#!/usr/bin/env bash

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

echo "=============================================="
echo " Harness Evaluation Authoring Setup"
echo "=============================================="
echo
echo "Repository: $ROOT"
echo

# ------------------------------------------------------------
# Helpers
# ------------------------------------------------------------

write_file() {
  local file="$1"
  shift

  mkdir -p "$(dirname "$file")"

  cat > "$file"

  echo "Created: ${file#$ROOT/}"
}

ensure_gitkeep() {
  local dir="$1"

  mkdir -p "$dir"

  if [[ ! -e "$dir/.gitkeep" ]]; then
    touch "$dir/.gitkeep"
  fi
}

# ------------------------------------------------------------
# Directories
# ------------------------------------------------------------

mkdir -p \
  "$ROOT/.github/skills/evaluation-author" \
  "$ROOT/.harness/evaluation-authoring/examples" \
  "$ROOT/.harness/evaluations" \
  "$ROOT/scripts"

# ------------------------------------------------------------
# Evaluation Author Skill
# ------------------------------------------------------------

write_file "$ROOT/.github/skills/evaluation-author/SKILL.md" <<'EOF'
---
name: evaluation-author
description: Create and review high-quality Harness Evaluation specifications that are behavior-focused, independently testable, evidence-driven, and resistant to weak test implementations.
---

# Evaluation Author

You are an Evaluation Specification Engineer.

Your responsibility is to create Evaluation specifications that define
what must be true for a task to be considered complete.

You do NOT design the implementation.

You define:

- required behavior
- acceptance criteria
- invariants
- failure behavior
- required evidence
- required test level
- regression expectations
- forbidden shortcuts

The Evaluation must be strong enough that an incorrect implementation
cannot easily pass by adding a superficial test.

---

# Core Principles

## 1. Define behavior, not implementation

Prefer:

"Concurrent requests must never oversell inventory."

Avoid:

"Use SELECT FOR UPDATE."

Only prescribe a specific implementation when the architecture or
technology requirement is itself part of the product contract.

---

## 2. Every acceptance criterion must be independently testable

Each requirement must be expressible as a concrete condition that can
be verified.

Bad:

"The system should be robust."

Good:

"Inventory quantity must never become negative after concurrent
reservation attempts."

---

## 3. Every acceptance criterion must have evidence

Every AC must map to one or more explicit verification strategies.

Required structure:

Acceptance Criterion
        ↓
Required Evidence
        ↓
Actual Test / Verification

Never create an acceptance criterion that has no evidence strategy.

---

## 4. Evidence must be strong enough to falsify an incorrect implementation

Ask:

"Could a broken implementation still pass this test?"

If yes, the evidence is insufficient.

For example:

Requirement:

"Concurrent reservations must not oversell inventory."

Insufficient:

- call reserve() twice sequentially
- mock the repository
- assert only HTTP status
- assert only that a method was invoked

Strong:

- real PostgreSQL
- multiple concurrent transactions
- synchronized start
- requested quantity exceeds inventory
- assert successful reservations
- assert final inventory
- assert failed transactions leave no partial state

---

## 5. Stateful behavior requires state verification

For requirements involving:

- transactions
- persistence
- inventory
- orders
- cancellation
- rollback
- idempotency
- concurrency

Do not rely only on API responses.

Verify relevant database state.

---

## 6. Use the minimum test level that can prove the requirement

Default preference:

1. Unit
2. Integration
3. API
4. E2E

But the requirement overrides this preference.

Examples:

- pure domain rule → unit test
- transaction rollback → integration test
- PostgreSQL locking → real PostgreSQL integration test
- API contract → API test
- complete user workflow → E2E

---

## 7. Include failure paths

For each important operation consider:

- invalid input
- nonexistent entity
- invalid state
- insufficient inventory
- transaction failure
- duplicate request
- concurrent request
- partial failure

Do not specify only the happy path.

---

# Evaluation Structure

Every Evaluation should contain:

1. Objective
2. Context / Scenario
3. Acceptance Criteria
4. Required Evidence
5. Required Tests
6. Architecture Constraints
7. Regression Requirements
8. Verification
9. Forbidden Shortcuts

---

# Acceptance Criteria

Use stable identifiers:

AC-1
AC-2
AC-3
...

Each criterion should represent one independently meaningful requirement.

Example:

### AC-1 Inventory never becomes negative

Inventory quantity must never fall below zero under concurrent
reservation attempts.

### AC-2 Successful reservations never exceed available inventory

