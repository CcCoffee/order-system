#!/usr/bin/env bash

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT"

echo "=============================================="
echo " Simplify Harness"
echo "=============================================="

echo
echo "[1/4] Removing baseline/performance evaluation..."

rm -rf .harness/reports
rm -f scripts/record-baseline.sh

echo "Removed baseline reports and performance measurement."


echo
echo "[2/4] Simplifying evaluation configuration..."

cat > .harness/config/evaluations.yaml <<'EOF'
version: 1

project:
  name: order-system

verification:
  command: ./scripts/verify.sh
  success_exit_code: 0

evaluations:

  - id: 001
    name: order-system-mvp
    category: functional
    status: active

  - id: 002
    name: order-cancellation
    category: business-rule
    status: active

  - id: 003
    name: inventory-concurrency
    category: concurrency
    status: active

  - id: 004
    name: order-idempotency
    category: reliability
    status: active

  - id: 005
    name: regression
    category: regression
    status: active
EOF


echo
echo "[3/4] Simplifying Harness directory..."

mkdir -p \
  .harness/evaluations \
  .harness/tasks \
  .harness/config \
  .harness/state

echo
echo "Current Harness:"
echo

find .harness -maxdepth 2 -type f | sort


echo
echo "[4/4] Verifying canonical verification..."

if [[ -x "./scripts/verify.sh" ]]; then
    echo "PASS: ./scripts/verify.sh exists"
else
    echo "ERROR: ./scripts/verify.sh does not exist or is not executable"
    exit 1
fi

echo
echo "=============================================="
echo " Harness simplified"
echo "=============================================="

echo
echo "The Harness now focuses on:"
echo
echo "  AGENTS.md"
echo "      ↓"
echo "  Copilot Instructions"
echo "      ↓"
echo "  Evaluation"
echo "      ↓"
echo "  Task"
echo "      ↓"
echo "  Agent"
echo "      ↓"
echo "  ./scripts/verify.sh"
echo "      ↓"
echo "  PASS / FAIL"
echo