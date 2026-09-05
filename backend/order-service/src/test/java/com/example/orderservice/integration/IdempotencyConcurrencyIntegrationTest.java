package com.example.orderservice.integration;

import com.example.orderservice.application.CreateOrderCommand;
import com.example.orderservice.application.CreateOrderItemCommand;
import com.example.orderservice.application.OrderApplicationService;
import com.example.orderservice.application.OrderResponse;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Tag;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.jdbc.core.JdbcTemplate;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.Set;
import java.util.UUID;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Real-PostgreSQL and real-Redis concurrency evidence for Evaluation 004.
 *
 * <p>All workers submit the SAME idempotency key, against a dedicated product
 * whose inventory is provisioned to {@code WORKER_COUNT * QUANTITY_PER_REQUEST}
 * so that idempotency (not scarcity) is the binding constraint. The workers are
 * released simultaneously through a {@link CountDownLatch} so the requests
 * genuinely overlap rather than running sequentially, against the real
 * PostgreSQL database and the real Redis instance.
 */
@Tag("integration")
class IdempotencyConcurrencyIntegrationTest extends AbstractIntegrationTest {

    private static final UUID DEDICATED_PRODUCT =
            UUID.fromString("77777777-7777-7777-7777-777777777777");
    private static final UUID DEDICATED_INVENTORY =
            UUID.fromString("77777777-7777-7777-7777-777777777776");
    private static final int WORKER_COUNT = 8;
    private static final int QUANTITY_PER_REQUEST = 1;
    private static final String IDEMPOTENCY_PREFIX = "idempotency:";

    @Autowired
    private OrderApplicationService orderService;

    @Autowired
    private JdbcTemplate jdbcTemplate;

    @Autowired
    private StringRedisTemplate stringRedisTemplate;

    @BeforeEach
    void createIsolatedInventory() {
        int provisioned = WORKER_COUNT * QUANTITY_PER_REQUEST;
        jdbcTemplate.update(
                "INSERT INTO products (id, name, price, created_at) VALUES (?, ?, ?, now()) "
                        + "ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name, price = EXCLUDED.price",
                DEDICATED_PRODUCT, "Idempotency Concurrency Product", 10.00);
        jdbcTemplate.update(
                "INSERT INTO inventory (id, product_id, quantity, reserved_quantity, version) "
                        + "VALUES (?, ?, ?, 0, 0) "
                        + "ON CONFLICT (product_id) DO UPDATE SET quantity = EXCLUDED.quantity, "
                        + "reserved_quantity = 0, version = 0",
                DEDICATED_INVENTORY, DEDICATED_PRODUCT, provisioned);
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

    /**
     * AC-4: overlapping same-key requests yield one order and one reservation,
     * and losing requests add no extra business side effects.
     */
    @Test
    void concurrentDuplicateRequestsCreateSingleOrderAndSingleReservation() throws Exception {
        String key = UUID.randomUUID().toString();
        int quantityBefore = inventoryQuantity();
        int reservedBefore = inventoryReserved();

        UUID orderId = runConcurrentSameKey(WORKER_COUNT, QUANTITY_PER_REQUEST, key);

        assertThat(orderCountForProduct()).isEqualTo(1);
        assertThat(inventoryQuantity()).isEqualTo(quantityBefore - QUANTITY_PER_REQUEST);
        assertThat(inventoryReserved()).isEqualTo(reservedBefore + QUANTITY_PER_REQUEST);
        assertThat(auditCountForOrder(orderId)).isEqualTo(1);
        assertThat(orderItemCountForOrder(orderId)).isEqualTo(1);
        assertThat(stringRedisTemplate.opsForValue().get(IDEMPOTENCY_PREFIX + key))
                .isEqualTo(orderId.toString());
    }

    private UUID runConcurrentSameKey(int workerCount, int qty, String key) throws InterruptedException {
        ExecutorService executor = Executors.newFixedThreadPool(workerCount);
        CountDownLatch ready = new CountDownLatch(workerCount);
        CountDownLatch start = new CountDownLatch(1);
        CountDownLatch done = new CountDownLatch(workerCount);
        List<UUID> results = Collections.synchronizedList(new ArrayList<>());
        List<Throwable> failures = Collections.synchronizedList(new ArrayList<>());
        List<Future<?>> futures = new ArrayList<>();

        for (int i = 0; i < workerCount; i++) {
            futures.add(executor.submit(() -> {
                ready.countDown();
                try {
                    // Every worker blocks here until all workers are ready so the
                    // same-key requests genuinely overlap instead of running
                    // sequentially.
                    start.await();
                } catch (InterruptedException e) {
                    Thread.currentThread().interrupt();
                    failures.add(e);
                    done.countDown();
                    return;
                }
                try {
                    OrderResponse response = orderService.createOrder(
                            new CreateOrderCommand(
                                    List.of(new CreateOrderItemCommand(DEDICATED_PRODUCT, qty))),
                            key);
                    results.add(response.id());
                } catch (Throwable t) {
                    failures.add(t);
                } finally {
                    done.countDown();
                }
            }));
        }

        ready.await();
        start.countDown();
        done.await();
        executor.shutdown();

        assertThat(failures)
                .as("Concurrent same-key workers must not throw")
                .isEmpty();
        assertThat(results).hasSize(workerCount);
        UUID first = results.get(0);
        assertThat(results)
                .as("All workers must observe the single winner order")
                .allMatch(id -> first.equals(id));
        return first;
    }

    private List<UUID> orderIdsForProduct() {
        return jdbcTemplate.query(
                "SELECT order_id FROM order_items WHERE product_id = ?",
                (rs, rowNum) -> rs.getObject("order_id", UUID.class),
                DEDICATED_PRODUCT);
    }

    private int orderCountForProduct() {
        return jdbcTemplate.queryForObject(
                "SELECT COUNT(DISTINCT order_id) FROM order_items WHERE product_id = ?",
                Integer.class, DEDICATED_PRODUCT);
    }

    private int auditCountForOrder(UUID orderId) {
        return jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM audit_logs WHERE order_id = ? AND event = 'ORDER_CREATED'",
                Integer.class, orderId);
    }

    private int orderItemCountForOrder(UUID orderId) {
        return jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM order_items WHERE order_id = ?", Integer.class, orderId);
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
