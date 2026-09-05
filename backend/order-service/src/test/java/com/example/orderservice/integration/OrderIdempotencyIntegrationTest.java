package com.example.orderservice.integration;

import com.example.orderservice.application.CreateOrderCommand;
import com.example.orderservice.application.CreateOrderItemCommand;
import com.example.orderservice.application.OrderApplicationService;
import com.example.orderservice.application.OrderResponse;
import com.example.orderservice.application.ProductNotFoundException;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Tag;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.jdbc.core.JdbcTemplate;

import java.util.List;
import java.util.Set;
import java.util.UUID;
import java.util.concurrent.TimeUnit;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

/**
 * Real-PostgreSQL and real-Redis idempotency evidence for Evaluation 004.
 *
 * <p>Each scenario runs against a dedicated product whose inventory is reset to
 * a known quantity and a unique per-run idempotency key, so the tests are
 * isolated from the seeded catalog and deterministic across repeated runs.
 * After each scenario the dedicated product and its orders are removed and
 * Redis idempotency state is cleared.
 */
@Tag("integration")
class OrderIdempotencyIntegrationTest extends AbstractIntegrationTest {

    private static final UUID DEDICATED_PRODUCT =
            UUID.fromString("88888888-8888-8888-8888-888888888888");
    private static final UUID DEDICATED_INVENTORY =
            UUID.fromString("88888888-8888-8888-8888-888888888887");
    private static final int INITIAL_QUANTITY = 100;
    private static final String IDEMPOTENCY_PREFIX = "idempotency:";

    @Autowired
    private OrderApplicationService orderService;

    @Autowired
    private JdbcTemplate jdbcTemplate;

    @Autowired
    private StringRedisTemplate stringRedisTemplate;

    @BeforeEach
    void createIsolatedInventory() {
        jdbcTemplate.update(
                "INSERT INTO products (id, name, price, created_at) VALUES (?, ?, ?, now()) "
                        + "ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name, price = EXCLUDED.price",
                DEDICATED_PRODUCT, "Idempotency Test Product", 10.00);
        jdbcTemplate.update(
                "INSERT INTO inventory (id, product_id, quantity, reserved_quantity, version) "
                        + "VALUES (?, ?, ?, 0, 0) "
                        + "ON CONFLICT (product_id) DO UPDATE SET quantity = EXCLUDED.quantity, "
                        + "reserved_quantity = 0, version = 0",
                DEDICATED_INVENTORY, DEDICATED_PRODUCT, INITIAL_QUANTITY);
        clearIdempotencyKeys();
    }

    @AfterEach
    void removeIsolatedData() {
        for (UUID orderId : orderIdsForProduct()) {
            jdbcTemplate.update("DELETE FROM audit_logs WHERE order_id = ?", orderId);
            jdbcTemplate.update("DELETE FROM order_items WHERE order_id = ?", orderId);
            jdbcTemplate.update("DELETE FROM orders WHERE id = ?", orderId);
        }
        jdbcTemplate.update("DELETE FROM inventory WHERE product_id = ?", DEDICATED_PRODUCT);
        jdbcTemplate.update("DELETE FROM products WHERE id = ?", DEDICATED_PRODUCT);
        clearIdempotencyKeys();
    }

    /** AC-1 / AC-3: the same key submitted twice yields a single order. */
    @Test
    void sameKeySubmittedTwiceCreatesOneOrder() {
        String key = UUID.randomUUID().toString();

        OrderResponse first = orderService.createOrder(command(1), key);
        OrderResponse second = orderService.createOrder(command(1), key);

        assertThat(second.id()).isEqualTo(first.id());
        assertThat(orderCountForKey(key)).isEqualTo(1);
        assertThat(auditCountForOrder(first.id())).isEqualTo(1);
    }

    /** AC-1 / AC-3: the same key submitted many times yields a single order. */
    @Test
    void sameKeyManyTimesReturnsSameOrder() {
        String key = UUID.randomUUID().toString();

        OrderResponse first = orderService.createOrder(command(1), key);
        for (int i = 0; i < 9; i++) {
            OrderResponse repeated = orderService.createOrder(command(1), key);
            assertThat(repeated.id()).isEqualTo(first.id());
        }

        assertThat(orderCountForKey(key)).isEqualTo(1);
        assertThat(auditCountForOrder(first.id())).isEqualTo(1);
        assertThat(inventoryReserved()).isEqualTo(1);
        assertThat(inventoryQuantity()).isEqualTo(INITIAL_QUANTITY - 1);
    }

    /** AC-2: inventory is reserved once even when the same key is reused. */
    @Test
    void sameKeyReservesInventoryOnlyOnce() {
        String key = UUID.randomUUID().toString();
        int quantityBefore = inventoryQuantity();
        int reservedBefore = inventoryReserved();

        OrderResponse first = orderService.createOrder(command(3), key);
        assertThat(inventoryReserved()).isEqualTo(reservedBefore + 3);
        assertThat(inventoryQuantity()).isEqualTo(quantityBefore - 3);

        OrderResponse second = orderService.createOrder(command(3), key);
        assertThat(second.id()).isEqualTo(first.id());
        assertThat(inventoryReserved()).isEqualTo(reservedBefore + 3);
        assertThat(inventoryQuantity()).isEqualTo(quantityBefore - 3);
    }

