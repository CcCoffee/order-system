package com.example.orderservice.domain;

public class InvalidOrderTransitionException extends RuntimeException {

    public InvalidOrderTransitionException(OrderStatus from, OrderStatus to) {
        super("Invalid order transition: " + from + " -> " + to);
    }
}
