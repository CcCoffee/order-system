---
applyTo: "frontend/**/*.{ts,tsx}"
---

# Frontend Engineering Rules

## Architecture

Keep responsibilities separated:

UI Component
    ↓
Application/UI State
    ↓
API Client
    ↓
Backend API

Rules:

- Components should not contain large amounts of business logic.
- API calls belong in dedicated API/service modules.
- Do not access backend databases directly.
- Do not duplicate backend business rules as the source of truth.
- Keep API contracts typed.
- Handle loading, success and error states explicitly.

## User Experience

Important operations must provide:

- loading feedback
- success feedback where appropriate
- meaningful error feedback
- disabled states while requests are in progress

Do not silently ignore API failures.

## Testing

Critical user journeys must have automated tests.

At minimum:

- order creation
- order detail
- order cancellation
- invalid cancellation
