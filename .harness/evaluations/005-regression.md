# Evaluation 005 — Regression

## Objective

Verify that new changes do not break previously established behavior.

## Scenario

A new implementation is introduced. Previously established capabilities must
continue to work as before.

## Acceptance Criteria

### AC-1 Product and inventory lookup continue to work
Product lookup and inventory lookup remain functional.

### AC-2 Order creation continues to work
Order creation remains functional and atomic.

### AC-3 Order detail continues to work
Order detail retrieval remains functional.

### AC-4 Order cancellation continues to work
Order cancellation remains functional.

### AC-5 Order state transitions are preserved
Valid and invalid order state transitions behave as before.

### AC-6 Inventory reservation and release are preserved
Inventory reservation and release behave as before.

### AC-7 Audit logging is preserved
Audit logging remains functional.

### AC-8 Redis integration is preserved
Redis integration remains functional.

### AC-9 Frontend flows are preserved
Frontend order creation, detail, and cancellation continue to work.

### AC-10 API contract and architecture rules are preserved
API contract and architecture rules remain satisfied.

## Required Evidence

Every acceptance criterion MUST have corresponding evidence.

| Criterion | Required Evidence |
|---|---|
| AC-1 | Repository/API lookup test |
| AC-2 | Integration/API create order test |
| AC-3 | API order detail test |
| AC-4 | Integration/API cancel test |
| AC-5 | Unit test asserting valid/invalid transitions |
| AC-6 | Integration test asserting reservation/release |
| AC-7 | Integration test asserting audit log |
| AC-8 | Integration test asserting Redis behavior |
| AC-9 | Frontend/E2E test |
| AC-10 | Architecture test + OpenAPI lint |

## Required Tests

Run the complete Harness verification suite:

```
./scripts/verify.sh
```

## Architecture Constraints

No new change may weaken the existing layered architecture or the API contract.

## Regression Requirements

All previously established capabilities listed in the acceptance criteria must
remain intact.

## Verification

The full Harness verification suite must pass:

```
./scripts/verify.sh
```

## Forbidden Shortcuts

The agent must not:

- delete tests
- weaken assertions
- disable architecture checks
- modify evaluation criteria
- bypass integration tests
- remove Redis usage
- change verification scripts merely to hide failures

## Success Criteria

Regression evaluation passes only when all existing verification checks continue
to pass after the new implementation is introduced.
