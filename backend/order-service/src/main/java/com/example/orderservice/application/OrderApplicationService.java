package com.example.orderservice.application;

import com.example.orderservice.domain.AuditLog;
import com.example.orderservice.domain.Inventory;
import com.example.orderservice.domain.Order;
import com.example.orderservice.domain.OrderItem;
import com.example.orderservice.domain.OrderNotCancellableException;
import com.example.orderservice.domain.OrderStatus;
import com.example.orderservice.domain.Product;
import com.example.orderservice.domain.repository.AuditLogRepository;
import com.example.orderservice.domain.repository.InventoryRepository;
import com.example.orderservice.domain.repository.OrderRepository;
import com.example.orderservice.domain.repository.ProductRepository;
import com.example.orderservice.infrastructure.OrderCache;
import org.springframework.context.annotation.Lazy;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.transaction.support.TransactionSynchronization;
import org.springframework.transaction.support.TransactionSynchronizationManager;

import java.time.Duration;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

/**
 * Application service coordinating the order use cases.
 *
 * <p>{@link #createOrder(CreateOrderCommand, String)} is a non-transactional
 * orchestrator that drives idempotency coordination and delegates the
 * transactional creation to a Spring proxy (held as {@code self}) so the
 * {@code @Transactional} boundary is enforced by a real proxy boundary.
 *
 * <p>Each transactional use case runs inside a single transaction so that order
 * creation and cancellation are atomic with respect to inventory
 * reservation/release and audit logging.
 */
@Service
public class OrderApplicationService {

    private static final int LOCK_WAIT_ATTEMPTS = 5;
    private static final Duration LOCK_WAIT_POLL = Duration.ofMillis(100);

    private final OrderRepository orderRepository;
    private final InventoryRepository inventoryRepository;
    private final ProductRepository productRepository;
    private final AuditLogRepository auditLogRepository;
    private final OrderCache orderCache;
    private final OrderApplicationService self;

    public OrderApplicationService(OrderRepository orderRepository,
                                   InventoryRepository inventoryRepository,
                                   ProductRepository productRepository,
                                   AuditLogRepository auditLogRepository,
                                   OrderCache orderCache,
                                   @Lazy OrderApplicationService self) {
        this.orderRepository = orderRepository;
        this.inventoryRepository = inventoryRepository;
        this.productRepository = productRepository;
        this.auditLogRepository = auditLogRepository;
        this.orderCache = orderCache;
        this.self = self;
    }

    public OrderResponse createOrder(CreateOrderCommand command, String idempotencyKey) {
        boolean hasKey = idempotencyKey != null && !idempotencyKey.isBlank();

        if (hasKey) {
            Optional<UUID> existing = orderCache.getIdempotency(idempotencyKey);
            if (existing.isPresent()) {
                return self.getOrder(existing.get());
            }
        }

        String lockToken = UUID.randomUUID().toString();
        boolean lockHeld = false;

        if (hasKey) {
            OrderCache.LockResult lock = orderCache.tryAcquireIdempotencyLock(idempotencyKey, lockToken);
            if (lock == OrderCache.LockResult.ACQUIRED) {
                lockHeld = true;
            } else if (lock == OrderCache.LockResult.BUSY) {
                Optional<OrderResponse> resolved = waitForIdempotencyResolution(idempotencyKey);
                if (resolved.isPresent()) {
                    return resolved.get();
                }
            }
        }

        try {
            return self.createOrderTx(command, hasKey ? idempotencyKey : null, lockToken, lockHeld);
        } catch (RuntimeException ex) {
            if (hasKey) {
                Optional<OrderResponse> existing = self.findExistingByIdempotencyKey(idempotencyKey);
                if (existing.isPresent()) {
                    return existing.get();
                }
            }
            throw ex;
        }
    }

    /**
     * Transactional order creation. Must be invoked through the Spring proxy
     * ({@code self}) so the transaction boundary is visible.
     *
     * <p>If a duplicate key races, the database unique index raises a
     * constraint violation that rolls this transaction back; the caller re-reads
     * using {@link #findExistingByIdempotencyKey(String)}.
     */
    @Transactional
    public OrderResponse createOrderTx(CreateOrderCommand command, String idempotencyKey,
                                       String lockToken, boolean lockHeld) {
        if (command.items().isEmpty()) {
            throw new IllegalArgumentException("Order must contain at least one item");
        }

        Order order = new Order(UUID.randomUUID(), idempotencyKey);

        for (CreateOrderItemCommand item : command.items()) {
            validateItem(item);
            Product product = productRepository.findById(item.productId())
                    .orElseThrow(() -> new ProductNotFoundException(item.productId()));
            Inventory inventory = inventoryRepository.findByProductIdForUpdate(item.productId())
                    .orElseThrow(() -> new InventoryNotFoundException(item.productId()));
            // Reserve inventory inside the transaction; rolled back on failure.
            inventory.reserve(item.quantity());
            order.addItem(product.getId(), product.getName(), product.getPrice(), item.quantity());
        }

        Order saved = orderRepository.save(order);
        auditLogRepository.save(
                new AuditLog(saved.getId(), "ORDER_CREATED", null, OrderStatus.PENDING.name()));

        if (idempotencyKey != null && !idempotencyKey.isBlank()) {
            registerIdempotencyAfterCommit(saved.getId(), idempotencyKey, lockToken, lockHeld);
        }

        return toResponse(saved);
    }

