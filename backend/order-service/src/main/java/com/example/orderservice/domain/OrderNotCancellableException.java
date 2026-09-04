package com.example.orderservice.domain;

public class OrderNotCancellableException extends RuntimeException {

    private final OrderStatus status;

    public OrderNotCancellableException(OrderStatus status) {
        super("Order cannot be cancelled in state " + status);
        this.status = status;
    }

    public OrderStatus getStatus() {
        return status;
    }
}
