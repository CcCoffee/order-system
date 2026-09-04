# Engineering Harness

## Purpose

This repository is an AI-assisted enterprise software project.

Agents must treat this file as the top-level engineering contract.

---

# 1. Before Changing Code

Before modifying any code:

1. Read this file.
2. Locate and read the nearest applicable AGENTS.md.
3. Read relevant architecture documentation.
4. Search the repository for existing implementations.
5. Reuse existing abstractions before creating new ones.
6. Identify affected tests.
7. Identify API/database compatibility requirements.

Do not start coding immediately after reading only the user request.

---

# 2. Architecture Principles

Prefer:

API
 ↓
Application
 ↓
Domain
 ↓
Infrastructure

Do not bypass architectural layers without a documented reason.

Avoid:

- duplicate abstractions
- unnecessary frameworks
- speculative refactoring
- unrelated cleanup
- breaking API changes without explicit approval

---

# 3. API Contract

OpenAPI is the source of truth for public REST APIs.

When an API changes:

1. Update OpenAPI.
2. Update backend.
3. Update frontend client/types.
4. Update integration tests.
5. Verify compatibility.

Agents must not independently invent API contracts.

---

# 4. Database

PostgreSQL is the source of truth for persistent business data.

All schema changes require migrations.

Never:

- modify production schema manually
- delete production data
- bypass migration tooling
- introduce destructive changes without explicit approval

---

# 5. Testing

Use the smallest appropriate verification level:

Unit
 ↓
Integration
 ↓
API Contract
 ↓
E2E

User-visible behavior should have E2E coverage where practical.

---

# 6. Verification

Before declaring a task complete:

    ./scripts/verify.sh

A successful compilation is NOT sufficient evidence.

The final response must report:

- implementation summary
- files changed
- tests executed
- verification result
- known risks

---

# 7. Definition of Done

A task is complete only when:

- requirement implemented
- architecture respected
- tests updated
- relevant tests pass
- API contract valid
- database migration valid
- frontend builds
- E2E passes where applicable
- no unrelated changes introduced
- full verification passes

---

# 8. Agent Behavior

Agents should:

- inspect before editing
- make minimal changes
- reuse existing patterns
- preserve compatibility
- verify their changes
- fix failures instead of bypassing them

Agents must NOT:

- disable tests
- weaken validation merely to make tests pass
- remove failing assertions without justification
- silently change requirements
- make unrelated refactors

---

# 9. Evidence

Do not say:

"Implemented successfully."

Instead provide evidence:

Command:
    ./scripts/verify.sh

Result:
    PASS

Tests:
    128 passed

E2E:
    14 passed

The repository state and verification output are the source of truth.
