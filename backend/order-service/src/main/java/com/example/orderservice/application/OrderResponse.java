package com.example.orderservice.application;

import com.example.orderservice.domain.OrderStatus;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.List;
import java.util.UUID;

public record OrderResponse(
        UUID id,
        OrderStatus status,
        List<OrderItemResponse> items,
        BigDecimal totalAmount,
        Instant createdAt,
        Instant updatedAt) {
}
