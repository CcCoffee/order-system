# Backend Architecture

Controller
    |
Application Service
    |
Domain
    |
Infrastructure

Controllers do not access repositories directly.

Transactions normally belong at application-service boundaries.

---

## Order Creation Idempotency

Order creation is idempotent under a client-supplied `Idempotency-Key` header.
The design uses PostgreSQL as the persistence-layer correctness authority and
Redis as best-effort coordination.

### Key format and stored value

| Concern            | Redis key                  | Stored value       | TTL      |
| ------------------ | -------------------------- | ------------------ | -------- |
| Order cache        | `orders:{orderId}`         | OrderResponse JSON | 5 min    |
| Idempotency mapping| `idempotency:{key}`        | order id (UUID)    | 24 h     |
| Coordination lock  | `idempotency:lock:{key}`   | lock token         | 15 s     |

### Duplicate request behavior

- A fast path checks `idempotency:{key}`. If the mapping exists, the existing
  order is returned directly without reserving inventory again.
- If no mapping exists, the request attempts to create the order. The order rows
  carry the `idempotency_key`, and the unique index `idx_orders_idempotency_key`
  guarantees the same key maps to at most one order.

### Concurrency behavior

- Create requests for the same key are coordinated with the short-lived lock.
  A winner holds the lock; concurrent requests that see the lock busy poll the
  idempotency mapping for a bounded period and return the winner's order once it
  is available.
- If a duplicate races past the lock (or Redis is unavailable), the losing
  transaction fails on inventory or on the unique-key constraint. The
  non-transactional orchestrator then re-reads the order by idempotency key in a
  fresh transaction and returns the original order, so losing requests add no
  extra business side effects (AC-4).

### Transaction boundary

`createOrder` is a non-transactional orchestrator; it invokes `createOrderTx`
and `findExistingByIdempotencyKey` through the Spring proxy so that
`@Transactional` boundaries are enforced by a real proxy boundary.

### After-commit / after-rollback strategy

- On a successful commit, the idempotency mapping is written and, if the lock is
  held, it is released (after-commit).
- On a rollback, the lock is released (after-rollback) so a failed database
  transaction cannot permanently block a retry with the same key (AC-6).

### Redis-unavailable fallback (AC-8)

Every Redis operation is best-effort. When Redis is unavailable, reads degrade
to empty and writes become no-ops. Because the database unique index still
enforces idempotency, order creation behaves deterministically and never creates
a duplicate order or a duplicate reservation even without Redis.
