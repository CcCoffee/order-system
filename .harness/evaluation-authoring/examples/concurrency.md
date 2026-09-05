# Evaluation Example — Concurrency

## Objective
Verify that concurrent operations cannot violate a shared inventory
invariant.

## Scenario
Initial inventory is 10.

Multiple independent requests attempt to reserve inventory concurrently.

The total requested quantity exceeds 10.

## Acceptance Criteria

### AC-1 Inventory never becomes negative
Inventory quantity must never be less than zero.

### AC-2 Successful reservations never exceed available inventory
The total quantity successfully reserved must not exceed the initial
available inventory.

### AC-3 Concurrent operations are handled atomically
Concurrent transactions must not both succeed when doing so would violate
the inventory invariant.

### AC-4 Failed operations leave no partial state
A failed operation must not leave partial inventory reservation or partial
business state.

### AC-5 Database state remains consistent
After all concurrent operations complete, inventory and related business
records must remain mutually consistent.

## Required Evidence
| Criterion | Required Evidence |
|---|---|
| AC-1 | Real PostgreSQL concurrent integration test + final inventory assertion |
| AC-2 | Concurrent reservation test + successful quantity assertion |
| AC-3 | Overlapping independent transactions |
| AC-4 | Failed transaction + database state assertions |
| AC-5 | Final database consistency assertions |

## Required Tests
At minimum:

1. Inventory 10, ten concurrent requests of 1.
2. Inventory 10, eleven concurrent requests of 1.
3. Inventory 10, concurrent requests of 6 and 6.
4. Failed transaction does not leave partial reservation.

## Forbidden Shortcuts

- Sequential execution
- Mocked repository when real persistence is required
- Weakening assertions
- Removing concurrency
- Test-specific production behavior
- Disabling verification
