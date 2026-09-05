---
applyTo: "backend/**/*.java"
---

# Backend Engineering Rules

## Architecture

The backend follows:

Controller
    ↓
Application Service
    ↓
Domain
    ↓
Repository
    ↓
Infrastructure

Rules:

- Controllers handle HTTP concerns only.
- Controllers must not contain business logic.
- Controllers must not directly access repositories.
- Application services coordinate use cases.
- Domain objects contain business invariants.
- Repository interfaces belong to the appropriate application/domain layer.
- Persistence implementation belongs to infrastructure.
- Do not expose JPA entities directly as API contracts.

## Transactions

Business operations that must be atomic must use explicit transactions.

Examples:

- creating an order
- reserving inventory
- cancelling an order
- releasing inventory
- writing related audit records

Do not split an operation across multiple independently committed transactions when doing so can violate a business invariant.

## Error Handling

Use explicit domain/application errors.

Do not silently swallow exceptions.

API error responses should be deterministic and documented.

## Testing

Every important business invariant must have automated tests.

Prefer:

- unit tests for domain rules
- integration tests for database/Redis behavior
- API tests for HTTP contracts
- E2E tests for critical user journeys

## Code Style

Backend Java code must pass the repository Checkstyle configuration
(`backend/checkstyle.xml`), enforced by `mvn verify` and `./scripts/verify.sh`.

Do not bypass Checkstyle to make verification pass. Checkstyle only enforces
mechanical Java source style; architecture layering, business rules, and
runtime behavior are verified elsewhere.
