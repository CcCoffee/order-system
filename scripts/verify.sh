#!/usr/bin/env bash

set -uo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

FAILED=0

run_check() {
local name="$1"
local script="$2"

echo
echo "=================================================="
echo " CHECK: $name"
echo "=================================================="

if "$ROOT/scripts/$script"; then
echo "RESULT: PASS"
else
echo "RESULT: FAIL"
FAILED=1
fi
}

run_check "Repository Structure" "verify-structure.sh"
run_check "Infrastructure" "verify-infrastructure.sh"
run_check "Backend" "verify-backend.sh"
run_check "Architecture" "verify-architecture.sh"
run_check "API Contract" "verify-api.sh"
run_check "Integration Tests" "integration-test.sh"
run_check "Frontend" "verify-frontend.sh"
run_check "E2E" "e2e.sh"

echo

if [[ "$FAILED" -eq 0 ]]; then
echo "=================================================="
echo " HARNESS VERIFICATION: PASS"
echo "=================================================="
exit 0
fi

echo "=================================================="
echo " HARNESS VERIFICATION: FAIL"
echo "=================================================="

exit 1
