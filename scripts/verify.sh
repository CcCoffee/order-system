#!/usr/bin/env bash

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

echo "========================================"
echo "       ENGINEERING HARNESS VERIFY"
echo "========================================"

./scripts/verify-backend.sh
./scripts/verify-frontend.sh
./scripts/integration-test.sh
./scripts/e2e.sh

echo
echo "========================================"
echo "       ALL VERIFICATIONS PASSED"
echo "========================================"
