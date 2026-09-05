# Order System Engineering Rules

## 1. Purpose

This repository uses Harness Engineering with GitHub Copilot Custom Agents.

The goal is to make software changes:

* understandable
* testable
* reviewable
* machine-verifiable
* safe to evolve

The engineering system is built around:

```text
Requirement
    ↓
Planning
    ↓
Implementation
    ↓
Testing
    ↓
Review
    ↓
Verification
    ↓
Feedback
    ↓
Repair
```

The repository separates four concerns:

```text
docs/
    Project knowledge and architectural context

.harness/
    Tasks, evaluations, and verification rules

.github/agents/
    Specialized development agents

src / backend / frontend
    Product implementation
```

---

# 2. Source of Truth

Different repository areas have different responsibilities.

## docs/

`docs/` is the project's knowledge base.

It describes:

* how the system currently works
* API contracts
* database structure
* architecture
* important architectural decisions
* Harness usage documentation

Examples:

```text
docs/architecture/
docs/api/
docs/database/
docs/decisions/
```

Agents should read relevant documentation before making changes.

Documentation should reflect the current implementation and architectural decisions.

---

## .harness/

`.harness/` is the project's Harness control layer.

It contains:

* tasks
* evaluations
* verification configuration
* Harness workflow documentation
* Harness state when applicable

The Harness defines:

> What must be implemented and what conditions must be satisfied.

It should not duplicate the general project documentation in `docs/`.

---

## .github/agents/

`.github/agents/` contains specialized GitHub Copilot Custom Agents.

Agents have explicit responsibilities and boundaries.

An Agent should only modify files that are within its assigned responsibility unless the task explicitly requires otherwise.

---

# 3. Mandatory Rules

Before implementing a non-trivial task:

1. Read this file.
2. Read relevant `.github/instructions/`.
3. Read relevant `docs/` documentation.
4. Identify relevant `.harness/evaluations/`.
5. Identify relevant `.harness/tasks/`.
6. Inspect the existing implementation before changing it.
7. Reuse existing architecture and patterns whenever possible.

Do not start implementation based only on the user request when the repository already contains relevant architectural or business context.

---

# 4. Agent Roles

The repository uses the following Custom Agents.

## Order System

The Orchestrator and primary entry point for multi-agent development.

Responsibilities:

* understand the user requirement
* invoke Planner
* coordinate implementation agents
* coordinate Test
* invoke Reviewer
* run final verification
* route failures to the responsible agent
* repeat verification after repairs

Order System should coordinate the workflow rather than directly implementing substantial product changes.

---

## Planner

Produces an evidence-based implementation plan.

Responsibilities:

* understand the requirement
* inspect the existing implementation
* identify affected components
* identify architecture impact
* identify API/database changes
* identify required tests
* identify documentation changes
* identify relevant Evaluations
* define machine-verifiable acceptance criteria

Planner must not modify production code.

Planner may propose a new Evaluation when a new important business capability is identified.

However:

> Planner must not unilaterally modify the official `.harness/evaluations/` definitions.

Formal Evaluation changes require explicit human/team approval or an explicitly authorized Harness-maintenance task.

---

## Backend

Implements backend changes.

Responsibilities:

* backend production code
* backend tests
* database migrations when required
* backend API implementation
* backend documentation updates when the implementation changes documented behavior

Backend must follow existing architecture and transaction boundaries.

Backend must not modify Harness evaluation criteria merely to make an implementation pass.

---

## Frontend

Implements frontend changes.

Responsibilities:

* React production code
* frontend tests
* API integration
* user-facing error/loading states
* frontend documentation updates when required

Frontend should use the existing API contracts and frontend architecture.

---

## Test

Creates and executes automated tests.

Responsibilities:

* unit tests
* integration tests
* API tests
* concurrency tests
* regression tests
* E2E tests when applicable
* executing focused verification
* executing full verification

Test must not modify production code merely to make tests pass.

Test must not weaken assertions or remove failing tests.

---

## Reviewer

Performs an independent engineering review.

Reviewer is read-only by default.

Reviewer checks:

* functional correctness
* business rules
* architecture
* transaction boundaries
* concurrency
* idempotency
* data consistency
* API compatibility
* security
* regression risk
* test quality
* documentation consistency

Reviewer should identify problems rather than silently fixing them.

---

# 5. Multi-Agent Workflow

The normal workflow is:

```text
User
  ↓
Order System
  ↓
Planner
  ↓
Backend / Frontend
  ↓
Test
  ↓
Reviewer
  ↓
./scripts/verify.sh
  ↓
PASS
```

When verification fails:

```text
FAIL
  ↓
Identify failure
  ↓
Identify responsible agent
  ↓
Repair
  ↓
Test
  ↓
Reviewer when appropriate
  ↓
./scripts/verify.sh
  ↓
PASS
```

