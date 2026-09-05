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
or duplicate reservations.

### AC-5 Redis is used meaningfully for idempotency
Redis coordinates/stores idempotency state. The implementation documents the key
format, TTL, stored value, duplicate request behavior, and concurrency behavior.

### AC-6 No permanent block from a failed DB transaction
The system must avoid a situation where Redis reports success but the database
transaction fails, permanently blocking subsequent requests. The consistency
strategy is documented.

## Required Evidence

Every acceptance criterion MUST have corresponding evidence.

| Criterion | Required Evidence |
|---|---|
| AC-1 | Integration/API test submitting the same request twice and asserting one order |
| AC-2 | Integration/API test asserting inventory reserved once |
| AC-3 | API test asserting identical response for repeated calls |
| AC-4 | Concurrent duplicate request integration test against real PostgreSQL |
| AC-5 | Integration test + documentation of Redis idempotency design |
| AC-6 | Test/documentation asserting the failure handling strategy |

## Required Tests

At minimum:

1. Same request submitted twice.
2. Same request submitted many times.
3. Concurrent duplicate requests.
4. Same idempotency key with a different request payload.
5. Redis unavailable behavior.

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
