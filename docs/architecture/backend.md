# Backend Architecture

Spring Boot services follow:

API
 ↓
Application
 ↓
Domain
 ↓
Infrastructure

API layer:

- REST controllers
- request/response DTOs
- validation

Application layer:

- use cases
- transactions
- orchestration

Domain:

- business rules
- domain objects
- state transitions

Infrastructure:

- PostgreSQL
- Redis
- external services
