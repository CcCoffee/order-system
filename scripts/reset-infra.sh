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
