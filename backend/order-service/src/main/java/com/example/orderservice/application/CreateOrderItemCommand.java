package com.example.orderservice.application;

import java.util.UUID;

public record CreateOrderItemCommand(UUID productId, int quantity) {
}
