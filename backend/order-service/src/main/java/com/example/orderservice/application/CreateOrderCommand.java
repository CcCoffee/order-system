package com.example.orderservice.application;

import java.util.List;

public record CreateOrderCommand(List<CreateOrderItemCommand> items) {

    public CreateOrderCommand {
        items = items == null ? List.of() : List.copyOf(items);
    }
}
