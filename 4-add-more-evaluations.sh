#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT"

echo "=============================================="
echo "Phase 2 Harness Setup"
echo "=============================================="

mkdir -p \
  .harness/evaluations \
  .harness/tasks \
  .harness/reports/baseline \
  .harness/config \
  scripts

echo
echo "[1/10] Creating .env.example"

cat > .env.example <<'EOF'
# PostgreSQL
DATABASE_URL=jdbc:postgresql://localhost:5434/order_system
DATABASE_USERNAME=postgres
DATABASE_PASSWORD=123456

# Redis
REDIS_HOST=localhost
REDIS_PORT=6380
EOF


echo
echo "[2/10] Creating Harness evaluation configuration"

cat > .harness/config/evaluations.yaml <<'EOF'
version: 1

project:
  name: order-system
  language: java
  framework: spring-boot
  frontend: react-typescript

verification:
  command: ./scripts/verify.sh
  success_exit_code: 0

evaluations:

  - id: 001
    name: order-system-mvp
    category: functional
    difficulty: medium
    status: baseline

  - id: 002
    name: order-cancellation
    category: business-rule
    difficulty: medium
    status: active

  - id: 003
    name: inventory-concurrency
    category: concurrency
    difficulty: hard
    status: active

  - id: 004
    name: order-idempotency
    category: reliability
    difficulty: hard
    status: active

  - id: 005
    name: regression
    category: regression
    difficulty: hard
    status: active

metrics:
  - task_success
  - human_intervention
  - verification_attempts
  - self_repair_iterations
  - architecture_violations
  - regression_failures
  - duration_seconds
EOF


echo
echo "[3/10] Creating Evaluation 002: Order Cancellation"

cat > .harness/evaluations/002-order-cancellation.md <<'EOF'
# Evaluation 002 — Order Cancellation

## Objective

Verify that the agent correctly implements and preserves the order cancellation
business flow.

## Preconditions

An order exists in `PENDING` state.

The order contains one or more items whose inventory has already been reserved.

## Required behavior

Calling:

POST `/api/orders/{id}/cancel`

must:

1. Verify that the order exists.
2. Verify that the current status is `PENDING`.
3. Change status to `CANCELLED`.
4. Release all previously reserved inventory.
5. Create an audit log.
6. Execute the operation transactionally.

## Invalid transitions

The following must be rejected:

- `PAID -> CANCELLED`
- `SHIPPED -> CANCELLED`
- `CANCELLED -> CANCELLED`

## Idempotency of cancellation

Repeated cancellation requests must not:

- release inventory multiple times
- create duplicate business effects
- corrupt order state

The API should return a deterministic response for repeated cancellation attempts.

## Required tests

At minimum:

- successful cancellation
- cancellation of nonexistent order
- cancellation of PAID order
- cancellation of SHIPPED order
- inventory released exactly once
- audit log created
- repeated cancellation does not double-release inventory

## Architecture constraints

Business rules must remain outside controllers.

Controllers must not access repositories directly.

## Verification

The evaluation passes only when:

`./scripts/verify.sh`

returns exit code `0`.
EOF


echo
echo "[4/10] Creating Evaluation 003: Inventory Concurrency"

cat > .harness/evaluations/003-inventory-concurrency.md <<'EOF'
# Evaluation 003 — Inventory Concurrency

## Objective

Verify that the order system behaves correctly when multiple requests attempt
to reserve the same inventory concurrently.

## Scenario

Assume:

- Product A has inventory quantity = 10.
- Multiple concurrent order requests attempt to purchase Product A.
- The total requested quantity is greater than 10.

## Required behavior

The system must guarantee:

1. Inventory can never become negative.
2. Successful orders never exceed available inventory.
3. Failed orders do not leave partially reserved inventory.
4. Database state remains consistent.
5. Concurrent requests do not bypass inventory validation.

## Example

Initial inventory:

10

Ten concurrent requests each buying:

1

Expected successful reservations:

10

Expected remaining inventory:

0

An additional request must fail.

## Stronger scenario

Run concurrent requests where:

- request A buys 6
- request B buys 6

Only one request may successfully reserve all 6 units.

The other request must fail.

## Required tests

Use integration tests with real PostgreSQL.

The test must exercise actual transaction/concurrency behavior rather than
only testing mocked services.

## Architecture constraints

Concurrency control must belong to the persistence/application boundary,
not the HTTP controller.

## Verification

The evaluation passes only when:

`./scripts/verify.sh`

returns exit code `0`.
EOF


echo
echo "[5/10] Creating Evaluation 004: Order Idempotency"

