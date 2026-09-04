package com.example.orderservice.domain;

import java.util.UUID;

public class InsufficientInventoryException extends RuntimeException {

    private final UUID productId;

    public InsufficientInventoryException(UUID productId, int available, int requested) {
        super("Insufficient inventory for product " + productId
                + ": available " + available + ", requested " + requested);
        this.productId = productId;
    }

    public UUID getProductId() {
        return productId;
    }
}
