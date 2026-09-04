package com.example.orderservice.integration;

import com.example.orderservice.application.CreateOrderCommand;
import com.example.orderservice.application.CreateOrderItemCommand;
import com.example.orderservice.application.OrderApplicationService;
import com.example.orderservice.application.ProductNotFoundException;
import com.example.orderservice.domain.Inventory;
import com.example.orderservice.domain.repository.InventoryRepository;
import org.junit.jupiter.api.Tag;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

@Tag("integration")
class OrderTransactionIntegrationTest extends AbstractIntegrationTest {

    private static final UUID WIDGET = UUID.fromString("11111111-1111-1111-1111-111111111111");

    @Autowired
    OrderApplicationService orderService;

    @Autowired
    InventoryRepository inventoryRepository;

    @Test
    void createOrderReservesInventory() {
        Inventory before = inventoryRepository.findByProductId(WIDGET).orElseThrow();

        var created = orderService.createOrder(
                new CreateOrderCommand(List.of(new CreateOrderItemCommand(WIDGET, 5))), null);

        Inventory after = inventoryRepository.findByProductId(WIDGET).orElseThrow();
        assertThat(after.getQuantity()).isEqualTo(before.getQuantity() - 5);
        assertThat(after.getReservedQuantity()).isEqualTo(before.getReservedQuantity() + 5);

        orderService.cancelOrder(created.id());
    }

    @Test
    void cancellationReleasesInventory() {
        var created = orderService.createOrder(
                new CreateOrderCommand(List.of(new CreateOrderItemCommand(WIDGET, 3))), null);
        Inventory beforeRelease = inventoryRepository.findByProductId(WIDGET).orElseThrow();

        orderService.cancelOrder(created.id());

        Inventory afterRelease = inventoryRepository.findByProductId(WIDGET).orElseThrow();
        assertThat(afterRelease.getQuantity()).isEqualTo(beforeRelease.getQuantity() + 3);
        assertThat(afterRelease.getReservedQuantity()).isEqualTo(beforeRelease.getReservedQuantity() - 3);
    }

    @Test
    void rollbackPreventsPartialInventoryReservation() {
        Inventory before = inventoryRepository.findByProductId(WIDGET).orElseThrow();
        int availableBefore = before.getQuantity();
        int reservedBefore = before.getReservedQuantity();

        assertThatThrownBy(() -> orderService.createOrder(
                new CreateOrderCommand(List.of(
                        new CreateOrderItemCommand(WIDGET, 5),
                        new CreateOrderItemCommand(UUID.randomUUID(), 1))), null))
                .isInstanceOf(ProductNotFoundException.class);

        Inventory after = inventoryRepository.findByProductId(WIDGET).orElseThrow();
        assertThat(after.getQuantity()).isEqualTo(availableBefore);
        assertThat(after.getReservedQuantity()).isEqualTo(reservedBefore);
    }
}
