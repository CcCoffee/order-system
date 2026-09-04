#!/usr/bin/env bash

set -euo pipefail

echo "=============================================="
echo " Order System - Harness Evaluation Setup"
echo "=============================================="

ROOT="$(pwd)"

if [[ ! -f "$ROOT/AGENTS.md" ]]; then
  echo "ERROR: AGENTS.md not found."
  echo "Please run this script from the order-system root directory."
  exit 1
fi

echo
echo "[1/7] Creating directories..."

mkdir -p \
  infra/docker \
  scripts \
  .harness/evaluations \
  .harness/tasks \
  .harness/state \
  .harness/reports \
  docs/architecture \
  docs/api \
  docs/database


# ============================================================
# 1. Docker infrastructure
# ============================================================

echo
echo "[2/7] Creating Docker infrastructure..."

cat > infra/docker/docker-compose.yml <<'EOF'
services:

  postgres:
    image: postgres:16-alpine
    container_name: order-system-postgres
    restart: unless-stopped
    ports:
      - "5434:5432"
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
      - "6380:6379"
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

The Order System uses the following local infrastructure.

## PostgreSQL

PostgreSQL is expected to already be installed/running on the host.

```text
host: localhost
port: 5434
database: order_system
username: postgres