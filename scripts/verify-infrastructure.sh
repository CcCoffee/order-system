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
