# Evaluation 001 — Order System MVP

## Objective

Build a small but production-style order management system.

The implementation must demonstrate that an AI coding agent can independently
implement a cross-layer feature while respecting repository architecture, tests
and executable verification.

## Scenario

The system must support product lookup, inventory lookup, order creation, order
query, order cancellation, Redis-based caching/idempotency, a React frontend, and
a documented API contract.

## Acceptance Criteria

### AC-1 Products and inventory are available
The system exposes product and inventory lookup backed by the database.

### AC-2 Order creation validates the request and reserves inventory atomically
`POST /api/orders` validates the requested products and inventory availability,
reserves inventory, creates the order and order items, and commits the operation
atomically.

### AC-3 Failed order creation leaves no partial state
If any required step of order creation fails, the operation must not leave
partially committed business state.

### AC-4 Order query returns required details
`GET /api/orders/{id}` returns the order id, status, items, quantities, prices,
total amount, and timestamps.

### AC-5 Cancellation is allowed only for PENDING and is atomic
`POST /api/orders/{id}/cancel` validates the current state, transitions to
`CANCELLED`, releases reserved inventory, and writes an audit record atomically.

### AC-6 Invalid cancellations are rejected
Cancellation must fail for `PAID`, `SHIPPED`, and `CANCELLED` orders.

### AC-7 Redis has meaningful application usage
Redis is used for idempotency, short-lived caching, or request deduplication, and
the reason is documented. Redis must not exist merely because the evaluation
mentions Redis.

### AC-8 Frontend supports the order flow with loading/error states
The frontend provides order creation, order detail, order status display, and
cancellation, with loading and error states. The cancel action is only available
when cancellation is valid, and the frontend must not become the source of truth
for backend business rules.

### AC-9 Backend layering is enforced
Backend follows `Controller -> Application Service -> Domain -> Repository`.
Controllers must not contain business logic or access repositories directly,
domain rules must not be implemented only in controllers, and persistence details
must not leak into API contracts.

### AC-10 API contract is documented
`docs/api/openapi.yaml` describes the implemented order APIs.

## Required Evidence

Every acceptance criterion MUST have corresponding evidence.

| Criterion | Required Evidence |
|---|---|
| AC-1 | Repository/API test verifying product and inventory lookup |
| AC-2 | Integration test verifying order creation reserves inventory and creates order+items atomically |
| AC-3 | Integration test verifying rollback leaves no partial state |
| AC-4 | API test verifying order detail response fields |
| AC-5 | Integration/API test verifying cancel transitions, releases inventory, writes audit log |
| AC-6 | API test verifying invalid cancel transitions are rejected |
| AC-7 | Integration test + documentation explaining Redis usage |
| AC-8 | Frontend unit/E2E test verifying order flow states |
| AC-9 | Architecture test enforcing layering rules |
| AC-10 | OpenAPI document present and consistent with the API |

## Required Tests

At minimum:

1. Unit tests for order status transition rules, cancellation rules, and inventory rules.
2. Integration tests for order creation, inventory reservation, cancellation, inventory release, and transaction rollback.
3. API tests for create order, query order, cancel order, and invalid cancellation.
4. E2E test: create order -> view order -> cancel order -> verify CANCELLED.

## Architecture Constraints

Backend layering:

```
Controller
    ↓
Application Service
    ↓
Domain
    ↓
Repository
```

- Controllers must not contain business logic.
- Controllers must not directly access repositories.
- Domain rules must not be implemented only in controllers.
- Persistence details must not leak into API contracts.

Frontend rules:

- API access must be separated from presentation.
- Backend business rules must remain authoritative on the backend.

## Regression Requirements

Existing order, inventory, cancellation, and audit behavior must remain intact
after any change.

## Verification

The repository must pass:

```
./scripts/verify.sh
```

Repository verification does not substitute for missing Evaluation evidence.

## Forbidden Shortcuts

- Weakening tests
- Deleting tests
- Skipping failures
- Replacing required integration tests with mocks
- Modifying Evaluation criteria to reduce requirements
- Modifying verification scripts to hide failures
- Hard-coding test-specific production behavior

---

# Technical Design

The following sections describe the technical design that the implementation is
expected to follow.

## Technology

### Backend

- Java
- Spring Boot
- Maven
- PostgreSQL
- Redis

### Frontend

- React
- TypeScript

### Testing

- JUnit
- Spring Boot Test
- Testcontainers where appropriate
- Playwright for E2E

## Domain
The system contains:

- Product
- Inventory
- Order
- OrderItem
- AuditLog

Order status:

```
PENDING
CANCELLED
PAID
SHIPPED
```

Valid transitions:

```
PENDING -> CANCELLED
PENDING -> PAID
PAID    -> SHIPPED
```

Invalid transitions include:

```
PAID    -> CANCELLED
SHIPPED -> CANCELLED
```

## Order Creation
API:

```
POST /api/orders
```

The operation must:

1. validate the requested products
2. validate inventory availability
3. reserve inventory
4. create the order
5. create order items
6. commit the operation atomically

If any required operation fails, the order creation must not leave partially
committed business state.

## Order Query
API:

```
GET /api/orders/{id}
```

The API must return sufficient information to display:

- order id
- status
- items
- quantities
- prices
- total amount
- timestamps

## Order Cancellation
API:

```
POST /api/orders/{id}/cancel
```

Cancellation is allowed only when:

```
status == PENDING
```

Cancellation must:

1. validate the current order state
2. change the order state to CANCELLED
3. release reserved inventory
4. create an audit record

These operations must be atomic.

Cancellation must fail for:

```
PAID
SHIPPED
CANCELLED
```

## Redis
Redis must have meaningful application usage.

Acceptable examples include:

- idempotency
- short-lived caching
- distributed coordination
- request deduplication

The implementation must document why Redis is used.

Redis must not exist merely because the evaluation mentions Redis.

## Frontend
The frontend must provide:

- order creation
- order detail
- order status display
- order cancellation
- loading states
- error states

The cancel action must only be available when cancellation is valid.

The frontend must not become the source of truth for backend business rules.

## Architecture
Backend layering:

```
Controller
    ↓
Application Service
    ↓
Domain
    ↓
Repository
```

Rules:

- Controller must not contain business logic.
- Controller must not directly access repositories.
- Domain rules must not be implemented only in controllers.
- Persistence details must not leak into API contracts.

Frontend rules:

- API access must be separated from presentation.
- Backend business rules must remain authoritative on the backend.

## Testing
Required:

### Unit tests
At minimum:

- order status transition rules
- cancellation rules
- inventory rules

### Integration tests
At minimum:

- order creation
- inventory reservation
- order cancellation
- inventory release
- transaction rollback

### API tests
At minimum:

- create order
- query order
- cancel order
- invalid cancellation

### E2E
At minimum:

```
Create order
    ↓
View order
    ↓
Cancel order
    ↓
Verify CANCELLED
```

## API Contract
Create:

```
docs/api/openapi.yaml
```

The OpenAPI document must describe the implemented order APIs.

## Completion Criteria
The task is complete only when:

```
./scripts/verify.sh
```

returns:

```
exit code 0
```
