package com.example.orderservice.domain;

import org.junit.jupiter.api.Test;

import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

class InventoryTest {

    private static final UUID PRODUCT_ID = UUID.randomUUID();

    @Test
    void reserveReducesAvailableAndIncreasesReserved() {
        Inventory inventory = new Inventory(UUID.randomUUID(), PRODUCT_ID, 10);
        inventory.reserve(4);
        assertThat(inventory.getQuantity()).isEqualTo(6);
        assertThat(inventory.getReservedQuantity()).isEqualTo(4);
    }

    @Test
    void reserveMoreThanAvailableThrows() {
        Inventory inventory = new Inventory(UUID.randomUUID(), PRODUCT_ID, 3);
        assertThatThrownBy(() -> inventory.reserve(5))
                .isInstanceOf(InsufficientInventoryException.class);
        assertThat(inventory.getQuantity()).isEqualTo(3);
        assertThat(inventory.getReservedQuantity()).isZero();
    }

    @Test
    void reserveNonPositiveThrows() {
        Inventory inventory = new Inventory(UUID.randomUUID(), PRODUCT_ID, 10);
        assertThatThrownBy(() -> inventory.reserve(0))
                .isInstanceOf(IllegalArgumentException.class);
    }

    @Test
    void releaseReturnsInventoryToAvailable() {
        Inventory inventory = new Inventory(UUID.randomUUID(), PRODUCT_ID, 10);
        inventory.reserve(4);
        inventory.release(4);
        assertThat(inventory.getQuantity()).isEqualTo(10);
        assertThat(inventory.getReservedQuantity()).isZero();
    }

    @Test
    void releaseMoreThanReservedThrows() {
        Inventory inventory = new Inventory(UUID.randomUUID(), PRODUCT_ID, 10);
        inventory.reserve(2);
        assertThatThrownBy(() -> inventory.release(3))
                .isInstanceOf(IllegalStateException.class);
    }
}
