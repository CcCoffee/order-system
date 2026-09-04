---
name: Backend Standards
description: Apply enterprise Spring Boot standards to backend code.
applyTo: "backend/**/*.java"
---

# Spring Boot Standards

- Keep controllers thin.
- Put business logic in application/domain services.
- Do not access repositories directly from controllers.
- Use explicit DTOs.
- Validate request boundaries.
- Use the existing exception handling mechanism.
- Do not introduce new frameworks without justification.
- Add tests for behavior changes.
