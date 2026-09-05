# Evaluation Example — Transaction

## Objective
Verify that a multi-step business operation is atomic.

## Acceptance Criteria

### AC-1 Successful operation commits all state
All required database changes are persisted when the operation succeeds.

### AC-2 Failed operation rolls back all state
If any required operation fails, no partial business state remains.

### AC-3 Related records remain consistent
Parent and child records must not become partially persisted.

## Required Evidence
| Criterion | Required Evidence |
|---|---|
| AC-1 | Integration test + database assertions |
| AC-2 | Forced failure + rollback + database assertions |
| AC-3 | Post-failure consistency assertions |

## Forbidden Shortcuts

- Mocking transaction behavior
- Testing only annotations
- Checking only HTTP response
- Ignoring database state
- Disabling transactional verification
