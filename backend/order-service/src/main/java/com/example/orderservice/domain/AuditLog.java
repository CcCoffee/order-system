package com.example.orderservice.domain;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "audit_logs")
public class AuditLog {

    @Id
    private UUID id;

    @Column(name = "order_id", nullable = false)
    private UUID orderId;

    @Column(nullable = false, length = 50)
    private String event;

    @Column(name = "status_before", length = 20)
    private String statusBefore;

    @Column(name = "status_after", length = 20)
    private String statusAfter;

    @Column(name = "created_at", nullable = false)
    private Instant createdAt;

    protected AuditLog() {
    }

    public AuditLog(UUID orderId, String event, String statusBefore, String statusAfter) {
        this.id = UUID.randomUUID();
        this.orderId = orderId;
        this.event = event;
        this.statusBefore = statusBefore;
        this.statusAfter = statusAfter;
        this.createdAt = Instant.now();
    }

    public UUID getId() {
        return id;
    }

    public UUID getOrderId() {
        return orderId;
    }

    public String getEvent() {
        return event;
    }

    public String getStatusBefore() {
        return statusBefore;
    }

    public String getStatusAfter() {
        return statusAfter;
    }

    public Instant getCreatedAt() {
        return createdAt;
    }
}