cat > .harness/evaluations/004-order-idempotency.md <<'EOF'
# Evaluation 004 — Order Idempotency

## Objective

Verify that repeated submission of the same order request does not create
duplicate orders or duplicate inventory reservations.

## Scenario

A client submits an order request with an idempotency key:

`order-demo-001`

The client then retries the same request multiple times.

## Required behavior

For the same idempotency key:

1. The system must not create multiple orders.
2. Inventory must only be reserved once.
3. The same logical result should be returned to repeated callers.
4. Concurrent duplicate requests must also be handled safely.

## Redis requirement

Redis should be used meaningfully for idempotency coordination/state.

The implementation must document:

- key format
- TTL
- stored value
- duplicate request behavior
- concurrency behavior

## Failure handling

The implementation must avoid a situation where:

1. Redis says request succeeded
2. database transaction fails
3. subsequent requests are permanently blocked

The chosen consistency strategy must be documented.

## Required tests

At minimum:

- same request submitted twice
- same request submitted many times
- concurrent duplicate requests
- same idempotency key with different request payload
- Redis unavailable behavior

## Architecture constraints

Idempotency logic must not be implemented directly inside controllers.

## Verification

The evaluation passes only when:

`./scripts/verify.sh`

returns exit code `0`.
EOF


echo
echo "[6/10] Creating Evaluation 005: Regression"

cat > .harness/evaluations/005-regression.md <<'EOF'
# Evaluation 005 — Regression

## Objective

Verify that new changes do not break previously established behavior.

## Regression baseline

The following capabilities must continue to work:

- product lookup
- inventory lookup
- order creation
- order detail
- order cancellation
- valid order state transitions
- invalid order state transitions
- inventory reservation
- inventory release
- audit logging
- Redis integration
- frontend order creation
- frontend order detail
- frontend cancellation
- API contract
- architecture rules

## Required verification

The complete Harness verification suite must pass:

`./scripts/verify.sh`

## Forbidden shortcuts

The agent must not:

- delete tests
- weaken assertions
- disable architecture checks
- modify evaluation criteria
- bypass integration tests
- remove Redis usage
- change verification scripts merely to hide failures

## Success criteria

Regression evaluation passes only when all existing verification checks
continue to pass after the new implementation is introduced.
EOF


echo
echo "[7/10] Creating task prompts"

cat > .harness/tasks/002-order-cancellation.prompt.md <<'EOF'
# Task 002 — Implement / Harden Order Cancellation

Read:

- AGENTS.md
- .github/instructions/
- .github/agents/order-system.agent.md
- .harness/evaluations/002-order-cancellation.md

Implement or harden the order cancellation flow according to the evaluation.

Do not modify the evaluation criteria.

Do not weaken or remove existing tests.

Do not modify verification scripts merely to make the task pass.

Use the following loop:

1. Inspect existing implementation.
2. Inspect existing tests.
3. Implement the smallest correct change.
4. Run ./scripts/verify.sh.
5. Analyze failures.
6. Fix root causes.
7. Run verification again.

The task is complete only when:

./scripts/verify.sh

returns exit code 0.
EOF


cat > .harness/tasks/003-inventory-concurrency.prompt.md <<'EOF'
# Task 003 — Harden Inventory Concurrency

Read:

- AGENTS.md
- .github/instructions/
- .github/agents/order-system.agent.md
- .harness/evaluations/003-inventory-concurrency.md

Implement or harden inventory concurrency behavior.

The implementation must guarantee that inventory cannot become negative
under concurrent order creation.

Use real PostgreSQL integration tests.

Do not rely only on mocks.

Do not weaken existing tests.

Do not modify Harness evaluation criteria.

Do not modify verification scripts merely to hide failures.

Run:

./scripts/verify.sh

until all verification checks pass.

The task is complete only when the command exits with code 0.
EOF


cat > .harness/tasks/004-order-idempotency.prompt.md <<'EOF'
# Task 004 — Implement Order Idempotency

Read:

- AGENTS.md
- .github/instructions/
- .github/agents/order-system.agent.md
- .harness/evaluations/004-order-idempotency.md

Implement or harden order creation idempotency.

Redis should provide meaningful idempotency coordination/state.

The implementation must handle concurrent duplicate requests.

Do not weaken or delete tests.

Do not modify evaluation criteria.

Do not modify verification scripts merely to make them pass.

Document the idempotency design.

Run:

./scripts/verify.sh

until the complete Harness verification suite passes.

The task is complete only when the command exits with code 0.
EOF


