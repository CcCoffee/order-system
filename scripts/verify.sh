#!/usr/bin/env bash

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

cd "$ROOT"

FAILED=0

run_check() {
    local name="$1"
    shift

    echo
    echo "============================================================"
    echo " CHECK: $name"
    echo "============================================================"

    if "$@"; then
        echo
        echo "PASS: $name"
    else
        echo
        echo "FAIL: $name"
        FAILED=1
    fi
}

echo
echo "############################################################"
echo "#                  ORDER SYSTEM HARNESS                    #"
echo "############################################################"

# ------------------------------------------------------------
# 1. Repository
# ------------------------------------------------------------

run_check \
    "Repository Structure" \
    "$ROOT/scripts/verify-structure.sh"

# ------------------------------------------------------------
# 2. Infrastructure
# ------------------------------------------------------------

run_check \
    "Infrastructure" \
    "$ROOT/scripts/verify-infrastructure.sh"

# ------------------------------------------------------------
# 3. Backend
# ------------------------------------------------------------

if [[ -d "$ROOT/backend" ]]; then

    run_check \
        "Backend" \
        "$ROOT/scripts/verify-backend.sh"

    run_check \
        "Architecture" \
        "$ROOT/scripts/verify-architecture.sh"

    run_check \
        "API Contract" \
        "$ROOT/scripts/verify-api.sh"

    run_check \
        "Integration Tests" \
        "$ROOT/scripts/integration-test.sh"

else
    echo
    echo "SKIP: backend/ does not exist."
fi

# ------------------------------------------------------------
# 4. Frontend
# ------------------------------------------------------------

if [[ -d "$ROOT/frontend" ]]; then

    run_check \
        "Frontend" \
        "$ROOT/scripts/verify-frontend.sh"

else
    echo
    echo "SKIP: frontend/ does not exist."
fi

# ------------------------------------------------------------
# 5. E2E
# ------------------------------------------------------------

if [[ -d "$ROOT/frontend" ]]; then

    if [[ -f "$ROOT/frontend/package.json" ]]; then
        run_check \
            "E2E" \
            "$ROOT/scripts/e2e.sh"
    else
        echo
        echo "SKIP: frontend package.json does not exist."
    fi

else
    echo
    echo "SKIP: E2E."
fi

# ------------------------------------------------------------
# Result
# ------------------------------------------------------------

echo
echo "############################################################"

if [[ "$FAILED" -eq 0 ]]; then

    echo "#                 HARNESS RESULT: PASS                    #"

else

    echo "#                 HARNESS RESULT: FAIL                    #"

fi

echo "############################################################"
echo

exit "$FAILED"