The Order System Agent is the orchestration root.

Specialized agents should not independently redesign the workflow.

---

# 6. Planning Rules

Planner must inspect the repository before proposing implementation.

A plan should normally contain:

```text
Requirement
Existing Implementation
Architecture Impact
Backend Changes
Frontend Changes
Database Changes
API Changes
Documentation Changes
Relevant Evaluations
Tests
Acceptance Criteria
Risks
Verification Plan
```

The plan should distinguish:

* what already exists
* what needs to change
* what must remain unchanged

Avoid speculative implementation.

Prefer the smallest change that satisfies the requirement and existing contracts.

---

# 7. Evaluation Rules

Evaluation defines:

> What does "correct" mean for an important system capability?

Evaluation is not a Jira ticket and does not need to map one-to-one to requirements.

Prefer:

```text
Multiple related requirements
        ↓
One business capability
        ↓
One Evaluation
```

For example:

```text
REQ-101 Add cancel button
REQ-102 Add cancel API
REQ-103 Release inventory
REQ-104 Write audit log
```

may be covered by:

```text
002-order-cancellation.md
```

rather than four separate Evaluation files.

---

## When to create a new Evaluation

Create or extend an Evaluation when a requirement introduces or changes an important capability or business rule, especially when the behavior:

* is business-critical
* is easy to break accidentally
* has concurrency or consistency requirements
* has idempotency requirements
* represents an important state transition
* should be protected against future regression

Do not create a new Evaluation for every small UI or implementation change.

Examples that usually deserve Evaluation:

* order cancellation
* inventory concurrency
* order idempotency
* payment state transitions
* authorization rules
* important business invariants

Examples that normally do not:

* changing button text
* changing CSS
* changing spacing
* ordinary refactoring with unchanged behavior

---

## Evaluation vs Test

Evaluation describes:

> What must be true.

Tests and verification determine:

> Whether it is true.

For example:

```text
Evaluation:

PENDING orders can be cancelled.

Cancellation must release reserved inventory.

Repeated cancellation must not release inventory twice.
```

The implementation may use any appropriate design as long as the required behavior is satisfied.

Do not unnecessarily encode implementation details into Evaluations.

Prefer:

```text
What must happen
```

over:

```text
Exactly how the code must be written
```

unless the implementation detail is itself an explicit architectural requirement.

---

## Evaluation Ownership

Formal Evaluations are engineering governance artifacts.

Agents must not modify:

```text
.harness/evaluations/
```

merely to make their implementation pass.

If implementation reveals that an Evaluation is incorrect, incomplete, or outdated:

```text
Agent
  ↓
Report proposed change
  ↓
Human / authorized Harness maintenance
  ↓
Update Evaluation
  ↓
Re-run verification
```

---

# 8. Documentation Rules

Documentation is part of the engineering system.

When implementation changes documented system behavior, the relevant documentation must be updated in the same change.

## API changes

If API behavior changes, update:

```text
docs/api/openapi.yaml
```

when applicable.

---

## Database changes

If the database schema or important database behavior changes, update:

```text
docs/database/schema.md
```

when applicable.

---

## Architecture changes

If the system architecture changes, update the relevant:

```text
docs/architecture/
```

documentation.

---

## Architectural decisions

When an important architectural decision is made, add or update an ADR under:

```text
docs/decisions/
```

ADR should explain:

* the problem
* the decision
* alternatives considered when useful
* consequences

Do not create ADRs for trivial implementation choices.

---

## Harness documentation

The following documents describe Harness itself:

```text
docs/HARNESS-QUICK-START.md
docs/HARNESS-EVALUATION-GUIDE.md
```

They should only be changed when the team's Harness methodology changes.

Normal product development should not modify them.

---

# 9. Documentation Ownership

The following ownership model is recommended:

| Area                    | Primary owner             |
| ----------------------- | ------------------------- |
| `docs/api/`             | Backend / team            |
| `docs/database/`        | Backend / team            |
| `docs/architecture/`    | Engineering team          |
| `docs/decisions/`       | Human / Tech Lead         |
| `docs/HARNESS-*`        | Harness maintainer / team |
| `.harness/evaluations/` | Human / team              |
| `.harness/tasks/`       | Planner / task author     |
| `scripts/verify.sh`     | Harness maintainer / team |

Agents may update implementation-related documentation when required by their changes.

Agents should not silently change architectural decisions or Harness governance.

---

# 10. Engineering Principles

Prefer:

* existing architecture
* existing patterns
* small focused changes
* explicit business rules
* deterministic verification
* meaningful automated tests
* minimal changes
* backward compatibility where required

Avoid:

