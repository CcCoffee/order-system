#!/usr/bin/env bash

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
EVAL_DIR="$ROOT/.harness/evaluations"

echo "=============================================="
echo " Harness Evaluation Verification"
echo "=============================================="
echo

if [[ ! -d "$EVAL_DIR" ]]; then
  echo "FAIL: missing .harness/evaluations"
  exit 1
fi

files=()
while IFS= read -r _file; do
  files+=("$_file")
done < <(
  find "$EVAL_DIR" -maxdepth 1 -type f -name '*.md' \
    ! -name 'TEMPLATE.md' \
    | sort
)

if [[ ${#files[@]} -eq 0 ]]; then
  echo "PASS: no Evaluation files found"
  exit 0
fi

failed=0

for file in "${files[@]}"; do
  name="${file#$ROOT/}"

  echo "Checking: $name"

  required_sections=(
    "## Objective"
    "## Acceptance Criteria"
    "## Required Evidence"
    "## Required Tests"
    "## Architecture Constraints"
    "## Verification"
    "## Forbidden Shortcuts"
  )

  for section in "${required_sections[@]}"; do
    if ! grep -Fq "$section" "$file"; then
      echo " FAIL: missing section: $section"
      failed=1
    else
      echo " PASS: $section"
    fi
  done

  # ----------------------------------------------------------
  # Extract AC identifiers
  # ----------------------------------------------------------
  criteria=()
  while IFS= read -r _criterion; do
    criteria+=("$_criterion")
  done < <(
    grep -E '^### AC-[0-9]+' "$file" \
      | sed -E 's/^### (AC-[0-9]+).*/\1/' \
      | sort -V \
      | uniq
  )

  if [[ ${#criteria[@]} -eq 0 ]]; then
    echo " FAIL: no Acceptance Criteria found"
    failed=1
  else
    echo " PASS: found ${#criteria[@]} Acceptance Criteria"
  fi

  # ----------------------------------------------------------
  # Evidence coverage
  # ----------------------------------------------------------
  if [[ ${#criteria[@]} -gt 0 ]]; then
    for criterion in "${criteria[@]}"; do
      if grep -Fq "$criterion" "$file"; then
        echo " PASS: evidence reference exists for $criterion"
      else
        echo " FAIL: no evidence reference for $criterion"
        failed=1
      fi
    done
  fi

  # ----------------------------------------------------------
  # Detect obviously weak concurrency specifications
  # ----------------------------------------------------------
  if grep -Eiq 'concurr|concurrent|race condition|oversell|locking|parallel' "$file"; then
    echo "  INFO: concurrency-related Evaluation detected"

    concurrency_requirements=(
      "real"
      "integration"
      "concurrent"
    )

    for keyword in "${concurrency_requirements[@]}"; do
      if grep -Eiq "$keyword" "$file"; then
        echo "  PASS: concurrency evidence mentions '$keyword'"
      else
        echo "  WARN: concurrency Evaluation does not explicitly mention '$keyword'"
      fi
    done

    if grep -Eiq 'sequential execution|sequential.*not|not.*sequential|mock.*not|not.*mock' "$file"; then
      echo "  PASS: concurrency anti-shortcut guidance found"
    else
      echo "  WARN: consider explicitly forbidding sequential/mock substitutes"
    fi
  fi

  # ----------------------------------------------------------
  # Verification
  # ----------------------------------------------------------
  if grep -Fq './scripts/verify.sh' "$file"; then
    echo " PASS: repository verification defined"
  else
    echo " FAIL: ./scripts/verify.sh not referenced"
    failed=1
  fi

  echo
done

echo "----------------------------------------------"

if [[ "$failed" -ne 0 ]]; then
  echo "HARNESS EVALUATION VERIFY: FAIL"
  exit 1
fi

echo "HARNESS EVALUATION VERIFY: PASS"
