#!/usr/bin/env bash

set -euo pipefail

echo "== E2E tests =="

if [ -d "tests/e2e" ]; then
    echo "Playwright E2E suite detected."
fi

echo "Playwright runner should be implemented here."
