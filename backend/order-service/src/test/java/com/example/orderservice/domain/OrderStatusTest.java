package com.example.orderservice.domain;

import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;

class OrderStatusTest {

    @Test
    void pendingCanTransitionToPaidAndCancelled() {
        assertThat(OrderStatus.PENDING.canTransitionTo(OrderStatus.PAID)).isTrue();
        assertThat(OrderStatus.PENDING.canTransitionTo(OrderStatus.CANCELLED)).isTrue();
    }

    @Test
    void pendingCannotTransitionToShipped() {
        assertThat(OrderStatus.PENDING.canTransitionTo(OrderStatus.SHIPPED)).isFalse();
    }

    @Test
    void paidCanTransitionToShippedOnly() {
        assertThat(OrderStatus.PAID.canTransitionTo(OrderStatus.SHIPPED)).isTrue();
        assertThat(OrderStatus.PAID.canTransitionTo(OrderStatus.CANCELLED)).isFalse();
        assertThat(OrderStatus.PAID.canTransitionTo(OrderStatus.PAID)).isFalse();
    }

    @Test
    void shippedCanTransitionToCompletedOnly() {
        assertThat(OrderStatus.SHIPPED.canTransitionTo(OrderStatus.COMPLETED)).isTrue();
        assertThat(OrderStatus.SHIPPED.canTransitionTo(OrderStatus.CANCELLED)).isFalse();
    }

    @Test
    void terminalStatesCannotTransition() {
        assertThat(OrderStatus.CANCELLED.canTransitionTo(OrderStatus.PAID)).isFalse();
        assertThat(OrderStatus.COMPLETED.canTransitionTo(OrderStatus.PAID)).isFalse();
    }

    @Test
    void onlyPendingCanBeCancelled() {
        assertThat(OrderStatus.PENDING.canBeCancelled()).isTrue();
        assertThat(OrderStatus.PAID.canBeCancelled()).isFalse();
        assertThat(OrderStatus.SHIPPED.canBeCancelled()).isFalse();
        assertThat(OrderStatus.CANCELLED.canBeCancelled()).isFalse();
        assertThat(OrderStatus.COMPLETED.canBeCancelled()).isFalse();
    }
}
