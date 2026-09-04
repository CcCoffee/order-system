
# Task — Implement Order System MVP
You are responsible for implementing the Order System MVP.

Do not ask the human to manually implement routine code.

## Step 1 — Understand the repository
Read:

```
AGENTS.md
.github/
.harness/evaluations/001-order-system-mvp.md
.harness/tasks/001-order-system-mvp.prompt.md
```
Inspect the existing repository before making changes.

Do not assume the repository is empty if implementation already exists.

## Step 2 — Start infrastructure
Ensure the local infrastructure is available.

Use:

```
./scripts/start-infra.sh
```
Verify:

```
./scripts/verify-infrastructure.sh
```

## Step 3 — Implement backend
Create a coherent Spring Boot Maven backend.

Implement:

- Product
- Inventory
- Order
- OrderItem
- AuditLog
Implement:

- order creation
- order query
- order cancellation
- order state transitions
- inventory reservation
- inventory release
- transactional consistency
Use PostgreSQL for persistence.

Use Redis for a meaningful application concern.

## Step 4 — Implement frontend
Create a React + TypeScript frontend.

Implement:

- order creation
- order detail
- order status
- order cancellation
- loading states
- error states

## Step 5 — Implement tests
Add:

- unit tests
- integration tests
- API tests
- E2E tests
Do not postpone testing until the very end.

## Step 6 — Implement API documentation
Create:

```
docs/api/openapi.yaml
```
Keep it consistent with the implemented APIs.

## Step 7 — Verification
Run:

```
./scripts/verify.sh
```
If it fails:

1. read the failure
2. determine the root cause
3. fix the implementation
4. run verification again
Repeat until all checks pass.

## Step 8 — Final review
Before declaring completion, verify:

- business rules are implemented in the correct layer
- transactions protect atomic operations
- invalid order transitions are rejected
- inventory cannot become inconsistent
- Redis has meaningful usage
- tests cover important invariants
- API documentation matches implementation
- frontend handles errors
- architecture rules are respected
Do not modify Harness evaluation criteria to make the task pass.