cat > .harness/tasks/005-regression.prompt.md <<'EOF'
# Task 005 — Regression Verification

Read:

- AGENTS.md
- .github/instructions/
- .github/agents/order-system.agent.md
- .harness/evaluations/005-regression.md

Run the complete Harness verification suite.

If failures occur:

1. Identify the root cause.
2. Determine whether the failure is caused by the current implementation.
3. Fix the implementation.
4. Re-run verification.

Do not:

- delete tests
- weaken assertions
- disable architecture checks
- modify evaluation criteria
- modify verification scripts to hide failures

The task is complete only when:

./scripts/verify.sh

returns exit code 0.
EOF


echo
echo "[8/10] Creating environment verification script"

cat > scripts/verify-env.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

echo "Checking Harness environment..."

required_commands=(
  docker
  git
)

for command in "${required_commands[@]}"; do
  if ! command -v "$command" >/dev/null 2>&1; then
    echo "ERROR: required command not found: $command"
    exit 1
  fi
done

if [ -x "./mvnw" ]; then
  echo "Maven wrapper: OK"
else
  echo "WARNING: ./mvnw not found"
fi

if [ -f "docker-compose.yml" ]; then
  COMPOSE_FILE="docker-compose.yml"
elif [ -f "compose.yml" ]; then
  COMPOSE_FILE="compose.yml"
else
  echo "WARNING: docker compose file not found"
  COMPOSE_FILE=""
fi

if [ -n "$COMPOSE_FILE" ]; then
  echo "Compose file: $COMPOSE_FILE"

  if grep -q '"5434:5432"' "$COMPOSE_FILE"; then
    echo "PostgreSQL host port: 5434"
  else
    echo "WARNING: PostgreSQL port mapping is not 5434:5432"
  fi

  if grep -q '"6380:6379"' "$COMPOSE_FILE"; then
    echo "Redis host port: 6380"
  else
    echo "WARNING: Redis port mapping is not 6380:6379"
  fi
fi

echo
echo "Environment verification completed."
EOF

chmod +x scripts/verify-env.sh


echo
echo "[9/10] Creating evaluation runner"

cat > scripts/run-evaluation.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

EVALUATION_ID="${1:-}"

if [ -z "$EVALUATION_ID" ]; then
  echo "Usage:"
  echo "  ./scripts/run-evaluation.sh 001"
  echo "  ./scripts/run-evaluation.sh 002"
  echo "  ./scripts/run-evaluation.sh 003"
  echo "  ./scripts/run-evaluation.sh 004"
  echo "  ./scripts/run-evaluation.sh 005"
  exit 1
fi

case "$EVALUATION_ID" in
  001)
    EVALUATION="001-order-system-mvp"
    ;;
  002)
    EVALUATION="002-order-cancellation"
    ;;
  003)
    EVALUATION="003-inventory-concurrency"
    ;;
  004)
    EVALUATION="004-order-idempotency"
    ;;
  005)
    EVALUATION="005-regression"
    ;;
  *)
    echo "Unknown evaluation: $EVALUATION_ID"
    exit 1
    ;;
esac

TIMESTAMP="$(date '+%Y-%m-%d_%H-%M-%S')"
REPORT_DIR=".harness/reports/runs"
REPORT_FILE="${REPORT_DIR}/${EVALUATION}-${TIMESTAMP}.md"

mkdir -p "$REPORT_DIR"

START_TIME="$(date +%s)"

echo "=============================================="
echo "Harness Evaluation"
echo "=============================================="
echo "Evaluation: $EVALUATION"
echo "Started:    $(date)"
echo

echo "Running environment verification..."

if ./scripts/verify-env.sh; then
  ENV_STATUS="PASS"
else
  ENV_STATUS="FAIL"
fi

echo
echo "Running complete verification suite..."
echo

VERIFY_STATUS="PASS"

set +e
./scripts/verify.sh
EXIT_CODE=$?
set -e

if [ "$EXIT_CODE" -ne 0 ]; then
  VERIFY_STATUS="FAIL"
fi

END_TIME="$(date +%s)"
DURATION="$((END_TIME - START_TIME))"

if [ "$ENV_STATUS" = "PASS" ] && [ "$VERIFY_STATUS" = "PASS" ]; then
  RESULT="PASS"
else
  RESULT="FAIL"
fi

cat > "$REPORT_FILE" <<EOF_REPORT
# Harness Evaluation Run

## Metadata

- Evaluation: ${EVALUATION}
- Timestamp: ${TIMESTAMP}
- Result: ${RESULT}
- Duration: ${DURATION}s
- Verification exit code: ${EXIT_CODE}