The total successfully reserved quantity must not exceed the initial
available inventory.

---

# Evidence Matrix

Every Evaluation MUST contain an evidence mapping.

Example:

| Criterion | Required Evidence |
|---|---|
| AC-1 | Real PostgreSQL concurrent integration test + final inventory assertion |
| AC-2 | Concurrent reservation test + successful quantity assertion |
| AC-3 | Overlapping transaction scenario |
| AC-4 | Failed transaction + database state assertions |

If an acceptance criterion cannot be mapped to evidence, the Evaluation
is incomplete.

---

# Concurrency Requirements

When the requirement involves concurrency, explicitly require:

- real concurrent execution
- independent transactions where appropriate
- real persistence when persistence behavior is under evaluation
- synchronization rather than arbitrary sleeps
- assertions on final state
- assertions on both success and failure

Avoid prescribing one implementation mechanism unless required.

Do NOT accept a sequential loop as concurrency evidence.

---

# Transaction Requirements

When evaluating transaction behavior, specify:

- atomicity
- rollback
- database state
- partial failure behavior
- transaction boundary

Do not only require an annotation such as @Transactional.

The evidence must demonstrate actual transactional behavior.

---

# Idempotency Requirements

For idempotency:

- execute the same logical operation multiple times
- verify deterministic result
- verify no duplicate business side effects
- verify database state
- consider concurrent duplicate requests when relevant

---

# Regression

Only include regression requirements that are materially related to the
change.

Avoid requiring unrelated test suites merely to increase test quantity.

---

# Forbidden Shortcuts

Use forbidden shortcuts to prevent gaming the Evaluation.

Examples:

- replacing required integration tests with mocks
- replacing concurrent execution with sequential execution
- weakening assertions
- deleting tests
- skipping failures
- modifying Evaluation criteria
- modifying verification scripts to make the task pass
- hard-coding test-specific behavior
- bypassing transaction requirements

Do not create artificial restrictions unrelated to correctness.

---

# Quality Checklist

Before finalizing an Evaluation, verify:

- [ ] Objective is clear
- [ ] Acceptance criteria are independently testable
- [ ] Every AC has explicit evidence
- [ ] Evidence is strong enough to detect incorrect behavior
- [ ] Happy path is covered
- [ ] Important failure paths are covered
- [ ] Stateful requirements verify state
- [ ] Transaction requirements use integration evidence
- [ ] Concurrency requirements use real concurrency
- [ ] Required database behavior uses real database where necessary
- [ ] Architecture constraints are meaningful
- [ ] Regression requirements are relevant
- [ ] Verification requirement exists
- [ ] Forbidden shortcuts are defined
- [ ] Implementation details are not unnecessarily prescribed

---

# Final Rule

An Evaluation is not complete merely because it contains requirements.

It is complete only when:

Every acceptance criterion
    has explicit evidence
    that can meaningfully prove or disprove the criterion.

If the Evaluation cannot be objectively verified, improve the Evaluation
before allowing implementation to begin.
EOF

# ------------------------------------------------------------
# Schema
# ------------------------------------------------------------

write_file "$ROOT/.harness/evaluation-authoring/schema.md" <<'EOF'
# Harness Evaluation Schema

An Evaluation is a behavioral contract.

It should define what must be true, how that truth can be demonstrated,
and what shortcuts are forbidden.

## Required Sections

### 1. Objective

Describe the capability being evaluated.

### 2. Scenario

Describe the relevant initial state and important conditions.

### 3. Acceptance Criteria

Use:

- AC-1
- AC-2
- AC-3
- ...

Each AC must be independently testable.

### 4. Required Evidence

Every AC must appear in the evidence mapping.

Example:

| Criterion | Required Evidence |
|---|---|
| AC-1 | Integration test + database assertion |
| AC-2 | API test + response assertion |

### 5. Required Tests

Describe the minimum test behavior required.

### 6. Architecture Constraints

Only include constraints that are important to correctness or
maintainability.

### 7. Regression Requirements

Describe related existing behavior that must remain intact.

### 8. Verification

Normally:

```text
./scripts/verify.sh
```

### 9. Forbidden Shortcuts
Prevent gaming the Evaluation.

---

# Evidence Rule
For every:

```
AC-N
```
there must be corresponding:

```
Evidence
```
An Evaluation with an acceptance criterion but no evidence is invalid.

---

# Test Strength
A test is valid evidence only if it exercises the behavior described
by the criterion.