    /**
     * Re-reads an order by idempotency key inside a fresh transaction.
     *
     * <p>Used after a duplicate create attempt to return the winner's order
     * instead of surfacing a race-related exception.
     */
    @Transactional(readOnly = true)
    public Optional<OrderResponse> findExistingByIdempotencyKey(String idempotencyKey) {
        return orderRepository.findByIdempotencyKey(idempotencyKey).map(this::toResponse);
    }

    private void validateItem(CreateOrderItemCommand item) {
        if (item.productId() == null) {
            throw new IllegalArgumentException("productId is required");
        }
        if (item.quantity() <= 0) {
            throw new IllegalArgumentException("Quantity must be positive");
        }
    }

    @Transactional(readOnly = true)
    public OrderResponse getOrder(UUID orderId) {
        Optional<OrderResponse> cached = orderCache.get(orderId);
        if (cached.isPresent()) {
            return cached.get();
        }
        Order order = orderRepository.findById(orderId)
                .orElseThrow(() -> new OrderNotFoundException(orderId));
        OrderResponse response = toResponse(order);
        orderCache.cache(orderId, response);
        return response;
    }

    @Transactional
    public OrderResponse cancelOrder(UUID orderId) {
        Order order = orderRepository.findById(orderId)
                .orElseThrow(() -> new OrderNotFoundException(orderId));
        if (!order.getStatus().canBeCancelled()) {
            throw new OrderNotCancellableException(order.getStatus());
        }

        OrderStatus before = order.getStatus();
        for (OrderItem item : order.getItems()) {
            Inventory inventory = inventoryRepository.findByProductIdForUpdate(item.getProductId())
                    .orElseThrow(() -> new InventoryNotFoundException(item.getProductId()));
            inventory.release(item.getQuantity());
        }
        order.cancel();
        auditLogRepository.save(new AuditLog(orderId, "ORDER_CANCELLED", before.name(), OrderStatus.CANCELLED.name()));

        registerAfterCommit(() -> orderCache.evict(orderId));
        return toResponse(order);
    }

    @Transactional(readOnly = true)
    public List<ProductResponse> listProducts() {
        return productRepository.findAll().stream()
                .map(p -> new ProductResponse(p.getId(), p.getName(), p.getPrice()))
                .toList();
    }

    private OrderResponse toResponse(Order order) {
        List<OrderItemResponse> items = order.getItems().stream()
                .map(i -> new OrderItemResponse(
                        i.getProductId(),
                        i.getProductName(),
                        i.getUnitPrice(),
                        i.getQuantity(),
                        i.getLineTotal()))
                .toList();
        return new OrderResponse(
                order.getId(),
                order.getStatus(),
                items,
                order.getTotalAmount(),
                order.getCreatedAt(),
                order.getUpdatedAt());
    }

    private void registerAfterCommit(Runnable action) {
        if (TransactionSynchronizationManager.isActualTransactionActive()) {
            TransactionSynchronizationManager.registerSynchronization(new TransactionSynchronization() {
                @Override
                public void afterCommit() {
                    action.run();
                }
            });
        } else {
            action.run();
        }
    }

    private void registerAfterRollback(Runnable action) {
        if (TransactionSynchronizationManager.isActualTransactionActive()) {
            TransactionSynchronizationManager.registerSynchronization(new TransactionSynchronization() {
                @Override
                public void afterCompletion(int status) {
                    if (status == TransactionSynchronization.STATUS_ROLLED_BACK) {
                        action.run();
                    }
                }
            });
        } else {
            action.run();
        }
    }

    private void registerIdempotencyAfterCommit(UUID orderId, String idempotencyKey,
                                                String lockToken, boolean lockHeld) {
        registerAfterCommit(() -> orderCache.putIdempotency(idempotencyKey, orderId));
        if (lockHeld) {
            registerAfterCommit(() -> orderCache.releaseIdempotencyLock(idempotencyKey, lockToken));
            registerAfterRollback(() -> orderCache.releaseIdempotencyLock(idempotencyKey, lockToken));
        }
    }

    private Optional<OrderResponse> waitForIdempotencyResolution(String idempotencyKey) {
        for (int attempt = 0; attempt < LOCK_WAIT_ATTEMPTS; attempt++) {
            sleepQuietly();
            Optional<UUID> resolved = orderCache.getIdempotency(idempotencyKey);
            if (resolved.isPresent()) {
                return Optional.of(self.getOrder(resolved.get()));
            }
        }
        return Optional.empty();
    }

    private void sleepQuietly() {
        try {
            Thread.sleep(LOCK_WAIT_POLL.toMillis());
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        }
    }
}