## Environment

- Environment verification: ${ENV_STATUS}

## Verification

Command:

\`\`\`
./scripts/verify.sh
\`\`\`

Result:

${VERIFY_STATUS}

Exit code:

${EXIT_CODE}

## Metrics

| Metric | Value |
|---|---:|
| Task success | ${RESULT} |
| Human intervention | TODO |
| Verification attempts | 1 |
| Self repair iterations | TODO |
| Architecture violations | TODO |
| Regression failures | TODO |
| Duration seconds | ${DURATION} |

## Notes

Add manual observations here.

EOF_REPORT

echo
echo "=============================================="
echo "Evaluation Result"
echo "=============================================="
echo "Evaluation : $EVALUATION"
echo "Result     : $RESULT"
echo "Duration   : ${DURATION}s"
echo "Report     : $REPORT_FILE"
echo "=============================================="

if [ "$RESULT" != "PASS" ]; then
  exit 1
fi
EOF

chmod +x scripts/run-evaluation.sh


echo
echo "[10/10] Creating baseline recorder"

cat > scripts/record-baseline.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

mkdir -p .harness/reports/baseline

TIMESTAMP="$(date '+%Y-%m-%d_%H-%M-%S')"
REPORT=".harness/reports/baseline/single-agent-${TIMESTAMP}.md"

START="$(date +%s)"

echo "=============================================="
echo "Single-Agent Baseline Run"
echo "=============================================="
echo

set +e
./scripts/verify.sh
EXIT_CODE=$?
set -e

END="$(date +%s)"
DURATION="$((END - START))"

if [ "$EXIT_CODE" -eq 0 ]; then
  RESULT="PASS"
else
  RESULT="FAIL"
fi

cat > "$REPORT" <<EOF_REPORT
# Single-Agent Baseline

## Run

- Timestamp: ${TIMESTAMP}
- Result: ${RESULT}
- Duration: ${DURATION}s
- Verification exit code: ${EXIT_CODE}

## Agent

- Agent: Order System Engineer
- Mode: Single-Agent

## Metrics

| Metric | Value |
|---|---:|
| Task success | ${RESULT} |
| Human intervention | TODO |
| Verification attempts | TODO |
| Self repair iterations | TODO |
| Architecture violations | TODO |
| Regression failures | TODO |
| Duration seconds | ${DURATION} |
| Token cost | TODO |

## Human Intervention

Describe whether manual intervention was required.

## Failure / Repair Log

Record:

1. Verification failure
2. Agent diagnosis
3. Fix
4. Verification result

## Conclusion

TODO

EOF_REPORT

echo
echo "Baseline result: $RESULT"
echo "Report: $REPORT"

exit "$EXIT_CODE"
EOF

chmod +x scripts/record-baseline.sh


echo
echo "=============================================="
echo "Phase 2 Harness files created"
echo "=============================================="

echo
echo "New structure:"
echo
echo ".harness/"
echo "├── config/"
echo "│   └── evaluations.yaml"
echo "├── evaluations/"
echo "│   ├── 001-order-system-mvp.md   (existing)"
echo "│   ├── 002-order-cancellation.md"
echo "│   ├── 003-inventory-concurrency.md"
echo "│   ├── 004-order-idempotency.md"
echo "│   └── 005-regression.md"
echo "├── tasks/"
echo "│   ├── 002-order-cancellation.prompt.md"
echo "│   ├── 003-inventory-concurrency.prompt.md"
echo "│   ├── 004-order-idempotency.prompt.md"
echo "│   └── 005-regression.prompt.md"
echo "└── reports/"
echo "    ├── baseline/"
echo "    └── runs/"
echo
echo ".env.example"
echo "scripts/verify-env.sh"
echo "scripts/run-evaluation.sh"
echo "scripts/record-baseline.sh"
echo
echo "=============================================="
echo "IMPORTANT"
echo "=============================================="
echo
echo "Docker ports expected:"
echo "PostgreSQL: localhost:5434"
echo "Redis:      localhost:6380"
echo
echo "Next recommended steps:"
echo
echo "1. ./scripts/verify-env.sh"
echo "2. ./scripts/record-baseline.sh"
echo "3. ./scripts/run-evaluation.sh 002"
echo "4. ./scripts/run-evaluation.sh 003"
echo "5. ./scripts/run-evaluation.sh 004"
echo "6. ./scripts/run-evaluation.sh 005"
echo
echo "Do NOT start Multi-Agent yet."
echo "First establish stable Single-Agent evaluation results."