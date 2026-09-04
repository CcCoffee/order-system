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
