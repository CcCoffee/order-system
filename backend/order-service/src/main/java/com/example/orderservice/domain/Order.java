package com.example.orderservice.domain;

import jakarta.persistence.CascadeType;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.FetchType;
import jakarta.persistence.Id;
import jakarta.persistence.OneToMany;
import jakarta.persistence.Table;
import jakarta.persistence.Version;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

/**
 * Order aggregate root. Encapsulates the order lifecycle invariants.
 */
@Entity
@Table(name = "orders")
public class Order {

    @Id
    private UUID id;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private OrderStatus status;

    @OneToMany(mappedBy = "order", cascade = CascadeType.ALL, orphanRemoval = true,
            fetch = FetchType.LAZY)
    private List<OrderItem> items = new ArrayList<>();

    @Column(name = "total_amount", nullable = false, precision = 12, scale = 2)
    private BigDecimal totalAmount;

    @Column(name = "created_at", nullable = false)
    private Instant createdAt;

    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;

    @Version
    @Column(nullable = false)
    private long version;

    protected Order() {
    }

    public Order(UUID id) {
        this.id = id;
        this.status = OrderStatus.PENDING;
        this.createdAt = Instant.now();
        this.updatedAt = this.createdAt;
        this.totalAmount = BigDecimal.ZERO;
    }

    public void addItem(UUID productId, String productName, BigDecimal unitPrice, int quantity) {
        OrderItem item = new OrderItem(UUID.randomUUID(), this, productId, productName, unitPrice, quantity);
        items.add(item);
        totalAmount = totalAmount.add(item.getLineTotal());
        updatedAt = Instant.now();
    }

    public void cancel() {
        if (!status.canBeCancelled()) {
            throw new OrderNotCancellableException(status);
        }
        setStatus(OrderStatus.CANCELLED);
    }

    public void pay() {
        transitionTo(OrderStatus.PAID);
    }

    public void ship() {
        transitionTo(OrderStatus.SHIPPED);
    }

    public void complete() {
        transitionTo(OrderStatus.COMPLETED);
    }

    private void transitionTo(OrderStatus target) {
        if (!status.canTransitionTo(target)) {
            throw new InvalidOrderTransitionException(status, target);
        }
        setStatus(target);
    }

    private void setStatus(OrderStatus status) {
        this.status = status;
        this.updatedAt = Instant.now();
    }

    public UUID getId() {
        return id;
    }

    public OrderStatus getStatus() {
        return status;
    }

    public List<OrderItem> getItems() {
        return items;
    }

    public BigDecimal getTotalAmount() {
        return totalAmount;
    }

    public Instant getCreatedAt() {
        return createdAt;
    }

    public Instant getUpdatedAt() {
        return updatedAt;
    }

    public long getVersion() {
        return version;
    }
}
