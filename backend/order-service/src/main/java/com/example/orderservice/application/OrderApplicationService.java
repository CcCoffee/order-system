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
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.transaction.support.TransactionSynchronization;
import org.springframework.transaction.support.TransactionSynchronizationManager;

import java.math.BigDecimal;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

/**
 * Application service coordinating the order use cases.
 *
 * <p>Each use case runs inside a single transaction so that order creation and
 * cancellation are atomic with respect to inventory reservation/release and
 * audit logging.
 */
@Service
public class OrderApplicationService {

    private final OrderRepository orderRepository;
    private final InventoryRepository inventoryRepository;
    private final ProductRepository productRepository;
    private final AuditLogRepository auditLogRepository;
    private final OrderCache orderCache;

    public OrderApplicationService(OrderRepository orderRepository,
                                   InventoryRepository inventoryRepository,
                                   ProductRepository productRepository,
                                   AuditLogRepository auditLogRepository,
                                   OrderCache orderCache) {
        this.orderRepository = orderRepository;
        this.inventoryRepository = inventoryRepository;
        this.productRepository = productRepository;
        this.auditLogRepository = auditLogRepository;
        this.orderCache = orderCache;
    }

    @Transactional
    public OrderResponse createOrder(CreateOrderCommand command, String idempotencyKey) {
        if (idempotencyKey != null && !idempotencyKey.isBlank()) {
            Optional<UUID> existing = orderCache.getIdempotency(idempotencyKey);
            if (existing.isPresent()) {
                return getOrder(existing.get());
            }
        }
        if (command.items().isEmpty()) {
            throw new IllegalArgumentException("Order must contain at least one item");
        }

        Order order = new Order(UUID.randomUUID());
        BigDecimal totalAmount = BigDecimal.ZERO;

        for (CreateOrderItemCommand item : command.items()) {
            if (item.productId() == null) {
                throw new IllegalArgumentException("productId is required");
            }
            if (item.quantity() <= 0) {
                throw new IllegalArgumentException("Quantity must be positive");
            }
            Product product = productRepository.findById(item.productId())
                    .orElseThrow(() -> new ProductNotFoundException(item.productId()));
            Inventory inventory = inventoryRepository.findByProductIdForUpdate(item.productId())
                    .orElseThrow(() -> new InventoryNotFoundException(item.productId()));
            // Reserve inventory inside the transaction; rolled back on failure.
            inventory.reserve(item.quantity());
            order.addItem(product.getId(), product.getName(), product.getPrice(), item.quantity());
        }

        orderRepository.save(order);
        auditLogRepository.save(new AuditLog(order.getId(), "ORDER_CREATED", null, OrderStatus.PENDING.name()));

        if (idempotencyKey != null && !idempotencyKey.isBlank()) {
            UUID orderId = order.getId();
            registerAfterCommit(() -> orderCache.putIdempotency(idempotencyKey, orderId));
        }

        return toResponse(order);
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
}
