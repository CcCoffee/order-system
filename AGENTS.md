# Order System Engineering Rules

## 1. Purpose

This repository uses Harness Engineering with GitHub Copilot Custom
Agents.

The goal is to make software changes:

- understandable
- testable
- reviewable
- machine-verifiable
- safe to evolve

The Harness is based on:

Task
→ Agent
→ Code
→ Verification
→ Feedback
→ Repair

---

# 2. Mandatory Rules

Before implementing a non-trivial task:

1. Read this file.
2. Read relevant `.github/instructions/`.
3. Identify the relevant `.harness/evaluations/`.
4. Identify the relevant `.harness/tasks/`.
5. Inspect existing implementation before changing it.

---

# 3. Agent Roles

The repository uses these Custom Agents:

## Order System

Orchestrator.

Primary entry point for multi-agent development.

## Planner

Produces evidence-based implementation plans.

Does not modify production code.

## Backend

Implements backend changes.

## Frontend

Implements frontend changes.

## Test

Adds and executes automated tests.

## Reviewer

Performs independent review.

Does not modify production code.

---

# 4. Engineering Principles

Prefer:

- existing architecture
- existing patterns
- small focused changes
- explicit business rules
- deterministic verification
- meaningful automated tests

Avoid:

- unnecessary rewrites
- speculative abstractions
- unrelated refactors
- test-specific hacks

---

# 5. Backend Rules

Follow the existing architecture.

Typical layering:

Controller
→ Service
→ Repository
→ Database

Business logic should not be placed directly in controllers.

Pay particular attention to:

- transaction boundaries
- state transitions
- concurrency
- idempotency
- data consistency

---

# 6. Frontend Rules

Follow the existing React architecture.

Reuse:

- existing components
- existing API abstractions
- existing state management patterns

Important UI flows should handle:

- loading
- success
- empty
- error

---

# 7. Testing Rules

Tests are part of the product contract.

Never:

- delete tests to hide failures
- weaken assertions
- skip failing tests
- disable verification
- add test-specific hard-coded behavior

When a test fails:

1. understand the failure
2. determine whether implementation is wrong
3. fix implementation
4. rerun tests
5. rerun full verification

---

# 8. Harness Rules

Do not modify Harness evaluation criteria merely to make an implementation
pass.

Do not modify:

- `.harness/evaluations/`
- `.harness/tasks/`
- `scripts/verify.sh`

unless the task explicitly concerns the Harness itself.

When changing Harness definitions intentionally, the change must be
reviewed as an engineering change.

---

# 9. Verification

The canonical verification command is:

./scripts/verify.sh

Focused tests may be executed during development.

However, the task is not complete until:

./scripts/verify.sh

passes.

The verification result is authoritative.

---

# 10. Definition of Done

A feature is complete only when:

- implementation is complete
- relevant tests exist
- review is complete
- full Harness verification passes

Expected final state:

HARNESS VERIFY: PASS

---

# 11. Multi-Agent Workflow

The normal workflow is:

User
→ Order System
→ Planner
→ Backend / Frontend
→ Test
→ Reviewer
→ verify.sh
→ PASS

If verification fails:

FAIL
→ identify responsible agent
→ repair
→ verify.sh again

---

# 12. Keep Harness Simple

This project intentionally does not use:

- baseline evaluation
- performance benchmarking
- token/cost scoring
- execution-time scoring
- unnecessary LLM judging

The primary goal is reliable functional and engineering verification.
