# Evaluation Example — Idempotency

## Objective
Verify that repeating the same logical operation does not create
duplicate business effects.

## Acceptance Criteria

### AC-1 Repeated operation is deterministic
Repeating the same logical request produces the defined deterministic
result.

### AC-2 No duplicate business side effects
Repeated execution does not create duplicate orders, payments,
reservations, or other business effects.

### AC-3 Database remains consistent
Repeated requests do not corrupt persistent state.

## Required Evidence
| Criterion | Required Evidence |
|---|---|
| AC-1 | Repeated operation test + deterministic result assertion |
| AC-2 | Database side-effect count/state assertion |
| AC-3 | Final consistency assertions |

## Optional Stronger Evidence
Where relevant, execute duplicate requests concurrently.

## Forbidden Shortcuts

- Checking only HTTP response
- Ignoring database side effects
- Deleting duplicate-request tests
- Weakening uniqueness assertions
