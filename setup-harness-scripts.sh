#!/usr/bin/env bash

set -euo pipefail

ROOT="$(pwd)"

if [[ ! -f "$ROOT/AGENTS.md" ]]; then
  echo "ERROR: AGENTS.md not found."
  echo "Please run this script from the order-system root directory."
  exit 1
fi

mkdir -p "$ROOT/scripts"

echo "Generating Harness scripts..."

# ============================================================
# verify.sh
# ============================================================

cat > "$ROOT/scripts/verify.sh" <<'EOF'
#!/usr/bin/env bash

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

cd "$ROOT"

FAILED=0

run_check() {
    local name="$1"
    shift

    echo
    echo "============================================================"
    echo " CHECK: $name"
    echo "============================================================"

    if "$@"; then
        echo
        echo "PASS: $name"
    else
        echo
        echo "FAIL: $name"
        FAILED=1
    fi
}

echo
echo "############################################################"
echo "#                  ORDER SYSTEM HARNESS                    #"
echo "############################################################"

# ------------------------------------------------------------
# 1. Repository
# ------------------------------------------------------------

run_check \
    "Repository Structure" \
    "$ROOT/scripts/verify-structure.sh"

# ------------------------------------------------------------
# 2. Infrastructure
# ------------------------------------------------------------

run_check \
    "Infrastructure" \
    "$ROOT/scripts/verify-infrastructure.sh"

# ------------------------------------------------------------
# 3. Backend
# ------------------------------------------------------------

if [[ -d "$ROOT/backend" ]]; then

    run_check \
        "Backend" \
        "$ROOT/scripts/verify-backend.sh"

    run_check \
        "Architecture" \
        "$ROOT/scripts/verify-architecture.sh"

    run_check \
        "API Contract" \
        "$ROOT/scripts/verify-api.sh"

    run_check \
        "Integration Tests" \
        "$ROOT/scripts/integration-test.sh"

else
    echo
    echo "SKIP: backend/ does not exist."
fi

# ------------------------------------------------------------
# 4. Frontend
# ------------------------------------------------------------

if [[ -d "$ROOT/frontend" ]]; then

    run_check \
        "Frontend" \
        "$ROOT/scripts/verify-frontend.sh"

else
    echo
    echo "SKIP: frontend/ does not exist."
fi

# ------------------------------------------------------------
# 5. E2E
# ------------------------------------------------------------

if [[ -d "$ROOT/frontend" ]]; then

    if [[ -f "$ROOT/frontend/package.json" ]]; then
        run_check \
            "E2E" \
            "$ROOT/scripts/e2e.sh"
    else
        echo
        echo "SKIP: frontend package.json does not exist."
    fi

else
    echo
    echo "SKIP: E2E."
fi

# ------------------------------------------------------------
# Result
# ------------------------------------------------------------

echo
echo "############################################################"

if [[ "$FAILED" -eq 0 ]]; then

    echo "#                 HARNESS RESULT: PASS                    #"

else

    echo "#                 HARNESS RESULT: FAIL                    #"

fi

echo "############################################################"
echo

exit "$FAILED"
EOF


# ============================================================
# verify-structure.sh
# ============================================================

cat > "$ROOT/scripts/verify-structure.sh" <<'EOF'
#!/usr/bin/env bash

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "Checking repository structure..."

REQUIRED_FILES=(
    "AGENTS.md"
    ".github/copilot-instructions.md"
)

REQUIRED_DIRS=(
    ".github"
    ".github/agents"
    ".github/instructions"
    "docs"
    "scripts"
    ".harness"
    ".harness/evaluations"
    ".harness/tasks"
)

for file in "${REQUIRED_FILES[@]}"; do
    if [[ ! -f "$ROOT/$file" ]]; then
        echo "Missing required file: $file"
        exit 1
    fi
done

for dir in "${REQUIRED_DIRS[@]}"; do
    if [[ ! -d "$ROOT/$dir" ]]; then
        echo "Missing required directory: $dir"
        exit 1
    fi
done

echo "Repository structure OK."
EOF


# ============================================================
# verify-infrastructure.sh
# ============================================================

cat > "$ROOT/scripts/verify-infrastructure.sh" <<'EOF'
#!/usr/bin/env bash

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "Checking Docker..."

