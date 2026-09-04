package com.example.orderservice.domain;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import jakarta.persistence.Version;

import java.util.UUID;

/**
 * Inventory tracks the quantity of a product available to sell and the quantity
 * reserved by pending orders.
 */
@Entity
@Table(name = "inventory")
public class Inventory {

    @Id
    private UUID id;

    @Column(name = "product_id", nullable = false, unique = true)
    private UUID productId;

    @Column(nullable = false)
    private int quantity;

    @Column(name = "reserved_quantity", nullable = false)
    private int reservedQuantity;

    @Version
    @Column(nullable = false)
    private long version;

    protected Inventory() {
    }

    public Inventory(UUID id, UUID productId, int quantity) {
        this.id = id;
        this.productId = productId;
        this.quantity = quantity;
        this.reservedQuantity = 0;
    }

    /**
     * Reserves {@code amount} units of inventory, reducing the available quantity
     * and increasing the reserved quantity.
     *
     * @throws InsufficientInventoryException when there is not enough stock
     */
    public void reserve(int amount) {
        if (amount <= 0) {
            throw new IllegalArgumentException("Reservation amount must be positive");
        }
        if (quantity < amount) {
            throw new InsufficientInventoryException(productId, quantity, amount);
        }
        quantity -= amount;
        reservedQuantity += amount;
    }

    /**
     * Releases {@code amount} reserved units back into the available quantity.
     */
    public void release(int amount) {
        if (amount <= 0) {
            throw new IllegalArgumentException("Release amount must be positive");
        }
        if (reservedQuantity < amount) {
            throw new IllegalStateException("Cannot release more inventory than is reserved");
        }
        reservedQuantity -= amount;
        quantity += amount;
    }

    public UUID getId() {
        return id;
    }

    public UUID getProductId() {
        return productId;
    }

    public int getQuantity() {
        return quantity;
    }

    public int getReservedQuantity() {
        return reservedQuantity;
    }

    public long getVersion() {
        return version;
    }
}
