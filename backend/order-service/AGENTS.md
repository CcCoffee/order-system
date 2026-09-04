# Order Service Engineering Rules

This service owns the Order domain.

---

# Responsibilities

Order Service owns:

- order creation
- order state transitions
- order cancellation
- order querying
- order lifecycle events

---

# Order Lifecycle

Supported states:

PENDING
 ↓
PAID
 ↓
SHIPPED
 ↓
COMPLETED

Cancellation rules must be enforced in the domain/application layer.

Do not implement order state transitions directly inside controllers.

---

# Cancellation

Cancellation must verify:

1. Order exists.
2. Current state allows cancellation.
3. Caller has permission.
4. State transition is atomic.
5. Cache invalidation occurs where required.
6. Relevant event is emitted.

---

# Events

Business events should be emitted after successful state transitions.

Examples:

OrderCreated
OrderPaid
OrderCancelled
OrderShipped
OrderCompleted

---

# Database

Orders are persisted in PostgreSQL.

All schema changes require Flyway migrations.

---

# Redis

Order cache must be invalidated whenever order state changes.

---

# Tests

Every state transition requires tests.

At minimum:

- valid transition
- invalid transition
- permission failure
- missing order
- persistence behavior
- cache invalidation
- event emission
