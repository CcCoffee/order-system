#!/usr/bin/env bash

set -euo pipefail

echo "======================================================"
echo " Order System - Harness Upgrade"
echo "======================================================"

ROOT="$(pwd)"

if [[ ! -f "$ROOT/AGENTS.md" ]]; then
  echo "ERROR: AGENTS.md not found."
  echo "Run this script from the order-system root directory."
  exit 1
fi

echo
echo "[1/8] Checking project structure..."

mkdir -p \
  backend \
  frontend \
  infra/docker \
  scripts \
  docs/architecture \
  docs/api \
  docs/database \
  .harness/evaluations \
  .harness/tasks \
  .harness/reports \
  .harness/state \
  .github/agents \
  .github/instructions \
  .vscode


# ============================================================
# 2. VS Code / Copilot configuration
# ============================================================

echo
echo "[2/8] Configuring VS Code / GitHub Copilot..."

cat > .vscode/settings.json <<'EOF'
{
  "chat.useAgentsMdFile": true,
  "chat.useNestedAgentsMdFiles": true,
  "github.copilot.chat.codeGeneration.useInstructionFiles": true
}
EOF


# ============================================================
# 3. Docker infrastructure
# ============================================================

echo
echo "[3/8] Configuring Docker infrastructure..."

cat > infra/docker/docker-compose.yml <<'EOF'
services:

  postgres:
    image: postgres:16-alpine
    container_name: order-system-postgres
    restart: unless-stopped
    ports:
      - "5433:5432"
    environment:
      POSTGRES_DB: order_system
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: "123456"
    volumes:
      - postgres-data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres -d order_system"]
      interval: 5s
      timeout: 3s
      retries: 10

  redis:
    image: redis:7-alpine
    container_name: order-system-redis
    restart: unless-stopped
    ports:
      - "6379:6379"
    volumes:
      - redis-data:/data
    command:
      - redis-server
      - --appendonly
      - "yes"
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 5s
      timeout: 3s
      retries: 10

volumes:
  postgres-data:
  redis-data:
EOF


cat > infra/docker/README.md <<'EOF'
# Local Infrastructure

The local development environment uses Docker Compose.

## PostgreSQL

```text
host: localhost
port: 5433
database: order_system
username: postgres
password: 123456
```

## Redis

```text
host: localhost
port: 6379
```

## Startup

Start the infrastructure:

```bash
./scripts/start-infra.sh
```

Stop the infrastructure:

```bash
./scripts/stop-infra.sh
```

Reset and recreate the infrastructure:

```bash
./scripts/reset-infra.sh
```
EOF


# ============================================================
# 4. GitHub Copilot instructions
# ============================================================

echo
echo "[4/8] Creating GitHub Copilot instructions..."

cat > .github/instructions/backend.instructions.md <<'EOF'
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
EOF

cat > .github/instructions/frontend.instructions.md <<'EOF'
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
EOF

cat > .github/instructions/testing.instructions.md <<'EOF'
---
applyTo: "**/*Test.java,**/*.test.ts,**/*.test.tsx,**/*.spec.ts,**/*.spec.tsx"
---

# Testing Rules

Tests are part of the Harness.

Never:

- delete tests to make verification pass
- weaken assertions to make verification pass
- skip failing tests without a documented environmental reason
- modify verification scripts to hide failures
- modify evaluation criteria to redefine success

When a defect is discovered:

1. reproduce it
2. add or update a regression test
3. fix the implementation
4. run verification again
EOF


# ============================================================
# 5. Custom Copilot Agent
# ============================================================

echo
echo "[5/8] Creating Copilot Agent..."

cat > .github/agents/order-system.agent.md <<'EOF'
---
name: Order System Engineer
description: Autonomous engineer for implementing and verifying the Order System according to the repository Harness.
tools:
  - read
  - search
  - edit
  - execute
---

# Order System Engineer

You are the primary implementation agent for this repository.

Your responsibility is to implement engineering tasks according to the repository's Harness.

## Mandatory reading order

Before changing code, read:

1. `/AGENTS.md`
2. `.github/copilot-instructions.md` if present
3. relevant `.github/instructions/*.instructions.md`
4. relevant `.harness/evaluations/*.md`
5. relevant `.harness/tasks/*.prompt.md`
6. existing source code
7. existing tests

Do not start implementation before understanding the evaluation criteria.

## Implementation loop

Use this loop:

1. Understand the task.
2. Inspect the repository.
3. Design the smallest coherent implementation.
4. Implement it.
5. Run `./scripts/verify.sh`.
6. Read every failure.
7. Identify the root cause.
8. Fix the implementation.
9. Run verification again.
10. Repeat until verification passes.

Do not stop after the first compilation error.

## Autonomous behavior

Do not routinely ask the human for decisions that can be reasonably inferred from:

- existing code
- architecture documentation
- evaluation criteria
- task description
- established conventions

Prefer making a coherent engineering decision and validating it through tests.

Ask the human only when a decision genuinely requires information unavailable from the repository.

## Harness protection

The following are evaluation contracts:

- `.harness/evaluations/`
- `.harness/tasks/`

Do not modify them to make an implementation pass.

Do not modify `scripts/verify.sh` or verification scripts merely to hide failures.

Do not delete tests to make verification pass.

## Definition of done

A task is not complete until:

```text
./scripts/verify.sh
```
returns exit code 0.

When verification fails, continue the failure → diagnosis → fix → verification loop.
EOF


# ============================================================
# 6. Harness Evaluation and Task
# ============================================================

echo
echo "[6/8] Creating Harness evaluation and task..."

cat > .harness/evaluations/001-order-system-mvp.md <<'EOF'

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
EOF

cat > .harness/tasks/001-order-system-mvp.prompt.md <<'EOF'

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
EOF


# ============================================================
# 7. Verification scripts
# ============================================================

echo
echo "[7/8] Creating verification scripts..."

cat > scripts/verify-structure.sh <<'EOF'
#!/usr/bin/env bash

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

echo "Checking repository structure..."

required_paths=(
"AGENTS.md"
".github"
".github/agents"
".github/instructions"
".harness"
".harness/evaluations"
".harness/tasks"
".harness/reports"
".harness/state"
"backend"
"frontend"
"infra/docker"
"docs"
"scripts"
)

for path in "${required_paths[@]}"; do
if [[ ! -e "$ROOT/$path" ]]; then
echo "FAIL: missing $path"
exit 1
fi
done

echo "PASS: repository structure"
EOF

cat > scripts/verify-infrastructure.sh <<'EOF'
#!/usr/bin/env bash

set -euo pipefail

echo "Checking infrastructure..."

if ! command -v docker >/dev/null 2>&1; then
echo "FAIL: Docker is not installed."
exit 1
fi

if ! docker info >/dev/null 2>&1; then
echo "FAIL: Docker daemon is not running."
exit 1
fi

check_container() {
local container="$1"

if ! docker inspect "$container" >/dev/null 2>&1; then
echo "FAIL: container $container does not exist."
echo "Run ./scripts/start-infra.sh first."
exit 1
fi

local status
status="$(docker inspect -f '{{.State.Health.Status}}' "$container")"

if [[ "$status" != "healthy" ]]; then
echo "FAIL: $container health status = $status"
exit 1
fi

echo "PASS: $container"
}

check_container "order-system-postgres"
check_container "order-system-redis"

echo "PASS: infrastructure"
EOF

cat > scripts/verify-backend.sh <<'EOF'
#!/usr/bin/env bash

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

if [[ ! -f "$ROOT/backend/pom.xml" ]]; then
echo "SKIP: backend/pom.xml does not exist yet."
exit 0
fi

cd "$ROOT/backend"

if [[ -x "./mvnw" ]]; then
MVN="./mvnw"
else
if ! command -v mvn >/dev/null 2>&1; then
echo "FAIL: Maven is not installed and backend/mvnw does not exist."
exit 1
fi

MVN="mvn"
fi

echo "Running backend tests..."

"$MVN" test
EOF

cat > scripts/verify-architecture.sh <<'EOF'
#!/usr/bin/env bash

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

