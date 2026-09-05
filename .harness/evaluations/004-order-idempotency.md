# Evaluation 004 — Order Idempotency

## Objective

Verify that repeated submission of the same order request does not create
duplicate orders or duplicate inventory reservations.

## Scenario

A client submits an order request with an idempotency key:

`order-demo-001`

The client then retries the same request multiple times.

## Required behavior

For the same idempotency key:

1. The system must not create multiple orders.
2. Inventory must only be reserved once.
3. The same logical result should be returned to repeated callers.
4. Concurrent duplicate requests must also be handled safely.

## Redis requirement

Redis should be used meaningfully for idempotency coordination/state.

The implementation must document:

- key format
- TTL
- stored value
- duplicate request behavior
- concurrency behavior

## Failure handling

The implementation must avoid a situation where:

1. Redis says request succeeded
2. database transaction fails
3. subsequent requests are permanently blocked

The chosen consistency strategy must be documented.

## Required tests

At minimum:

- same request submitted twice
- same request submitted many times
- concurrent duplicate requests
- same idempotency key with different request payload
- Redis unavailable behavior

## Architecture constraints

Idempotency logic must not be implemented directly inside controllers.

## Verification

The evaluation passes only when:

`./scripts/verify.sh`

returns exit code `0`.
