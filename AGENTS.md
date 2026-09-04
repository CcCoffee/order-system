# Order System - Engineering Harness

## Project

This is an enterprise order management system.

Technology stack:

- Backend: Java + Spring Boot
- Frontend: React + TypeScript
- Database: PostgreSQL
- Cache: Redis
- API: REST + OpenAPI
- Browser testing: Playwright
- Build: Gradle / npm
- CI: GitHub Actions

---

# Core Engineering Principles

## 1. Read before changing

Before modifying code:

1. Read this file.
2. Read the relevant directory-level AGENTS.md.
3. Read relevant architecture documentation.
4. Search the repository for existing implementations.
5. Reuse existing abstractions before creating new ones.

Do not create duplicate utilities, services, DTOs, API clients, or infrastructure abstractions.

---

# Architecture

The backend follows:

Controller
    ↓
Application Service
    ↓
Domain
    ↓
Infrastructure

Controllers must not directly access repositories.

Frontend follows:

Page
    ↓
Feature
    ↓
API Client
    ↓
Backend API

API contracts are defined by OpenAPI.

---

# Backend Rules

1. Use Spring Boot conventions.
2. Controllers must remain thin.
3. Business logic belongs in application/domain services.
4. Repository access must not happen inside controllers.
5. Database changes require Flyway migration.
6. Never modify production database manually.
7. API changes must update OpenAPI.
8. Public APIs require tests.
9. Do not introduce new frameworks without justification.
10. Preserve backward compatibility unless the requirement explicitly allows breaking changes.

---

# Frontend Rules

1. Use TypeScript strict mode.
2. Do not introduce `any` unless explicitly justified.
3. API DTOs must follow the OpenAPI contract.
4. Do not manually duplicate backend API models when generated types are available.
5. Reuse existing components.
6. Core user flows require Playwright coverage.
7. Do not introduce a new UI framework without approval.

---

# Database Rules

All schema changes must be represented as migrations.

Never:

- modify production schema manually
- delete production data
- introduce destructive migrations without explicit approval

---

# Testing Rules

Every feature should have the smallest appropriate test set:

- Unit test
- Integration test
- API contract test
- E2E test when user-visible

---

# Verification

Before considering a task complete:

    ./scripts/verify.sh

A task is NOT complete merely because the code compiles.

The agent must provide evidence that verification passed.

---

# Definition of Done

A task is complete only when:

1. Requirement is implemented.
2. Existing behavior is preserved.
3. Relevant tests pass.
4. API contract is valid.
5. Frontend builds.
6. Integration tests pass.
7. E2E tests pass when applicable.
8. Documentation is updated when architecture/API behavior changes.
9. No unnecessary dependencies are introduced.
10. `./scripts/verify.sh` passes.

---

# Agent Behavior

Agents should:

- inspect before editing
- make the smallest reasonable change
- reuse existing patterns
- avoid speculative refactoring
- avoid unrelated changes
- run targeted tests first
- run full verification before completion

When verification fails:

1. inspect the failure
2. identify the root cause
3. fix the implementation
4. rerun the failed check
5. continue until verification passes or a blocking issue is documented

Do not hide or bypass failing tests.