if [[ ! -f "$ROOT/backend/pom.xml" ]]; then
echo "SKIP: backend/pom.xml does not exist yet."
exit 0
fi

cd "$ROOT/backend"

if [[ -x "./mvnw" ]]; then
MVN="./mvnw"
else
if ! command -v mvn >/dev/null 2>&1; then
echo "FAIL: Maven is not installed."
exit 1
fi

MVN="mvn"
fi

echo "Running architecture tests..."

"$MVN" test -Dgroups=architecture
EOF

cat > scripts/integration-test.sh <<'EOF'
#!/usr/bin/env bash

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

if [[ ! -f "$ROOT/backend/pom.xml" ]]; then
echo "SKIP: backend/pom.xml does not exist yet."
exit 0
fi

cd "$ROOT/backend"

if [[ -x "./mvnw" ]]; then
MVN="./mvnw"
else
if ! command -v mvn >/dev/null 2>&1; then
echo "FAIL: Maven is not installed."
exit 1
fi

MVN="mvn"
fi

echo "Running integration tests..."

"$MVN" test -Dgroups=integration
EOF

cat > scripts/verify-api.sh <<'EOF'
#!/usr/bin/env bash

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

OPENAPI="$ROOT/docs/api/openapi.yaml"

if [[ ! -f "$OPENAPI" ]]; then
echo "FAIL: $OPENAPI does not exist."
exit 1
fi

echo "OpenAPI specification exists."

if command -v npx >/dev/null 2>&1; then

if npx --yes @redocly/cli lint "$OPENAPI"; then
echo "PASS: OpenAPI lint"
exit 0
fi

echo "FAIL: OpenAPI lint failed."
exit 1
fi

echo "FAIL: npx is required for OpenAPI validation."
exit 1
EOF

cat > scripts/verify-frontend.sh <<'EOF'
#!/usr/bin/env bash

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

if [[ ! -f "$ROOT/frontend/package.json" ]]; then
echo "SKIP: frontend/package.json does not exist yet."
exit 0
fi

if ! command -v npm >/dev/null 2>&1; then
echo "FAIL: npm is not installed."
exit 1
fi

cd "$ROOT/frontend"

if [[ ! -d node_modules ]]; then
echo "FAIL: frontend dependencies are not installed."
echo "Run npm ci inside frontend/."
exit 1
fi

echo "Running frontend build..."

npm run build
EOF

cat > scripts/e2e.sh <<'EOF'
#!/usr/bin/env bash

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

if [[ ! -f "$ROOT/frontend/package.json" ]]; then
echo "SKIP: frontend/package.json does not exist yet."
exit 0
fi

cd "$ROOT/frontend"

if [[ ! -d node_modules ]]; then
echo "FAIL: frontend dependencies are not installed."
exit 1
fi

if ! npm list @playwright/test >/dev/null 2>&1; then
echo "FAIL: @playwright/test is not installed."
exit 1
fi

echo "Running Playwright E2E tests..."

npx playwright test
EOF

cat > scripts/verify.sh <<'EOF'
#!/usr/bin/env bash

set -uo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

FAILED=0

run_check() {
local name="$1"
local script="$2"

echo
echo "=================================================="
echo " CHECK: $name"
echo "=================================================="

if "$ROOT/scripts/$script"; then
echo "RESULT: PASS"
else
echo "RESULT: FAIL"
FAILED=1
fi
}

run_check "Repository Structure" "verify-structure.sh"
run_check "Infrastructure" "verify-infrastructure.sh"
run_check "Backend" "verify-backend.sh"
run_check "Architecture" "verify-architecture.sh"
run_check "API Contract" "verify-api.sh"
run_check "Integration Tests" "integration-test.sh"
run_check "Frontend" "verify-frontend.sh"
run_check "E2E" "e2e.sh"

echo

if [[ "$FAILED" -eq 0 ]]; then
echo "=================================================="
echo " HARNESS VERIFICATION: PASS"
echo "=================================================="
exit 0
fi

echo "=================================================="
echo " HARNESS VERIFICATION: FAIL"
echo "=================================================="

exit 1
EOF

chmod +x "$ROOT/scripts/"*.sh


