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

The repository separates product engineering from Harness engineering.

```text
docs/
    Product and system knowledge

.harness/
    Harness control layer

.github/agents/
    Specialized development agents

backend/
frontend/
    Product implementation

scripts/
    Development, testing, and verification commands
```

---

# 2. Repository Source of Truth

Different repository areas have different responsibilities.

## docs/

`docs/` is the product and system knowledge base.

It describes:

* current architecture
* API contracts
* database structure
* system behavior
* important architectural decisions

Typical structure:

```text
docs/
├── architecture/
├── api/
├── database/
└── decisions/
```

Product documentation should reflect the actual implementation.

---

## .harness/

`.harness/` is the Harness control layer.

It contains:

* Tasks
* Evaluations
* Harness configuration
* Harness state
* Harness methodology documentation

Typical structure:

```text
.harness/
├── config/
├── docs/
├── evaluations/
├── tasks/
└── state/
```

`.harness/docs/` contains documentation about the Harness itself.

For example:

```text
.harness/docs/
├── HARNESS-DEVELOPER-GUIDE.md
├── HARNESS-QUICK-START.md
└── HARNESS-EVALUATION-GUIDE.md
```

Do not mix Harness methodology with normal product documentation.

---

## .github/agents/

`.github/agents/` contains GitHub Copilot Custom Agents.

Agents have explicit responsibilities and boundaries.

An Agent should only modify files within its assigned responsibility unless the task explicitly requires otherwise.

---

## scripts/

`scripts/` contains executable development, test, infrastructure, and verification commands.

Important categories include:

```text
Infrastructure:
start-infra.sh
stop-infra.sh
reset-infra.sh

Testing:
integration-test.sh
e2e.sh

Evaluation:
run-evaluation.sh

Verification:
verify.sh
verify-*.sh
```

Verification scripts are part of the Harness control system and must be treated as protected engineering artifacts.

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
* identify the applicable Evaluation
* identify the applicable Task
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

Planner must not unilaterally modify official Evaluation definitions.

---

## Backend

Implements backend changes.

Responsibilities:

* backend production code
* backend tests
* database migrations when required
* backend API implementation
* backend documentation updates when implementation changes documented behavior

Backend must follow existing architecture and transaction boundaries.

Backend must not modify Harness acceptance criteria or verification rules merely to make an implementation pass.

---

## Frontend

Implements frontend changes.

Responsibilities:

* React production code
* frontend tests
* API integration
* user-facing error/loading states
* frontend documentation updates when required

Frontend should use established API contracts and frontend architecture.

Frontend must not modify Harness acceptance criteria or verification rules merely to make an implementation pass.

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
* focused verification
* full verification

Test must not modify production behavior merely to make tests pass.

Test must not:

* weaken assertions
* delete tests
* skip failures
* disable verification
* modify verification scripts to hide failures

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

# 5. Normal Multi-Agent Workflow

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
Verification
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
Review when appropriate
  ↓
Verification
  ↓
PASS
```

The Order System Agent is the orchestration root.

Specialized agents should not independently redesign the workflow.

For normal development, users should invoke `Order System` rather than manually invoking every specialized Agent.

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

# 8. Evaluation vs Test vs Verification

These concepts are related but different.

## Evaluation

Answers:

> What must be true?

Example:

```text
PENDING orders can be cancelled.

Cancellation must release reserved inventory.

Repeated cancellation must not release inventory twice.
```

---

## Test

Answers:

> How do we prove a behavior?

For example:

```text
@Test
void shouldReleaseInventoryWhenCancelOrder() {
    ...
}
```

Tests provide executable evidence for the Evaluation.

---

## Verification

Answers:

> Does the repository as a whole satisfy its engineering contract?

The canonical command is:

```bash
./scripts/verify.sh
```

Therefore:

```text
Evaluation
    ↓
defines correctness

Tests
    ↓
prove specific behavior

verify.sh
    ↓
proves the repository satisfies the verification contract
```

---

# 9. Evaluation Ownership

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
Review
  ↓
Re-run verification
```

Evaluation changes must represent an intentional change to the engineering contract.

---

# 10. Verification Architecture

Verification is part of the Harness control layer.

The repository uses:

```text
verify.sh
```

as the canonical verification entry point.

