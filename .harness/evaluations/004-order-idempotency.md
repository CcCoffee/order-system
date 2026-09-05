# Evaluation 004 — Order Idempotency

## Objective

Verify that repeated submission of the same order request does not create
duplicate orders or duplicate inventory reservations.

## Scenario

A client submits an order request with an idempotency key, e.g. `order-demo-001`,
then retries the same request multiple times, including concurrently.

## Acceptance Criteria

### AC-1 Same key does not create multiple orders
For the same idempotency key, the system must not create multiple orders.

### AC-2 Inventory reserved only once
For the same idempotency key, inventory must only be reserved once.

### AC-3 Same logical result returned to repeated callers
Repeated callers with the same key receive the same logical result.

### AC-4 Concurrent duplicate requests are handled safely
Concurrent duplicate requests with the same key must not create duplicate orders
or duplicate reservations. The concurrent requests must yield a single order and
single reservation, and losing requests must not add extra business side effects.

### AC-5 Redis is used meaningfully for idempotency
Redis coordinates/stores idempotency state. The implementation documents the key
format, TTL, stored value, duplicate request behavior, and concurrency behavior.

### AC-6 No permanent block from a failed DB transaction
The system must avoid a situation where idempotency state is recorded (for
example in Redis) but the database transaction fails, permanently blocking
subsequent requests. A retry with the same key after a failed transaction must
be able to succeed. The consistency strategy is documented.

### AC-7 Same key with a different payload is deterministic
A request that reuses an existing idempotency key but carries a different request
payload must return the original order and must not create a new order or
reserve inventory again.

### AC-8 Redis unavailability is handled deterministically
If Redis is unavailable, order creation must behave deterministically as
documented and must still prevent duplicate orders and duplicate inventory
reservations. Acceptable documented behaviors include returning an explicit
error and creating nothing, or enforcing idempotency through a persistence-layer
guarantee that holds even without Redis.

## Required Evidence

Every acceptance criterion MUST have corresponding evidence.

| Criterion | Required Evidence |
|---|---|
| AC-1 | Integration/API test submitting the same request twice and asserting exactly one order exists |
| AC-2 | Integration/API test asserting inventory reserved once via persistent reservation count/state, not only an HTTP response |
| AC-3 | API test asserting the same logical result for repeated calls (same order identifier and identical response body) |
| AC-4 | Concurrent duplicate request integration test against real PostgreSQL and real Redis using synchronized overlapping execution; assert exactly one order and one inventory reservation, and that losing duplicates add no extra side effects |
| AC-5 | Integration test asserting the idempotency key exists in Redis with the documented key format and TTL and maps to the created order, plus documentation of the Redis idempotency design (key format, TTL, stored value, duplicate request behavior, concurrency behavior); documentation is verified by review |
| AC-6 | Integration test that triggers a database transaction failure after idempotency state is recorded and asserts the same key can be retried successfully (no permanent block); documentation of the consistency strategy is also required |
| AC-7 | Integration/API test reusing the same key with a different payload, asserting the original order is returned and no duplicate order or reservation is created |
| AC-8 | Integration test with an unavailable Redis endpoint asserting the documented deterministic behavior and that no duplicate side effects occur |

## Required Tests

At minimum:

1. Same request submitted twice.
2. Same request submitted many times.
3. Concurrent duplicate requests (overlapping, against real PostgreSQL and real Redis).
4. Same idempotency key with a different request payload.
5. Redis unavailable behavior.
6. A test that triggers a database transaction failure and verifies the same idempotency key can be retried successfully (no permanent block).

## Architecture Constraints

Idempotency logic must not be implemented directly inside controllers.

## Regression Requirements

Order creation, inventory reservation, and existing verification must remain
intact.

## Verification

The repository must pass:

```
./scripts/verify.sh
```

Repository verification does not substitute for missing Evaluation evidence.

## Forbidden Shortcuts

- Weakening tests
- Deleting tests
- Skipping failures
- Replacing required integration tests with mocks
- Replacing required concurrency with sequential execution
- Modifying Evaluation criteria to reduce requirements
- Modifying verification scripts to hide failures
- Hard-coding test-specific production behavior
- Checking only the HTTP response while ignoring database or Redis side effects
- Replacing real Redis with an embedded or mocked Redis in concurrency tests
