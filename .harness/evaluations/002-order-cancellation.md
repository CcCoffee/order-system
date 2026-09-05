# Evaluation 002 — Order Cancellation

## Objective

Verify that the agent correctly implements and preserves the order cancellation
business flow.

## Scenario

An order exists in `PENDING` state and contains one or more items whose inventory
has already been reserved. Cancellation is requested via:

POST `/api/orders/{id}/cancel`

## Acceptance Criteria

### AC-1 Cancellation verifies the order exists
Cancelling a nonexistent order is rejected.

### AC-2 Cancellation verifies the current status is PENDING
Only `PENDING` orders can be cancelled.

### AC-3 Cancellation changes status to CANCELLED
A successful cancellation transitions the order to `CANCELLED`.

### AC-4 Cancellation releases all previously reserved inventory
All reserved inventory for the cancelled order is released exactly once.

### AC-5 Cancellation creates an audit log
A successful cancellation writes an audit log entry.

### AC-6 Cancellation executes transactionally
All cancellation effects (status change, inventory release, audit log) are
atomic.

### AC-7 Invalid transitions are rejected
`PAID -> CANCELLED`, `SHIPPED -> CANCELLED`, and `CANCELLED -> CANCELLED` are
rejected.

### AC-8 Repeated cancellation does not double release inventory
Repeated cancellation must not release inventory multiple times, create duplicate
business effects, or corrupt order state. It returns a deterministic response.

## Required Evidence

Every acceptance criterion MUST have corresponding evidence.

| Criterion | Required Evidence |
|---|---|
| AC-1 | API test cancelling a nonexistent order |
| AC-2 | API/unit test for non-PENDING cancellation |
| AC-3 | Integration test asserting order status becomes CANCELLED |
| AC-4 | Integration test asserting inventory released exactly once |
| AC-5 | Integration test asserting an audit log is created |
| AC-6 | Integration test asserting atomic rollback on failure |
| AC-7 | API/unit tests for invalid cancel transitions |
| AC-8 | Integration test asserting repeated cancel does not double release |

## Required Tests

At minimum:

1. Successful cancellation.
2. Cancellation of a nonexistent order.
3. Cancellation of a `PAID` order.
4. Cancellation of a `SHIPPED` order.
5. Inventory released exactly once.
6. Audit log created.
7. Repeated cancellation does not double-release inventory.

## Architecture Constraints

Business rules must remain outside controllers.
Controllers must not access repositories directly.

## Regression Requirements

Existing order creation, inventory reservation, query, and audit behavior must
remain intact.

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
- Modifying Evaluation criteria to reduce requirements
- Modifying verification scripts to hide failures
- Hard-coding test-specific production behavior