Test count is not evidence quality.

---

# Implementation Independence
Do not require a particular implementation strategy unless that strategy
is explicitly part of the architecture contract.
EOF

# ------------------------------------------------------------
# Checklist
# ------------------------------------------------------------

write_file "$ROOT/.harness/evaluation-authoring/checklist.md" <<'EOF'
# Evaluation Authoring Checklist

## Specification

- Objective is specific
- Scenario defines important initial state
- Acceptance criteria are independently testable
- Acceptance criteria describe behavior rather than implementation

## Evidence

- Every AC has evidence
- Evidence can detect an incorrect implementation
- Evidence verifies important state
- Evidence verifies failure paths
- Evidence verifies side effects where relevant

## Concurrency
If concurrency is involved:

- Real concurrent execution is required
- Independent transactions are used where appropriate
- Real database is used when persistence behavior matters
- No sequential substitute is accepted
- Final state is asserted
- Success and failure are both verified

## Transactions
If transactions are involved:

- Atomicity is specified
- Rollback behavior is specified
- Partial state is checked
- Integration-level evidence is required

## Idempotency
If idempotency is involved:

- Duplicate execution is tested
- Duplicate business side effects are checked
- Final state is checked
- Concurrent duplicates are considered where relevant

## Architecture

- Business logic boundaries are clear
- Controller/repository constraints are meaningful
- No unnecessary implementation restrictions

## Anti-Gaming

- No weakening tests
- No deleting tests
- No mocks replacing required real integrations
- No sequential replacement for concurrency
- No test-specific production behavior
- No modification of Evaluation to lower requirements
- No modification of verification scripts to hide failures

## Final

- Required tests are explicit
- Verification is explicit
- Forbidden shortcuts are explicit
EOF

# ------------------------------------------------------------
# Concurrency example
# ------------------------------------------------------------

write_file "$ROOT/.harness/evaluation-authoring/examples/concurrency.md" <<'EOF'
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
EOF

# ------------------------------------------------------------
# Transaction example
# ------------------------------------------------------------

write_file "$ROOT/.harness/evaluation-authoring/examples/transaction.md" <<'EOF'
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
EOF

# ------------------------------------------------------------
# Idempotency example
# ------------------------------------------------------------

write_file "$ROOT/.harness/evaluation-authoring/examples/idempotency.md" <<'EOF'
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
EOF

# ------------------------------------------------------------
# Evaluation Template
# ------------------------------------------------------------

write_file "$ROOT/.harness/evaluations/TEMPLATE.md" <<'EOF'
# Evaluation XXXX —

## Objective
Describe the capability being evaluated.

## Scenario
Describe the initial state and important conditions.

## Acceptance Criteria

### AC-1
Describe the required behavior.

### AC-2
Describe the required behavior.

## Required Evidence
Every acceptance criterion MUST have corresponding evidence.

| Criterion | Required Evidence |
|---|---|
| AC-1 |  |
| AC-2 |  |

## Required Tests
List the tests required to produce the evidence.

## Architecture Constraints
Describe only architecture constraints relevant to correctness,
maintainability, or explicit project design.

## Regression Requirements
Describe related existing behavior that must remain intact.

## Verification
The repository must pass:

```
./scripts/verify.sh
```
Repository verification does not substitute for missing Evaluation
evidence.

## Forbidden Shortcuts

- Weakening tests
- Deleting tests
- Skipping failures
- Replacing required integration tests with mocks
- Replacing required concurrency with sequential execution
- Modifying Evaluation criteria to reduce requirements
- Modifying verification scripts to hide failures
- Hard-coding test-specific production behavior

## Completion Rule
The Evaluation is satisfied only when:

1. Every acceptance criterion has sufficient evidence.
2. Required tests pass.
3. Relevant regression tests pass.
4. Architecture constraints are satisfied.
5. `./scripts/verify.sh` passes.
EOF

# ------------------------------------------------------------
# Evaluation Linter
# ------------------------------------------------------------

write_file "$ROOT/scripts/verify-evaluations.sh" <<'EOF'
#!/usr/bin/env bash

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
EVAL_DIR="$ROOT/.harness/evaluations"

echo "=============================================="
echo " Harness Evaluation Verification"
echo "=============================================="
echo

if [[ ! -d "$EVAL_DIR" ]]; then
  echo "FAIL: missing .harness/evaluations"
  exit 1
fi