* unnecessary rewrites
* speculative abstractions
* unrelated refactors
* test-specific hacks
* duplicated implementations
* silently changing contracts
* weakening existing guarantees

Before introducing a new abstraction, verify that the existing architecture cannot reasonably support the requirement.

---

# 11. Backend Rules

Follow the existing backend architecture.

Typical layering:

```text
Controller
    ↓
Service
    ↓
Repository
    ↓
Database
```

Business logic should not be placed directly in controllers.

Pay particular attention to:

* transaction boundaries
* state transitions
* concurrency
* idempotency
* data consistency
* error handling
* API compatibility

Database modifications must consider:

* migrations
* indexes
* constraints
* transaction behavior
* existing data

---

# 12. Frontend Rules

Follow the existing React architecture.

Reuse:

* existing components
* existing API abstractions
* existing state management
* existing routing
* existing styling patterns

Important UI flows should handle:

* loading
* success
* empty
* error
* retry when appropriate

Frontend should consume the established API contract rather than independently inventing request/response structures.

---

# 13. Testing Rules

Tests are part of the product contract.

Tests should verify behavior rather than implementation details whenever practical.

Never:

* delete tests to hide failures
* weaken assertions
* skip failing tests
* disable verification
* add test-specific hard-coded behavior
* change production behavior solely to satisfy an incorrect test

When a test fails:

```text
1. Understand the failure
2. Determine whether implementation or test is wrong
3. Fix the actual problem
4. Rerun the focused test
5. Rerun full verification
```

If the test itself is genuinely incorrect, explain why before changing it.

---

# 14. Harness Protection Rules

The following are protected Harness artifacts:

```text
.harness/evaluations/
.harness/tasks/
scripts/verify.sh
```

Do not modify them merely to make an implementation pass.

A product implementation must adapt to the established acceptance criteria.

Harness definitions may only be changed when the task explicitly concerns the Harness or when an approved requirement intentionally changes the contract.

Harness changes are engineering changes and must themselves be reviewed and verified.

---

# 15. Verification

The canonical verification command is:

```bash
./scripts/verify.sh
```

Focused tests may be executed during development.

However:

> A task is not complete until the canonical verification passes.

The verification result is authoritative.

Expected final state:

```text
HARNESS VERIFY: PASS
```

Do not claim a task is complete when verification has not been executed or has failed.

---

# 16. Definition of Done

A feature is complete only when:

* implementation is complete
* relevant tests exist
* relevant documentation is updated
* review is complete
* relevant Evaluations are satisfied
* full Harness verification passes

Expected final state:

```text
Implementation
    +
Tests
    +
Documentation
    +
Review
    +
Evaluation
    +
Verification
    =
DONE
```

---

# 17. Failure Handling

When verification fails, do not immediately change the verification criteria.

First determine:

1. What failed?
2. Which Evaluation or requirement is affected?
3. Is the implementation wrong?
4. Is the test wrong?
5. Is the documentation stale?
6. Is there a genuine Harness definition problem?

The default assumption is:

> Fix the implementation before changing the acceptance criteria.

Only change Harness definitions when the requirement or engineering contract has intentionally changed.

---

# 18. Keep Harness Simple

This project intentionally does not use:

* baseline evaluation
* performance benchmarking
* token/cost scoring
* execution-time scoring
* unnecessary LLM judging

The primary goal is:

> reliable functional and engineering verification.

Harness should remain small enough that developers understand it and agents can reliably operate within it.

Prefer deterministic verification over subjective scoring whenever possible.

---

# 19. Final Mental Model

The repository can be understood as four layers:

```text
┌──────────────────────────────────────────┐
│ Requirement                              │
│ What does the user want?                 │
└────────────────────┬─────────────────────┘
                     ↓
┌──────────────────────────────────────────┐
│ docs/                                    │
│ How does the system work?                │
│ Why was it designed this way?             │
└────────────────────┬─────────────────────┘
                     ↓
┌──────────────────────────────────────────┐
│ .harness/                                │
│ What must be true?                       │
│ How do we verify it?                     │
└────────────────────┬─────────────────────┘
                     ↓
┌──────────────────────────────────────────┐
│ Agents + Code                            │
│ How should we implement it?              │
└────────────────────┬─────────────────────┘
                     ↓
┌──────────────────────────────────────────┐
│ Verification                             │
│ Did we actually do it correctly?         │
└──────────────────────────────────────────┘
```

Remember:

> **Requirement defines what is wanted.**

> **docs explain what the system is and why it works that way.**

> **Planner determines how the requirement can be implemented.**

> **Evaluation defines what correct behavior means.**

> **Agents implement the change.**

> **Tests and verification prove whether the change is correct.**

> **The Harness prevents the implementation process from drifting away from the engineering contract.**
