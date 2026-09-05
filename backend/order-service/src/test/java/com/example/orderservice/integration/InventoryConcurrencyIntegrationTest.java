package com.example.orderservice.integration;

import com.example.orderservice.application.CreateOrderCommand;
import com.example.orderservice.application.CreateOrderItemCommand;
import com.example.orderservice.application.OrderApplicationService;
import com.example.orderservice.domain.InsufficientInventoryException;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Tag;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.jdbc.core.JdbcTemplate;

import java.util.ArrayList;
import java.util.List;
import java.util.Set;
import java.util.UUID;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;
import java.util.concurrent.atomic.AtomicInteger;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

/**
 * Real-PostgreSQL concurrency evidence for Evaluation 003 (Inventory
 * Concurrency).
 *
 * <p>All scenarios execute genuine concurrent order creation against the shared
 * dev PostgreSQL database. Each scenario runs against a dedicated product whose
 * inventory is (re)created to a known quantity, so the test is fully isolated
 * from the seeded catalog and deterministic across repeated runs. After each
 * scenario the dedicated product and any orders it created are removed, and
 * stale Redis idempotency keys are cleared so the shared idempotency
 * integration test can self-heal.
 */
@Tag("integration")
class InventoryConcurrencyIntegrationTest extends AbstractIntegrationTest {

    private static final UUID DEDICATED_PRODUCT =
            UUID.fromString("99999999-9999-9999-9999-999999999999");
    private static final UUID DEDICATED_INVENTORY =
            UUID.fromString("99999999-9999-9999-9999-999999999998");
    private static final int SCENARIO_QUANTITY = 10;

    @Autowired
    private OrderApplicationService orderService;

    @Autowired
    private JdbcTemplate jdbcTemplate;

    @Autowired
    private StringRedisTemplate stringRedisTemplate;

    @BeforeEach
    void createIsolatedInventory() {
        // Recreate a dedicated product+inventory with a known available quantity
        // so each scenario starts from a deterministic state.
        jdbcTemplate.update(
                "INSERT INTO products (id, name, price, created_at) VALUES (?, ?, ?, now()) "
                        + "ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name, price = EXCLUDED.price",
                DEDICATED_PRODUCT, "Concurrency Test Product", 10.00);
        jdbcTemplate.update(
                "INSERT INTO inventory (id, product_id, quantity, reserved_quantity, version) "
                        + "VALUES (?, ?, ?, 0, 0) "
                        + "ON CONFLICT (product_id) DO UPDATE SET quantity = EXCLUDED.quantity, "
                        + "reserved_quantity = 0, version = 0",
                DEDICATED_INVENTORY, DEDICATED_PRODUCT, SCENARIO_QUANTITY);
        clearIdempotencyKeys();
    }

    @AfterEach
    void removeIsolatedData() {
        List<UUID> orderIds = jdbcTemplate.query(
                "SELECT order_id FROM order_items WHERE product_id = ?",
                (rs, rowNum) -> rs.getObject("order_id", UUID.class),
                DEDICATED_PRODUCT);
        for (UUID orderId : orderIds) {
            jdbcTemplate.update("DELETE FROM audit_logs WHERE order_id = ?", orderId);
            jdbcTemplate.update("DELETE FROM order_items WHERE order_id = ?", orderId);
            jdbcTemplate.update("DELETE FROM orders WHERE id = ?", orderId);
        }
        jdbcTemplate.update("DELETE FROM inventory WHERE product_id = ?", DEDICATED_PRODUCT);
        jdbcTemplate.update("DELETE FROM products WHERE id = ?", DEDICATED_PRODUCT);
        clearIdempotencyKeys();
    }

    /** AC-1 / AC-2 / AC-3: exactly 10 concurrent qty-1 reservations all succeed. */
    @Test
    void tenConcurrentReservationsAllSucceedAndInventoryIsNeverNegative() throws Exception {
        int ordersBefore = orderCount();

        ReservationResult result = runConcurrent(10, 1);

        assertThat(result.success()).isEqualTo(10);
        assertThat(result.failed()).isZero();
        // AC-1: final inventory must never be negative.
        assertThat(inventoryQuantity()).isGreaterThanOrEqualTo(0);
        // AC-2: successful quantity does not exceed available inventory.
        assertThat(result.success()).isLessThanOrEqualTo(SCENARIO_QUANTITY);
        // AC-5: post-concurrency database state is consistent.
        assertThat(inventoryQuantity()).isEqualTo(0);
        assertThat(inventoryReserved()).isEqualTo(10);
        assertThat(orderCount() - ordersBefore).isEqualTo(10);
    }