# ============================================================
# 8. Harness governance and report template
# ============================================================

echo
echo "[8/8] Creating Harness governance and report template..."

if ! grep -q "Harness Engineering Governance" "$ROOT/AGENTS.md"; then

cat >> AGENTS.md <<'EOF'

# Harness Engineering Governance
This repository uses a repository-native Harness to evaluate AI-assisted software development.

## Canonical verification
The canonical verification command is:

./scripts/verify.sh

An implementation task is complete only when this command returns exit code 0.

## Evaluation ownership
The following directories contain evaluation contracts:

- .harness/evaluations/
- .harness/tasks/
During normal implementation these files are read-only.

Agents must not modify evaluation criteria merely to make an implementation pass.

## Verification ownership
Verification scripts are executable engineering contracts.

Agents must not:

- disable verification
- remove verification steps
- weaken assertions
- hide failures
- change verification behavior merely to make a task pass
- delete tests to avoid failures

## Failure recovery
When verification fails:

1. read the failure
2. identify the root cause
3. fix the implementation
4. run verification again
5. repeat until passing
Do not bypass a failing verification step.

## Engineering principle
Tests and verification are feedback mechanisms, not obstacles.

The preferred development loop is:

Read
↓
Understand
↓
Implement
↓
Verify
↓
Diagnose
↓
Fix
↓
Verify again

## Definition of done
A task is complete only when the implementation satisfies the evaluation criteria and the canonical verification command passes.
EOF

else
echo "Harness governance already exists in AGENTS.md; leaving it unchanged."
fi

cat > .harness/reports/001-order-system-mvp.md <<'EOF'

# Harness Evaluation Report

## Evaluation
001-order-system-mvp

## Result

- PASS
- FAIL
- BLOCKED

## Verification
Command:

```
./scripts/verify.sh
```
Attempts:

- 
Failures:

- 

## Human Intervention
Number of human interventions:

- 
Reason for intervention:

- 

## Implementation
Backend:

- 
Frontend:

- 
Database:

- 
Redis:

- 
API:

- 

## Tests
Unit tests:

- 
Integration tests:

- 
API tests:

- 
E2E tests:

- 

## Architecture
Architecture verification:

- 
Violations:

- 

## Self Repair
Number of verification/fix iterations:

- 
Problems autonomously detected:

- 
Problems autonomously fixed:

- 

## Harness Weaknesses
Issues discovered in the evaluation itself:

- 
Missing verification:

- 
False positives:

- 
False negatives:

- 

## Final Assessment

- Functional correctness:
- Architecture compliance:
- Test coverage:
- Autonomous recovery:
- Human intervention:
EOF

echo
echo "======================================================"
echo " Harness completion finished."
echo "======================================================"

echo
echo "Created / updated:"
echo
echo " .github/instructions/backend.instructions.md"
echo " .github/instructions/frontend.instructions.md"
echo " .github/instructions/testing.instructions.md"
echo " .github/agents/order-system.agent.md"
echo " .harness/evaluations/001-order-system-mvp.md"
echo " .harness/tasks/001-order-system-mvp.prompt.md"
echo " .harness/reports/001-order-system-mvp.md"
echo " scripts/verify-structure.sh"
echo " scripts/verify-infrastructure.sh"
echo " scripts/verify-backend.sh"
echo " scripts/verify-architecture.sh"
echo " scripts/integration-test.sh"
echo " scripts/verify-api.sh"
echo " scripts/verify-frontend.sh"
echo " scripts/e2e.sh"
echo " scripts/verify.sh"
echo
echo "Next:"
echo
echo " 1. Start infrastructure:"
echo " ./scripts/start-infra.sh"
echo
echo " 2. Verify infrastructure:"
echo " ./scripts/verify-infrastructure.sh"
echo
echo " 3. Open the project in VS Code."
echo
echo " 4. Select the 'Order System Engineer' custom agent."
echo
echo " 5. Give it:"
echo " .harness/tasks/001-order-system-mvp.prompt.md"
echo
echo " 6. Let the Agent implement and self-repair."
echo
echo "======================================================"