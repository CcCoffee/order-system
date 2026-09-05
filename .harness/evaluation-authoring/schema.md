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
