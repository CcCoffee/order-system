
# Evaluation 001 — Order System MVP

## Objective
Build a small but production-style order management system.

The implementation must demonstrate that an AI coding agent can independently implement a cross-layer feature while respecting repository architecture, tests and executable verification.

---

# 1. Technology

## Backend

- Java
- Spring Boot
- Maven
- PostgreSQL
- Redis

## Frontend

- React
- TypeScript

## Testing

- JUnit
- Spring Boot Test
- Testcontainers where appropriate
- Playwright for E2E

---

# 2. Domain
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

---

# 3. Order Creation
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
If any required operation fails, the order creation must not leave partially committed business state.

---

# 4. Order Query
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

---

# 5. Order Cancellation
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

---

# 6. Redis
Redis must have meaningful application usage.

Acceptable examples include:

- idempotency
- short-lived caching
- distributed coordination
- request deduplication
The implementation must document why Redis is used.

Redis must not exist merely because the evaluation mentions Redis.

---

# 7. Frontend
The frontend must provide:

- order creation
- order detail
- order status display
- order cancellation
- loading states
- error states
The cancel action must only be available when cancellation is valid.

The frontend must not become the source of truth for backend business rules.

---

# 8. Architecture
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

---

# 9. Testing
Required:

## Unit tests
At minimum:

- order status transition rules
- cancellation rules
- inventory rules

## Integration tests
At minimum:

- order creation
- inventory reservation
- order cancellation
- inventory release
- transaction rollback

## API tests
At minimum:

- create order
- query order
- cancel order
- invalid cancellation

## E2E
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

---

# 10. API Contract
Create:

```
docs/api/openapi.yaml
```
The OpenAPI document must describe the implemented order APIs.

---

# 11. Completion Criteria
The task is complete only when:

```
./scripts/verify.sh
```
returns:

```
exit code 0
```

---

# 12. Forbidden shortcuts
The agent must not:

- delete tests
- weaken tests
- disable architecture checks
- remove verification
- modify evaluation criteria
- modify task criteria
- hide failing commands
- hard-code test-specific behavior
- bypass transaction requirements
Infrastructure or environment problems may be reported, but implementation problems must be fixed by the agent.