    /** AC-1 / AC-2 / AC-3: 11 concurrent qty-1 requests cannot oversell. */
    @Test
    void elevenConcurrentReservationsNeverExceedAvailableInventory() throws Exception {
        int ordersBefore = orderCount();

        ReservationResult result = runConcurrent(11, 1);

        // At most ten may succeed; at least one must fail.
        assertThat(result.success()).isLessThanOrEqualTo(10);
        assertThat(result.failed()).isGreaterThanOrEqualTo(1);
        // With pessimistic locking exactly ten succeed and one fails.
        assertThat(result.success()).isEqualTo(10);
        assertThat(result.failed()).isEqualTo(1);
        // AC-1 / AC-2: no negative inventory, no overselling.
        assertThat(inventoryQuantity()).isGreaterThanOrEqualTo(0);
        assertThat(inventoryReserved()).isEqualTo(10);
        // AC-5: successful orders correspond to successful reservations.
        assertThat(orderCount() - ordersBefore).isEqualTo(result.success());
    }

    /** AC-3: two competing large reservations cannot both succeed. */
    @Test
    void competingLargeReservationsOnlyOneSucceeds() throws Exception {
        int ordersBefore = orderCount();

        ReservationResult result = runConcurrent(2, 6);

        assertThat(result.success()).isEqualTo(1);
        assertThat(result.failed()).isEqualTo(1);
        // Exactly one request consumes 6 of the 10 units; the other must fail.
        assertThat(inventoryQuantity()).isEqualTo(4);
        assertThat(inventoryReserved()).isEqualTo(6);
        assertThat(orderCount() - ordersBefore).isEqualTo(1);
    }

    /** AC-4 / AC-5: an unfulfillable order leaves no partial reservation. */
    @Test
    void failedOrderRollsBackWithoutPartialReservation() {
        int ordersBefore = orderCount();
        int quantityBefore = inventoryQuantity();
        int reservedBefore = inventoryReserved();
        int auditBefore = jdbcTemplate.queryForObject("SELECT COUNT(*) FROM audit_logs", Integer.class);

        assertThatThrownBy(() -> orderService.createOrder(
                new CreateOrderCommand(List.of(new CreateOrderItemCommand(DEDICATED_PRODUCT, 1000))), null))
                .isInstanceOf(InsufficientInventoryException.class);

        // AC-4 / AC-5: the failed order must not leave partially committed state.
        assertThat(inventoryQuantity()).isEqualTo(quantityBefore);
        assertThat(inventoryReserved()).isEqualTo(reservedBefore);
        assertThat(orderCount()).isEqualTo(ordersBefore);
        int auditAfter = jdbcTemplate.queryForObject("SELECT COUNT(*) FROM audit_logs", Integer.class);
        assertThat(auditAfter).isEqualTo(auditBefore);
    }

    private ReservationResult runConcurrent(int requestCount, int quantityPerRequest) throws InterruptedException {
        ExecutorService executor = Executors.newFixedThreadPool(requestCount);
        CountDownLatch ready = new CountDownLatch(requestCount);
        CountDownLatch start = new CountDownLatch(1);
        CountDownLatch done = new CountDownLatch(requestCount);
        AtomicInteger success = new AtomicInteger();
        AtomicInteger failed = new AtomicInteger();
        List<Future<?>> futures = new ArrayList<>();

        for (int i = 0; i < requestCount; i++) {
            futures.add(executor.submit(() -> {
                ready.countDown();
                try {
                    // Every worker blocks here until all workers are ready so the
                    // requests genuinely overlap instead of running sequentially.
                    start.await();
                } catch (InterruptedException e) {
                    Thread.currentThread().interrupt();
                    failed.incrementAndGet();
                    done.countDown();
                    return;
                }
                try {
                    orderService.createOrder(
                            new CreateOrderCommand(
                                    List.of(new CreateOrderItemCommand(DEDICATED_PRODUCT, quantityPerRequest))),
                            null);
                    success.incrementAndGet();
                } catch (InsufficientInventoryException e) {
                    failed.incrementAndGet();
                } catch (Exception e) {
                    failed.incrementAndGet();
                } finally {
                    done.countDown();
                }
            }));
        }

        ready.await();
        start.countDown();
        done.await();
        executor.shutdown();
        return new ReservationResult(success.get(), failed.get());
    }

    private int orderCount() {
        return jdbcTemplate.queryForObject("SELECT COUNT(*) FROM orders", Integer.class);
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
        Set<String> keys = stringRedisTemplate.keys("idempotency:*");
        if (keys != null && !keys.isEmpty()) {
            stringRedisTemplate.delete(keys);
        }
    }

    private record ReservationResult(int success, int failed) {
    }
}