Individual verification scripts provide focused checks.

Typical structure:

```text
verify.sh
    │
    ├── verify-env.sh
    ├── verify-structure.sh
    ├── verify-infrastructure.sh
    ├── verify-backend.sh
    ├── verify-frontend.sh
    ├── verify-api.sh
    └── verify-architecture.sh
```

The exact composition may evolve as the project evolves.

---

# 11. Verification Script Ownership

Verification scripts are protected artifacts.

Examples:

```text
scripts/verify.sh
scripts/verify-env.sh
scripts/verify-structure.sh
scripts/verify-infrastructure.sh
scripts/verify-backend.sh
scripts/verify-frontend.sh
scripts/verify-api.sh
scripts/verify-architecture.sh
```

Normal product development must not modify these files merely to make a Task pass.

In particular:

* Backend must not weaken backend verification.
* Frontend must not weaken frontend verification.
* Test must not remove verification checks.
* Reviewer must not silently change verification behavior.
* Order System must not modify verification rules to avoid a failure.

---

# 12. When Verification Scripts May Be Changed

Verification scripts may be changed when there is a genuine change to the project's engineering contract.

Valid examples include:

### New engineering invariant

A new architectural rule needs deterministic enforcement.

Example:

```text
Controllers must not directly access repositories.
```

This may require an update to:

```text
scripts/verify-architecture.sh
```

---

### New repository capability

The project gains a new subsystem that requires verification.

For example:

```text
A new frontend application is introduced.
```

This may require:

```text
scripts/verify-frontend.sh
```

to evolve.

---

### Verification coverage is genuinely incomplete

A critical requirement is repeatedly being verified only through fragile manual inspection.

A deterministic verification rule may be appropriate.

---

### Project architecture changes

If the architecture intentionally changes, corresponding verification rules may need to change.

---

# 13. When Verification Scripts Must NOT Be Changed

Do not modify verification scripts because:

* a product implementation fails
* a test fails
* an Agent made a mistake
* the implementation is inconvenient
* the existing architecture makes implementation harder
* a Task is difficult to satisfy
* `verify.sh` reports a failure
* a new implementation does not match an existing engineering rule

The default response to verification failure is:

```text
Fix the implementation
```

not:

```text
Change the verification rule
```

---

# 14. Verification Change Workflow

When an Agent believes a verification rule needs to change:

```text
Agent
  ↓
Identify missing / outdated verification rule
  ↓
Explain why the current rule is incorrect or incomplete
  ↓
Human / authorized Harness maintainer approves
  ↓
Modify verify-*.sh
  ↓
Review the Harness change
  ↓
Run ./scripts/verify.sh
  ↓
PASS
```

Changing a verification script is itself an engineering change.

It must not be treated as a workaround for a failing product implementation.

---

# 15. `verify.sh` Is the Final Authority

The canonical command is:

```bash
./scripts/verify.sh
```

Focused tests may be executed during development.

However:

> A Task is not complete until the canonical verification passes.

The verification result is authoritative.

Do not declare completion when:

* tests pass but `verify.sh` fails
* Reviewer approves but `verify.sh` fails
* an Agent claims completion but verification was not executed

Expected final state:

```text
HARNESS VERIFY: PASS
```

---

# 16. Failure Handling

When verification fails:

1. Read the failure carefully.
2. Identify the failed verification.
3. Identify the affected requirement or Evaluation.
4. Determine whether the implementation is wrong.
5. Determine whether the test is wrong.
6. Determine whether documentation is stale.
7. Determine whether the verification rule itself is genuinely incorrect.
8. Fix the actual problem.
9. Re-run relevant tests.
10. Re-run `./scripts/verify.sh`.

The default assumption is:

> The implementation is wrong until evidence shows that the verification rule itself is wrong.

---

# 17. Documentation Rules

Documentation is part of the engineering system.

When implementation changes documented system behavior, relevant documentation must be updated.

## API changes

Update relevant documentation under:

```text
docs/api/
```

when API behavior changes.

---

## Database changes

Update relevant documentation under:

```text
docs/database/
```

when schema or important database behavior changes.

---

## Architecture changes

Update relevant documentation under:

```text
docs/architecture/
```

when system architecture changes.

---

## Architectural decisions

Important architectural decisions should be documented under:

