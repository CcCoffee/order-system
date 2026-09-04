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