    /** AC-7: reusing a key with a different payload returns the original order. */
    @Test
    void sameKeyDifferentPayloadReturnsOriginalOrder() {
        String key = UUID.randomUUID().toString();
        int quantityBefore = inventoryQuantity();
        int reservedBefore = inventoryReserved();

        OrderResponse original = orderService.createOrder(command(1), key);
        assertThat(inventoryReserved()).isEqualTo(reservedBefore + 1);

        OrderResponse duplicate = orderService.createOrder(command(5), key);
        assertThat(duplicate.id()).isEqualTo(original.id());
        assertThat(duplicate.items()).hasSize(1);
        assertThat(duplicate.items().get(0).quantity()).isEqualTo(1);
        assertThat(orderCountForKey(key)).isEqualTo(1);
        assertThat(inventoryReserved()).isEqualTo(reservedBefore + 1);
        assertThat(inventoryQuantity()).isEqualTo(quantityBefore - 1);
    }

    /** AC-5: the idempotency key is stored in Redis with the documented TTL. */
    @Test
    void idempotencyKeyStoredInRedisWithTtlAndOrderId() {
        String key = UUID.randomUUID().toString();
        OrderResponse created = orderService.createOrder(command(1), key);

        String stored = stringRedisTemplate.opsForValue().get(IDEMPOTENCY_PREFIX + key);
        assertThat(stored).isEqualTo(created.id().toString());

        Long ttl = stringRedisTemplate.getExpire(IDEMPOTENCY_PREFIX + key, TimeUnit.HOURS);
        assertThat(ttl).isNotNull();
        assertThat(ttl).isBetween(23L, 24L);

        Integer indexCount = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM pg_indexes WHERE indexname = 'idx_orders_idempotency_key'",
                Integer.class);
        assertThat(indexCount).isEqualTo(1);
    }

    /** AC-6: a failed transaction does not permanently block a retry with the same key. */
    @Test
    void failedDbTransactionDoesNotBlockRetry() {
        String key = UUID.randomUUID().toString();

        assertThatThrownBy(() -> orderService.createOrder(
                new CreateOrderCommand(List.of(
                        new CreateOrderItemCommand(DEDICATED_PRODUCT, 1),
                        new CreateOrderItemCommand(UUID.randomUUID(), 1))), key))
                .isInstanceOf(ProductNotFoundException.class);

        assertThat(orderCountForKey(key)).isZero();
        assertThat(stringRedisTemplate.hasKey(IDEMPOTENCY_PREFIX + key)).isFalse();

        OrderResponse retried = orderService.createOrder(command(1), key);
        assertThat(retried.id()).isNotNull();
        assertThat(orderCountForKey(key)).isEqualTo(1);
        assertThat(auditCountForOrder(retried.id())).isEqualTo(1);
        assertThat(inventoryReserved()).isEqualTo(1);
        assertThat(inventoryQuantity()).isEqualTo(INITIAL_QUANTITY - 1);
        String stored = stringRedisTemplate.opsForValue().get(IDEMPOTENCY_PREFIX + key);
        assertThat(stored).isEqualTo(retried.id().toString());
    }

    private CreateOrderCommand command(int quantity) {
        return new CreateOrderCommand(List.of(new CreateOrderItemCommand(DEDICATED_PRODUCT, quantity)));
    }

    private List<UUID> orderIdsForProduct() {
        return jdbcTemplate.query(
                "SELECT order_id FROM order_items WHERE product_id = ?",
                (rs, rowNum) -> rs.getObject("order_id", UUID.class),
                DEDICATED_PRODUCT);
    }

    private int orderCountForKey(String key) {
        return jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM orders WHERE idempotency_key = ?", Integer.class, key);
    }

    private int auditCountForOrder(UUID orderId) {
        return jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM audit_logs WHERE order_id = ? AND event = 'ORDER_CREATED'",
                Integer.class, orderId);
    }

    private int inventoryQuantity() {
        return jdbcTemplate.queryForObject(
                "SELECT quantity FROM inventory WHERE product_id = ?", Integer.class, DEDICATED_PRODUCT);
    }

    private int inventoryReserved() {
        return jdbcTemplate.queryForObject(
                "SELECT reserved_quantity FROM inventory WHERE product_id = ?", Integer.class, DEDICATED_PRODUCT);
    }

    private void clearIdempotencyKeys() {
        Set<String> keys = stringRedisTemplate.keys(IDEMPOTENCY_PREFIX + "*");
        if (keys != null && !keys.isEmpty()) {
            stringRedisTemplate.delete(keys);
        }
    }
}