```text
docs/decisions/
```

Use ADRs for decisions with meaningful long-term consequences.

Do not create ADRs for trivial implementation choices.

---

## Harness documentation

Harness methodology belongs under:

```text
.harness/docs/
```

Examples:

```text
.harness/docs/HARNESS-DEVELOPER-GUIDE.md
.harness/docs/HARNESS-QUICK-START.md
.harness/docs/HARNESS-EVALUATION-GUIDE.md
```

Normal product development should not modify these documents unless the Harness methodology itself changes.

---

# 18. Documentation Ownership

Recommended ownership:

| Area                    | Primary Owner              |
| ----------------------- | -------------------------- |
| `docs/api/`             | Backend / Engineering Team |
| `docs/database/`        | Backend / Engineering Team |
| `docs/architecture/`    | Engineering Team           |
| `docs/decisions/`       | Human / Tech Lead          |
| `.harness/docs/`        | Harness Maintainer / Team  |
| `.harness/evaluations/` | Human / Authorized Team    |
| `.harness/tasks/`       | Task Author / Team         |
| `scripts/verify-*.sh`   | Harness Maintainer / Team  |
| `scripts/verify.sh`     | Harness Maintainer / Team  |

Agents may update implementation-related documentation when required by their changes.

Agents should not silently change architectural decisions or Harness governance.

---

# 19. Engineering Principles

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

# 20. Backend Rules

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

## Code style (Checkstyle)

Backend Java code must satisfy the repository Checkstyle configuration
(`backend/checkstyle.xml`), which is enforced as part of `mvn verify` and the
canonical `./scripts/verify.sh`.

* Agents must not bypass Checkstyle (for example with `-Dcheckstyle.skip=true`,
  removing the check, or weakening rules) to make verification pass.
* If a Checkstyle rule conflicts with an explicit architecture or framework
  requirement, investigate the rule before changing production code.
* Checkstyle covers mechanical Java source style only. It is not a substitute
  for architecture verification, business-logic tests, API checks, or
  infrastructure checks.

---

# 21. Frontend Rules

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

Frontend should consume established API contracts rather than independently inventing request/response structures.

---

# 22. Testing Rules

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

# 23. Harness Protection Rules

The following are protected Harness artifacts:

```text
.harness/evaluations/
.harness/tasks/
.harness/config/
.harness/docs/
scripts/verify.sh
scripts/verify-*.sh
```

Protection means:

> These files must not be changed merely to make a product implementation pass.

A Harness artifact may be changed when the task explicitly concerns Harness behavior or when an approved engineering change requires it.

Harness changes must themselves be:

* reviewed
* tested where applicable
* verified

---

# 24. Definition of Done

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

# 25. Keep Harness Simple

This project intentionally does not use:

* baseline evaluation
* performance benchmarking
* token/cost scoring
* execution-time scoring
* unnecessary LLM judging

The primary goal is:

> reliable functional and engineering verification.

Prefer deterministic verification over subjective scoring.

Do not introduce additional scoring systems unless there is a clear engineering need.

---

# 26. Final Mental Model

The system can be understood as:

```text
                 REQUIREMENT
                      │
                      ↓
              ┌───────────────┐
              │     TASK      │
              │ What to build │
              └───────┬───────┘
                      ↓
              ┌───────────────┐
              │  EVALUATION   │
              │ What is right │
              └───────┬───────┘
                      ↓
              ┌───────────────┐
              │     AGENTS    │
              │ How to build  │
              └───────┬───────┘
                      ↓
              ┌───────────────┐
              │     TESTS     │
              │ Prove behavior│
              └───────┬───────┘
                      ↓
              ┌───────────────┐
              │  VERIFY.SH    │
              │ Final judge   │
              └───────┬───────┘
                      ↓
                 PASS / FAIL
```

Remember:

> **Task defines what needs to be done now.**

> **Evaluation defines what correct behavior means.**

> **Planner determines an evidence-based implementation approach.**

> **Backend / Frontend implement the change.**

> **Test provides executable evidence.**

> **Reviewer independently checks the implementation.**

> **verify.sh is the final authority.**

> **Verification scripts are part of the Harness and must not be weakened to make a Task pass.**

> **When verification fails, fix the product before changing the judge.**
