#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

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

if [ -x "$ROOT/backend/mvnw" ]; then
  echo "Maven wrapper: OK"
else
  echo "WARNING: backend/mvnw not found"
fi

if [ -f "$ROOT/infra/docker/docker-compose.yml" ]; then
  COMPOSE_FILE="$ROOT/infra/docker/docker-compose.yml"
elif [ -f "$ROOT/docker-compose.yml" ]; then
  COMPOSE_FILE="$ROOT/docker-compose.yml"
elif [ -f "$ROOT/compose.yml" ]; then
  COMPOSE_FILE="$ROOT/compose.yml"
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