mapfile -t files < <(
  find "$EVAL_DIR" -maxdepth 1 -type f -name '*.md' \
    ! -name 'TEMPLATE.md' \
    | sort
)

if [[ ${#files[@]} -eq 0 ]]; then
  echo "PASS: no Evaluation files found"
  exit 0
fi

failed=0

for file in "${files[@]}"; do
  name="${file#$ROOT/}"

  echo "Checking: $name"

  required_sections=(
    "## Objective"
    "## Acceptance Criteria"
    "## Required Evidence"
    "## Required Tests"
    "## Architecture Constraints"
    "## Verification"
    "## Forbidden Shortcuts"
  )

  for section in "${required_sections[@]}"; do
    if ! grep -Fq "$section" "$file"; then
      echo " FAIL: missing section: $section"
      failed=1
    else
      echo " PASS: $section"
    fi
  done

  # ----------------------------------------------------------
  # Extract AC identifiers
  # ----------------------------------------------------------
  mapfile -t criteria < <(
    grep -E '^### AC-[0-9]+' "$file" \
      | sed -E 's/^### (AC-[0-9]+).*/\1/' \
      | sort -V \
      | uniq
  )

  if [[ ${#criteria[@]} -eq 0 ]]; then
    echo " FAIL: no Acceptance Criteria found"
    failed=1
  else
    echo " PASS: found ${#criteria[@]} Acceptance Criteria"
  fi

  # ----------------------------------------------------------
  # Evidence coverage
  # ----------------------------------------------------------
  if [[ ${#criteria[@]} -gt 0 ]]; then
    for criterion in "${criteria[@]}"; do
      if grep -Fq "$criterion" "$file"; then
        echo " PASS: evidence reference exists for $criterion"
      else
        echo " FAIL: no evidence reference for $criterion"
        failed=1
      fi
    done
  fi

  # ----------------------------------------------------------
  # Detect obviously weak concurrency specifications
  # ----------------------------------------------------------
  if grep -Eiq 'concurr|concurrent|race condition|oversell|locking|parallel' "$file"; then
    echo "  INFO: concurrency-related Evaluation detected"

    concurrency_requirements=(
      "real"
      "integration"
      "concurrent"
    )

    for keyword in "${concurrency_requirements[@]}"; do
      if grep -Eiq "$keyword" "$file"; then
        echo "  PASS: concurrency evidence mentions '$keyword'"
      else
        echo "  WARN: concurrency Evaluation does not explicitly mention '$keyword'"
      fi
    done

    if grep -Eiq 'sequential execution|sequential.*not|not.*sequential|mock.*not|not.*mock' "$file"; then
      echo "  PASS: concurrency anti-shortcut guidance found"
    else
      echo "  WARN: consider explicitly forbidding sequential/mock substitutes"
    fi
  fi

  # ----------------------------------------------------------
  # Verification
  # ----------------------------------------------------------
  if grep -Fq './scripts/verify.sh' "$file"; then
    echo " PASS: repository verification defined"
  else
    echo " FAIL: ./scripts/verify.sh not referenced"
    failed=1
  fi

  echo
done

echo "----------------------------------------------"

if [[ "$failed" -ne 0 ]]; then
  echo "HARNESS EVALUATION VERIFY: FAIL"
  exit 1
fi

echo "HARNESS EVALUATION VERIFY: PASS"
EOF

chmod +x "$ROOT/scripts/verify-evaluations.sh"

# ------------------------------------------------------------
# Ensure expected directories exist
# ------------------------------------------------------------
ensure_gitkeep "$ROOT/.harness/reports"
ensure_gitkeep "$ROOT/.harness/state"

# ------------------------------------------------------------
# Final output
# ------------------------------------------------------------
echo
echo "=============================================="
echo " Evaluation Authoring setup complete"
echo "=============================================="
echo
echo "Created:"
echo " .github/skills/evaluation-author/SKILL.md"
echo " .harness/evaluation-authoring/schema.md"
echo " .harness/evaluation-authoring/checklist.md"
echo " .harness/evaluation-authoring/examples/concurrency.md"
echo " .harness/evaluation-authoring/examples/transaction.md"
echo " .harness/evaluation-authoring/examples/idempotency.md"
echo " .harness/evaluations/TEMPLATE.md"
echo " scripts/verify-evaluations.sh"
echo
echo "Run:"
echo
echo " ./scripts/verify-evaluations.sh"
echo
echo "Then run:"
echo
echo " ./scripts/verify.sh"
echo
echo "Existing Evaluation files were not modified."
echo
