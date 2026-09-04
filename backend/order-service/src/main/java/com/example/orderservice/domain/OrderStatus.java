package com.example.orderservice.domain;

/**
 * Order lifecycle states.
 *
 * <p>Valid transitions:
 * <ul>
 *   <li>PENDING -&gt; PAID</li>
 *   <li>PENDING -&gt; CANCELLED</li>
 *   <li>PAID -&gt; SHIPPED</li>
 *   <li>SHIPPED -&gt; COMPLETED</li>
 * </ul>
 *
 * <p>Cancellation is only allowed from {@link #PENDING}.
 */
public enum OrderStatus {
    PENDING,
    PAID,
    SHIPPED,
    COMPLETED,
    CANCELLED;

    public boolean canTransitionTo(OrderStatus target) {
        return switch (this) {
            case PENDING -> target == PAID || target == CANCELLED;
            case PAID -> target == SHIPPED;
            case SHIPPED -> target == COMPLETED;
            case COMPLETED, CANCELLED -> false;
        };
    }

    public boolean canBeCancelled() {
        return this == PENDING;
    }
}
