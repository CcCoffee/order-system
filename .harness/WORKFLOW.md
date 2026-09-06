# Harness Multi-Agent Workflow

## Purpose

This document defines how GitHub Copilot Custom Agents collaborate in
the Order System.

The goal is not to maximize the number of agents.

The goal is to create a reliable engineering feedback loop:

Requirement
→ Planning
→ Implementation
→ Testing
→ Review
→ Verification
→ Repair
→ Verification

---

# 1. Agent Roles

## Order System

Role:

Orchestrator.

Responsibilities:

- understand request
- select Evaluation and Task
- invoke Planner
- invoke implementation agents
- invoke Test
- invoke Reviewer
- run Harness verification
- coordinate repairs

This is the primary entry point for normal development work.

---

## Planner

Role:

Analysis.

Responsibilities:

- inspect repository
- understand existing architecture
- analyze requirements
- identify affected components
- create implementation plan
- persist the final plan under `.harness/plans/`
- define acceptance criteria
- define verification strategy

Must not modify production code.

---

## Backend

Role:

Backend implementation.

Responsibilities:

- Spring Boot implementation
- business logic
- persistence
- transactions
- backend API
- backend tests

Must remain within backend scope.

---

## Frontend

Role:

Frontend implementation.

Responsibilities:

- React implementation
- API integration
- UI state
- frontend tests

Must remain within frontend scope.

---

## Test

Role:

Testing and verification.

Responsibilities:

- inspect implementation
- identify missing coverage
- add tests
- execute tests
- validate Evaluation criteria
- report failures

Must not modify production code merely to make tests pass.

---

## Reviewer

Role:

Independent review.

Responsibilities:

- inspect implementation
- inspect tests
- check architecture
- check business correctness
- identify transaction/concurrency/idempotency risks
- identify regression risks

Must not modify code.

---

# 2. Agent Hierarchy

The intended hierarchy is:

User
  ↓
Order System
  ↓
Planner
  ↓
.harness/plans/<evaluation-id>-<task-slug>.plan.md
  ↓
Backend / Frontend
  ↓
Test
  ↓
Reviewer
  ↓
verify.sh

The Order System agent is the orchestration root.

Specialized agents should not create their own uncontrolled agent trees.

---

# 3. Task Flow

## Step 1

User starts the Order System agent.

## Step 2

Order System identifies:

- Evaluation
- Task
- affected domains

## Step 3

Planner analyzes the repository and persists the implementation plan to:

```text
.harness/plans/<evaluation-id>-<task-slug>.plan.md
```

## Step 4

Order System confirms the persisted plan artifact exists and delegates
implementation, passing the plan path as the formal input.

## Step 5

Test validates implementation.

## Step 6

Reviewer independently reviews implementation.

## Step 7

Order System runs:

./scripts/verify.sh

## Step 8

If verification fails:

identify responsible component
→ delegate repair
→ run verification again

## Step 9

Only PASS means complete.

---

# 4. Verification Authority

The authoritative verification command is:

./scripts/verify.sh

Individual agents may run focused tests during development.

However:

Focused test PASS
does not mean
Harness PASS.

The full verification must pass before completion.

---

# 5. Harness Protection

Agents must not modify the following merely to make a task pass:

- .harness/evaluations/
- .harness/tasks/
- .harness/plans/
- scripts/verify.sh
- verification criteria

Only the Planner may revise a plan under `.harness/plans/`, and it must do so
in place (Git tracks history). Implementation agents report conflicts rather
than rewriting the plan.

Tests must not be weakened.

Tests must not be deleted to hide failures.

Failures must be repaired in implementation or reported as genuine
Harness gaps.

---

# 6. Scope Boundaries

Backend Agent:

May modify backend and backend tests.

Frontend Agent:

May modify frontend and frontend tests.

Test Agent:

May modify tests.

Planner:

Read-only.

Reviewer:

Read-only.

Order System:

Coordinates work and may make small orchestration-level changes,
but should delegate specialized implementation whenever practical.

---

# 7. Definition of Done

A task is complete only when:

1. Required implementation is present.
2. Required tests exist.
3. Review has completed.
4. Full Harness verification passes.

Command:

./scripts/verify.sh

Expected result:

HARNESS VERIFY: PASS

---

# 8. Design Philosophy

Keep the Harness simple.

Do not add:

- baseline systems
- performance scoring
- token/cost scoring
- benchmark infrastructure
- unnecessary dashboards
- unnecessary orchestration layers

The core feedback loop is enough:

Task
→ Agent
→ Code
→ Verification
→ FAIL
→ Repair
→ Verification
→ PASS
