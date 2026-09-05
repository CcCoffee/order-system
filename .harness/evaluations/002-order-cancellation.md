# Evaluation 002 — Order Cancellation

## Objective

Verify that the agent correctly implements and preserves the order cancellation
business flow.

## Preconditions

An order exists in `PENDING` state.

The order contains one or more items whose inventory has already been reserved.

## Required behavior

Calling:

POST `/api/orders/{id}/cancel`

must:

1. Verify that the order exists.
2. Verify that the current status is `PENDING`.
3. Change status to `CANCELLED`.
4. Release all previously reserved inventory.
5. Create an audit log.
6. Execute the operation transactionally.

## Invalid transitions

The following must be rejected:

- `PAID -> CANCELLED`
- `SHIPPED -> CANCELLED`
- `CANCELLED -> CANCELLED`

## Idempotency of cancellation

Repeated cancellation requests must not:

- release inventory multiple times
- create duplicate business effects
- corrupt order state

The API should return a deterministic response for repeated cancellation attempts.

## Required tests

At minimum:

- successful cancellation
- cancellation of nonexistent order
- cancellation of PAID order
- cancellation of SHIPPED order
- inventory released exactly once
- audit log created
- repeated cancellation does not double-release inventory

## Architecture constraints

Business rules must remain outside controllers.

Controllers must not access repositories directly.

## Verification

The evaluation passes only when:

`./scripts/verify.sh`

returns exit code `0`.
