package com.example.orderservice.domain;

import org.junit.jupiter.api.Test;

import java.math.BigDecimal;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

class OrderTest {

    private static final UUID PRODUCT_ID = UUID.randomUUID();

    @Test
    void newOrderIsPending() {
        Order order = new Order(UUID.randomUUID());
        assertThat(order.getStatus()).isEqualTo(OrderStatus.PENDING);
        assertThat(order.getTotalAmount()).isEqualByComparingTo(BigDecimal.ZERO);
    }

    @Test
    void pendingOrderCanBeCancelled() {
        Order order = new Order(UUID.randomUUID());
        order.cancel();
        assertThat(order.getStatus()).isEqualTo(OrderStatus.CANCELLED);
    }

    @Test
    void paidOrderCannotBeCancelled() {
        Order order = new Order(UUID.randomUUID());
        order.pay();
        assertThatThrownBy(order::cancel)
                .isInstanceOf(OrderNotCancellableException.class);
    }

    @Test
    void shippedOrderCannotBeCancelled() {
        Order order = new Order(UUID.randomUUID());
        order.pay();
        order.ship();
        assertThatThrownBy(order::cancel)
                .isInstanceOf(OrderNotCancellableException.class);
    }

    @Test
    void cancelledOrderCannotBeCancelledAgain() {
        Order order = new Order(UUID.randomUUID());
        order.cancel();
        assertThatThrownBy(order::cancel)
                .isInstanceOf(OrderNotCancellableException.class);
    }

    @Test
    void completedOrderCannotBeCancelled() {
        Order order = new Order(UUID.randomUUID());
        order.pay();
        order.ship();
        order.complete();
        assertThatThrownBy(order::cancel)
                .isInstanceOf(OrderNotCancellableException.class);
    }

    @Test
    void validLifecycleTransitionsApply() {
        Order order = new Order(UUID.randomUUID());
        order.pay();
        assertThat(order.getStatus()).isEqualTo(OrderStatus.PAID);
        order.ship();
        assertThat(order.getStatus()).isEqualTo(OrderStatus.SHIPPED);
        order.complete();
        assertThat(order.getStatus()).isEqualTo(OrderStatus.COMPLETED);
    }

    @Test
    void invalidTransitionThrows() {
        Order order = new Order(UUID.randomUUID());
        assertThatThrownBy(order::ship)
                .isInstanceOf(InvalidOrderTransitionException.class);
    }

    @Test
    void addItemAccumulatesTotal() {
        Order order = new Order(UUID.randomUUID());
        order.addItem(PRODUCT_ID, "Widget", new BigDecimal("10.00"), 2);
        order.addItem(PRODUCT_ID, "Widget", new BigDecimal("10.00"), 3);
        assertThat(order.getItems()).hasSize(2);
        assertThat(order.getTotalAmount()).isEqualByComparingTo("50.00");
    }
}
