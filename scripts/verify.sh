#!/usr/bin/env bash

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

cd "$ROOT"

echo ""
echo "=========================================="
echo "       ENGINEERING HARNESS"
echo "=========================================="
echo ""

./scripts/verify-backend.sh

./scripts/verify-frontend.sh

./scripts/integration-test.sh

./scripts/e2e.sh

echo ""
echo "=========================================="
echo "       HARNESS VERIFICATION PASSED"
echo "=========================================="
