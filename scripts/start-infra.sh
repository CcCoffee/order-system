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
