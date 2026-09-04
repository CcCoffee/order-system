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