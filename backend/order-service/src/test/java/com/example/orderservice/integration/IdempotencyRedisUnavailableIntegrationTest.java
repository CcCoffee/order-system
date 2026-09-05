package com.example.orderservice.integration;

import com.example.orderservice.OrderServiceApplication;
import com.example.orderservice.application.CreateOrderCommand;
import com.example.orderservice.application.CreateOrderItemCommand;
import com.example.orderservice.application.OrderApplicationService;
import com.example.orderservice.application.OrderResponse;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Tag;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.jdbc.core.JdbcTemplate;

import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Redis-unavailable idempotency evidence for Evaluation 004 (AC-8).
 *
 * <p>This context points Redis at {@code 127.0.0.1:6398}, where nothing is
 * listening, while still using the real PostgreSQL database. Lettuce connects
 * lazily, so the context starts, and every {@code OrderCache} operation degrades
 * to a no-op. The database unique index on {@code orders(idempotency_key)} is
 * therefore the correctness authority, so duplicate requests must still yield a
 * single order and a single reservation. Only the database is cleaned up
 * because Redis is deliberately unavailable.
 */
@Tag("integration")
@SpringBootTest(classes = OrderServiceApplication.class,
        webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT,
        properties = {
                "spring.data.redis.host=127.0.0.1",
                "spring.data.redis.port=6398"
        })
class IdempotencyRedisUnavailableIntegrationTest {

    private static final UUID DEDICATED_PRODUCT =
            UUID.fromString("66666666-6666-6666-6666-666666666666");
    private static final UUID DEDICATED_INVENTORY =
            UUID.fromString("66666666-6666-6666-6666-666666666665");
    private static final int INITIAL_QUANTITY = 100;

    @Autowired
    private OrderApplicationService orderService;

    @Autowired
    private JdbcTemplate jdbcTemplate;

    @BeforeEach
    void createIsolatedInventory() {
        jdbcTemplate.update(
                "INSERT INTO products (id, name, price, created_at) VALUES (?, ?, ?, now()) "
                        + "ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name, price = EXCLUDED.price",
                DEDICATED_PRODUCT, "Redis-Unavailable Product", 10.00);
        jdbcTemplate.update(
                "INSERT INTO inventory (id, product_id, quantity, reserved_quantity, version) "
                        + "VALUES (?, ?, ?, 0, 0) "
                        + "ON CONFLICT (product_id) DO UPDATE SET quantity = EXCLUDED.quantity, "
                        + "reserved_quantity = 0, version = 0",
                DEDICATED_INVENTORY, DEDICATED_PRODUCT, INITIAL_QUANTITY);
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
    }

    /** AC-8: duplicate requests without Redis still yield one order and one reservation. */
    @Test
    void duplicateRequestsWithoutRedisStillYieldSingleOrder() {
        String key = UUID.randomUUID().toString();
        int quantityBefore = inventoryQuantity();
        int reservedBefore = inventoryReserved();

        OrderResponse first = orderService.createOrder(command(1), key);
        OrderResponse second = orderService.createOrder(command(1), key);

        assertThat(second.id()).isEqualTo(first.id());
        assertThat(orderCountForKey(key)).isEqualTo(1);
        assertThat(auditCountForOrder(first.id())).isEqualTo(1);
        assertThat(inventoryReserved()).isEqualTo(reservedBefore + 1);
        assertThat(inventoryQuantity()).isEqualTo(quantityBefore - 1);
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
}
