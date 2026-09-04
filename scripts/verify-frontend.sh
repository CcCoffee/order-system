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