if ! command -v docker >/dev/null 2>&1; then
    echo "ERROR: docker command not found."
    exit 1
fi

if ! docker info >/dev/null 2>&1; then
    echo "ERROR: Docker daemon is not running."
    exit 1
fi

# ------------------------------------------------------------
# Redis
# ------------------------------------------------------------

echo
echo "Checking Redis..."

if ! docker ps --format '{{.Names}}' | grep -qx "order-system-redis"; then

    echo "ERROR: Redis container is not running."
    echo
    echo "Start it with:"
    echo
    echo "  ./scripts/start-infra.sh"

    exit 1
fi

REDIS_RESULT="$(
    docker exec order-system-redis redis-cli ping 2>/dev/null || true
)"

if [[ "$REDIS_RESULT" != "PONG" ]]; then
    echo "ERROR: Redis health check failed."
    exit 1
fi

echo "Redis: OK"

# ------------------------------------------------------------
# PostgreSQL
# ------------------------------------------------------------

echo
echo "Checking PostgreSQL..."

if ! command -v psql >/dev/null 2>&1; then

    echo "WARNING: psql command not found."
    echo "PostgreSQL will be verified by integration tests."

else

    DB_PASSWORD="${DATABASE_PASSWORD:-123456}"

    if PGPASSWORD="$DB_PASSWORD" \
        psql \
        -h localhost \
        -p 5432 \
        -U postgres \
        -d order_system \
        -c "SELECT 1;" >/dev/null 2>&1
    then
        echo "PostgreSQL: OK"
    else
        echo
        echo "ERROR: Cannot connect to PostgreSQL database 'order_system'."
        echo
        echo "Expected:"
        echo "  host: localhost"
        echo "  port: 5432"
        echo "  user: postgres"
        echo "  database: order_system"
        echo
        echo "Create the database with:"
        echo
        echo "  CREATE DATABASE order_system;"
        echo

        exit 1
    fi
fi
EOF


# ============================================================
# verify-backend.sh
# ============================================================

cat > "$ROOT/scripts/verify-backend.sh" <<'EOF'
#!/usr/bin/env bash

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

cd "$ROOT/backend"

echo "Checking Spring Boot backend..."

if [[ -f "./mvnw" ]]; then

    chmod +x ./mvnw

    echo "Running Maven tests..."

    ./mvnw test

elif [[ -f "pom.xml" ]]; then

    if ! command -v mvn >/dev/null 2>&1; then
        echo "ERROR: Maven is not installed."
        exit 1
    fi

    mvn test

else

    echo "ERROR: Maven project not found."
    echo "Expected backend/pom.xml"
    exit 1

fi

echo
echo "Backend verification OK."
EOF


# ============================================================
# verify-frontend.sh
# ============================================================

cat > "$ROOT/scripts/verify-frontend.sh" <<'EOF'
#!/usr/bin/env bash

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

cd "$ROOT/frontend"

echo "Checking React frontend..."

if [[ ! -f package.json ]]; then
    echo "ERROR: frontend/package.json not found."
    exit 1
fi

if [[ ! -d node_modules ]]; then
    echo "Installing frontend dependencies..."

    npm install
fi

echo
echo "Running frontend tests..."

npm test -- --run

echo
echo "Running frontend build..."

npm run build

echo
echo "Frontend verification OK."
EOF


# ============================================================
# verify-architecture.sh
# ============================================================

cat > "$ROOT/scripts/verify-architecture.sh" <<'EOF'
#!/usr/bin/env bash

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

cd "$ROOT/backend"

echo "Checking architecture..."

if [[ -f "./mvnw" ]]; then
    ./mvnw test -Dgroups=architecture
    exit 0
fi

if [[ -f "pom.xml" ]]; then
    mvn test -Dgroups=architecture
    exit 0
fi

echo "ERROR: Backend Maven project not found."
exit 1
EOF


# ============================================================
# verify-api.sh
# ============================================================

cat > "$ROOT/scripts/verify-api.sh" <<'EOF'
#!/usr/bin/env bash

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

OPENAPI_FILE="$ROOT/docs/api/openapi.yaml"

echo "Checking OpenAPI contract..."

if [[ ! -f "$OPENAPI_FILE" ]]; then
    echo "ERROR: OpenAPI specification not found:"
    echo "  $OPENAPI_FILE"
    exit 1
