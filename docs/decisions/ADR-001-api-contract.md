# ADR-001: OpenAPI as API Contract

## Decision

OpenAPI is the source of truth for public REST API contracts.

## Consequences

Backend and frontend changes must remain synchronized.

API changes require:

1. OpenAPI update
2. backend implementation
3. frontend update
4. tests
