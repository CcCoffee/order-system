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

# ------------------------------------------------------------

# Harness Specification

# ------------------------------------------------------------

#

# Evaluation specifications are checked first because they define

# the behavioral contract used by the rest of the Harness.

#

# This check validates the structure and completeness of Evaluation

# files. It does not replace semantic Evaluation Review.

#

# ------------------------------------------------------------

run_check "Evaluation Specifications" "verify-evaluations.sh"

# ------------------------------------------------------------

# Plan Artifacts

# ------------------------------------------------------------

# Planner output is a persistent Harness artifact stored under
# .harness/plans/. This check validates that any plan artifacts present
# reference a valid Evaluation / Task and remain consistent with the
# current-task index. It does not require a plan for every task, so the
# normal lightweight bug-fix flow remains unblocked.

# ------------------------------------------------------------

run_check "Implementation Plans" "verify-plans.sh"

# ------------------------------------------------------------

# Repository

# ------------------------------------------------------------

run_check "Repository Structure" "verify-structure.sh"

# ------------------------------------------------------------

# Infrastructure

# ------------------------------------------------------------

run_check "Infrastructure" "verify-infrastructure.sh"

# ------------------------------------------------------------

# Backend

# ------------------------------------------------------------

run_check "Backend" "verify-backend.sh"

# ------------------------------------------------------------

# Architecture

# ------------------------------------------------------------

run_check "Architecture" "verify-architecture.sh"

# ------------------------------------------------------------

# API

# ------------------------------------------------------------

run_check "API Contract" "verify-api.sh"

# ------------------------------------------------------------

# Integration Tests

# ------------------------------------------------------------

run_check "Integration Tests" "integration-test.sh"

# ------------------------------------------------------------

# Frontend

# ------------------------------------------------------------

run_check "Frontend" "verify-frontend.sh"

# ------------------------------------------------------------

# E2E

# ------------------------------------------------------------

run_check "E2E" "e2e.sh"

# ------------------------------------------------------------

# Final Result

# ------------------------------------------------------------

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
