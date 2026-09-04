# Backend Engineering Rules

## Architecture

Spring Boot backend uses:

Controller
    ↓
Application Service
    ↓
Domain
    ↓
Infrastructure

## Package Structure

Prefer:

com.company.orders
├── api
├── application
├── domain
├── infrastructure
└── configuration

## Rules

- Controllers handle HTTP concerns only.
- Application services coordinate use cases.
- Domain contains business rules.
- Infrastructure contains database/external integrations.
- Repository interfaces belong to the appropriate abstraction layer.
- Avoid leaking persistence entities into API responses.
- Use explicit DTOs.
- Validate input at API boundaries.
- Use global exception handling.
- Use transactions at application-service boundaries.

## Database

PostgreSQL is the source of truth.

Every schema modification requires a Flyway migration.

## Redis

Redis is used only for caching and short-lived state.

Cache invalidation must be explicit when mutable domain state changes.

## Testing

Service/domain logic should have unit tests.

Database behavior requires integration tests.

Public APIs require API/integration tests.