fi

# ------------------------------------------------------------
# Prefer Redocly CLI if available
# ------------------------------------------------------------

if command -v redocly >/dev/null 2>&1; then

    redocly lint "$OPENAPI_FILE"

    echo "OpenAPI contract OK."
    exit 0
fi

# ------------------------------------------------------------
# Fallback: basic structural validation
# ------------------------------------------------------------

if ! grep -q "^openapi:" "$OPENAPI_FILE"; then
    echo "ERROR: Missing 'openapi:' field."
    exit 1
fi

if ! grep -q "^info:" "$OPENAPI_FILE"; then
    echo "ERROR: Missing 'info:' field."
    exit 1
fi

if ! grep -q "^paths:" "$OPENAPI_FILE"; then
    echo "ERROR: Missing 'paths:' field."
    exit 1
fi

echo "OpenAPI basic validation OK."
echo "NOTE: Install Redocly CLI for full validation."
EOF


# ============================================================
# integration-test.sh
# ============================================================

cat > "$ROOT/scripts/integration-test.sh" <<'EOF'
#!/usr/bin/env bash

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

cd "$ROOT/backend"

echo "Running integration tests..."

if [[ -f "./mvnw" ]]; then

    chmod +x ./mvnw

    ./mvnw test \
        -Dgroups=integration

elif [[ -f "pom.xml" ]]; then

    mvn test \
        -Dgroups=integration

else

    echo "ERROR: Maven project not found."
    exit 1

fi

echo
echo "Integration tests OK."
EOF


# ============================================================
# e2e.sh
# ============================================================

cat > "$ROOT/scripts/e2e.sh" <<'EOF'
#!/usr/bin/env bash

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

cd "$ROOT/frontend"

echo "Running E2E tests..."

if [[ ! -f package.json ]]; then
    echo "ERROR: frontend/package.json not found."
    exit 1
fi

# ------------------------------------------------------------
# Detect Playwright
# ------------------------------------------------------------

if [[ -x "node_modules/.bin/playwright" ]]; then

    node_modules/.bin/playwright test

elif command -v npx >/dev/null 2>&1; then

    npx playwright test

else

    echo "ERROR: Playwright not installed."
    exit 1

fi

echo
echo "E2E tests OK."
EOF


# ============================================================
# start-infra.sh
# ============================================================

cat > "$ROOT/scripts/start-infra.sh" <<'EOF'
#!/usr/bin/env bash

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

cd "$ROOT"

echo "Starting local infrastructure..."

docker compose \
    -f infra/docker/docker-compose.yml \
    up -d

echo
echo "Waiting for Redis..."

for i in {1..30}; do

    if docker exec order-system-redis redis-cli ping >/dev/null 2>&1; then
        echo "Redis is ready."
        break
    fi

    sleep 1

done

echo
echo "Infrastructure status:"
echo

docker compose \
    -f infra/docker/docker-compose.yml \
    ps

echo
echo "Infrastructure started."
EOF


# ============================================================
# stop-infra.sh
# ============================================================

cat > "$ROOT/scripts/stop-infra.sh" <<'EOF'
#!/usr/bin/env bash

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

cd "$ROOT"

docker compose \
    -f infra/docker/docker-compose.yml \
    down
EOF


# ============================================================
# reset-infra.sh
# ============================================================

cat > "$ROOT/scripts/reset-infra.sh" <<'EOF'
#!/usr/bin/env bash

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

cd "$ROOT"

echo "WARNING: This will delete local Redis data."

read -r -p "Continue? [y/N] " answer

if [[ "$answer" != "y" && "$answer" != "Y" ]]; then
    echo "Cancelled."
    exit 0
fi

docker compose \
    -f infra/docker/docker-compose.yml \
    down -v

docker compose \
    -f infra/docker/docker-compose.yml \
    up -d

echo "Redis has been reset."
EOF


# ============================================================
# permissions
# ============================================================

chmod +x "$ROOT/scripts/"*.sh


echo
echo "============================================================"
echo "Harness scripts generated successfully."
echo "============================================================"
echo
echo "Available commands:"
echo
echo "  ./scripts/start-infra.sh"
echo "  ./scripts/verify-infrastructure.sh"
echo "  ./scripts/verify.sh"
echo