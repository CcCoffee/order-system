package com.example.orderservice.api.dto;

import com.example.orderservice.application.CreateOrderCommand;
import com.example.orderservice.application.CreateOrderItemCommand;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotEmpty;

import java.util.List;

public record CreateOrderRequest(
        @NotEmpty(message = "items must not be empty")
        List<@Valid CreateOrderItemRequest> items) {

    public CreateOrderCommand toCommand() {
        return new CreateOrderCommand(items.stream()
                .map(i -> new CreateOrderItemCommand(i.productId(), i.quantity()))
                .toList());
    }
}
