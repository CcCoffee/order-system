#!/usr/bin/env bash

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

if [[ ! -f "$ROOT/frontend/package.json" ]]; then
echo "SKIP: frontend/package.json does not exist yet."
exit 0
fi

cd "$ROOT/frontend"

if [[ ! -d node_modules ]]; then
echo "FAIL: frontend dependencies are not installed."
exit 1
fi

if ! npm list @playwright/test >/dev/null 2>&1; then
echo "FAIL: @playwright/test is not installed."
exit 1
fi

echo "Running Playwright E2E tests..."

npx playwright test
