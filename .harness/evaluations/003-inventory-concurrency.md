# Evaluation 003 — Inventory Concurrency

## Objective

Verify that the order system correctly handles concurrent inventory
reservation requests and cannot oversell inventory.

This evaluation specifically validates real transaction and concurrency
behavior at the persistence/application boundary.

A sequential unit test or mocked repository test is NOT sufficient evidence
for this evaluation.

---

## Scenario

Assume:

* Product A has inventory quantity = 10.
* Multiple concurrent order requests attempt to purchase Product A.
* The total requested quantity is greater than 10.

The requests must execute against the real persistence layer.

---

## Acceptance Criteria

### AC-1 — Inventory must never become negative

Under concurrent reservation attempts:

```text
final inventory quantity >= 0
```

The database must never contain a negative inventory quantity.

---

### AC-2 — Successful reservations must never exceed available inventory

Given:

```text
initial inventory = 10
```

and concurrent requests whose total requested quantity is greater than 10:

```text
total successfully reserved quantity <= 10
```

The system must never oversell inventory.

---

### AC-3 — Concurrent requests must be handled atomically

Concurrent requests must not both observe the same available inventory and
successfully reserve overlapping inventory.

The implementation must provide a real concurrency guarantee at the
application/persistence boundary.

The guarantee must not depend on HTTP controller logic.

---

### AC-4 — Failed orders must not leave partially reserved inventory

If an order fails because inventory cannot be reserved, the failed order
must not leave behind a partial inventory reservation.

For a failed order:

```text
order creation = rolled back
inventory reservation for that order = rolled back
```

No partially committed business state may remain.

---

### AC-5 — Database state must remain consistent

After all concurrent requests complete:

* inventory quantity must be correct
* successful orders must correspond to successful inventory reservations
* failed orders must not consume inventory
* no negative inventory may exist
* no partially committed order state may remain

---

## Required Concurrency Evidence

The evaluation MUST contain executable evidence that exercises actual
database concurrency.

The test must:

1. Use a real PostgreSQL database.
2. Execute multiple reservation/order operations concurrently.
3. Use independent transactions where the application normally uses
   transactions.
4. Synchronize concurrent workers so that requests genuinely overlap.
5. Attempt to reserve more inventory than is available.
6. Assert the number/quantity of successful reservations.
7. Assert the final inventory quantity.
8. Assert that failed requests do not leave partial business state.
9. Fail if the implementation allows overselling.
10. Be deterministic enough to run repeatedly.

A test that simply calls the service sequentially is NOT sufficient.

A test using mocked repositories or mocked transaction behavior is NOT
sufficient.

A test that merely verifies that a method exists or that a repository method
was called is NOT sufficient.

---

## Required Test Scenarios

### Scenario A — Ten concurrent reservations

Initial inventory:

```text
10
```

Run:

```text
10 concurrent requests
```

Each request purchases:

```text
1
```

Expected:

```text
successful reservations = 10
final inventory = 0
```

No request may reserve more inventory than actually exists.

---

### Scenario B — Eleven concurrent reservations

Initial inventory:

```text
10
```

Run:

```text
11 concurrent requests
```

Each request purchases:

```text
1
```

Expected:

```text
successful reservations <= 10
final inventory >= 0
```

At least one request must fail because inventory is insufficient.

The final inventory must be:

```text
0
```

if all successful reservations consume one unit.

No more than ten orders may successfully reserve inventory.

---

### Scenario C — Competing large reservations

Initial inventory:

```text
10
```

Run concurrently:

```text
Request A → quantity 6
Request B → quantity 6
```

Expected:

```text
exactly one request succeeds
exactly one request fails
final inventory = 4
```

The system must not allow both requests to succeed.

---

### Scenario D — Failed order rollback

Create a scenario where an order requests more inventory than is available.

Verify that:

```text
order creation fails
inventory is not partially consumed
no partially committed order state remains
```

The test must verify the resulting database state, not only the returned
exception or HTTP status.

---

## Required Test Isolation

Concurrency tests must reset database state between scenarios.

Each scenario must start from a known inventory state.

Tests must not depend on execution order or data left behind by another test.

---

## Architecture Constraints

Concurrency control must belong to the application/persistence boundary.

Controllers must not implement concurrency control.

Controllers must not directly access repositories.

The concurrency guarantee must be enforced by mechanisms appropriate to the
actual persistence model, such as transactional locking, optimistic
concurrency control, atomic database operations, or another explicitly
documented mechanism.

The evaluation does not mandate one specific implementation strategy.

---

## Evidence Mapping

Before declaring this evaluation complete, the Test/Reviewer process must
produce an explicit mapping:

| Acceptance Criterion          | Executable Evidence                                         | Result    |
| ----------------------------- | ----------------------------------------------------------- | --------- |
| AC-1 Inventory never negative | Concurrent PostgreSQL test + final inventory assertion      | PASS/FAIL |
| AC-2 No overselling           | Concurrent reservation test + successful quantity assertion | PASS/FAIL |
| AC-3 Atomic concurrency       | Overlapping transaction scenario                            | PASS/FAIL |
| AC-4 Failed order rollback    | Failed-order integration test + DB state assertions         | PASS/FAIL |
| AC-5 Database consistency     | Post-concurrency DB assertions                              | PASS/FAIL |

Every criterion must have evidence.

`NO EVIDENCE` means the evaluation has NOT passed.

---

## Required Tests

At minimum:

* concurrent reservation with exactly available inventory
* concurrent reservation exceeding available inventory
* competing large reservations
* failed reservation/order rollback
* final inventory consistency
* successful order count/quantity consistency

All concurrency tests must use real PostgreSQL.

---

## Verification

The evaluation passes only when:

```bash
./scripts/verify.sh
```

returns exit code:

```text
0
```

However, `verify.sh` PASS alone is NOT sufficient evidence for this
evaluation.

The acceptance criteria and required evidence must also be satisfied.

---

## Forbidden Shortcuts

The agent must not:

* replace concurrency integration tests with unit tests
* replace real PostgreSQL with mocks for concurrency verification
* make the test sequential
* remove concurrency from the scenario
* weaken assertions
* reduce the number of concurrent requests merely to avoid failures
* modify evaluation criteria
* modify task criteria
* disable verification
* modify `verify.sh` to hide failures
* modify verification scripts merely to make this evaluation pass
* hard-code test-specific behavior
* bypass transaction boundaries

If the implementation cannot satisfy the concurrency scenarios, the agent
must fix the implementation rather than weaken the evaluation.

---

## Final Verdict

This evaluation is:

```text
PASS
```

only when:

1. All acceptance criteria have executable evidence.
2. All required concurrency scenarios pass.
3. Real PostgreSQL is used.
4. No overselling occurs.
5. Failed operations leave no partial business state.
6. `./scripts/verify.sh` returns exit code 0.

Otherwise:

```text
FAIL
```
