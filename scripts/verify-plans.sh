#!/usr/bin/env bash

set -uo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PLAN_DIR="$ROOT/.harness/plans"
EVAL_DIR="$ROOT/.harness/evaluations"
TASK_DIR="$ROOT/.harness/tasks"
STATE_FILE="$ROOT/.harness/state/current-task.yaml"

echo "=============================================="
echo " Harness Plan Artifact Verification"
echo "=============================================="
echo

failed=0

# ----------------------------------------------------------------------
# 1. .harness/plans must exist
# ----------------------------------------------------------------------
if [[ ! -d "$PLAN_DIR" ]]; then
  echo "FAIL: missing .harness/plans"
  exit 1
fi

# ----------------------------------------------------------------------
# Collect plan artifacts (excluding TEMPLATE.md)
# ----------------------------------------------------------------------
plan_files=()
while IFS= read -r _file; do
  plan_files+=("$_file")
done < <(
  find "$PLAN_DIR" -maxdepth 1 -type f -name '*.plan.md' \
    ! -name 'TEMPLATE.md' \
    | sort
)

if [[ ${#plan_files[@]} -eq 0 ]]; then
  echo "PASS: no plan artifacts present"
else
  for file in "${plan_files[@]}"; do
    name="${file#$ROOT/}"

    echo "Checking: $name"

    # ------------------------------------------------------------------
    # 6. Plan must not be empty
    # ------------------------------------------------------------------
    if [[ ! -s "$file" ]]; then
      echo " FAIL: plan is empty"
      failed=1
    else
      echo " PASS: plan is non-empty"
    fi

    # ------------------------------------------------------------------
    # 2. Plan file format must be reasonable
    # ------------------------------------------------------------------
    for section in "# Implementation Plan" "## Task" "## Evaluation" "## Objective" "## Acceptance Criteria Mapping"; do
      if ! grep -Fq "$section" "$file"; then
        echo " FAIL: missing section: $section"
        failed=1
      else
        echo " PASS: section present: $section"
      fi
    done

    # AC mapping entries
    ac_count="$(grep -cE '^### AC-[0-9]+' "$file" || true)"
    if [[ "$ac_count" -eq 0 ]]; then
      echo " FAIL: no Acceptance Criteria mapping entries found (### AC-N)"
      failed=1
    else
      echo " PASS: found $ac_count Acceptance Criteria mapping entries"
    fi

    # ------------------------------------------------------------------
    # 3 / 4 / 5. Evaluation / Task / Plan ID consistency
    # ------------------------------------------------------------------
    base="$(basename "$file")"
    eval_id="$(echo "$base" | sed -E 's/^([0-9]+)-.*\.plan\.md$/\1/')"

    if [[ -z "$eval_id" ]]; then
      echo " FAIL: cannot parse evaluation id from filename: $base"
      failed=1
      continue
    fi

    # Matching Evaluation file
    eval_count="$(find "$EVAL_DIR" -maxdepth 1 -type f -name "$eval_id-*.md" ! -name 'TEMPLATE.md' | wc -l | tr -d ' ')"
    if [[ "$eval_count" -eq 0 ]]; then
      echo " FAIL: no Evaluation file matches id $eval_id"
      failed=1
    else
      echo " PASS: Evaluation exists for id $eval_id"
    fi

    # Matching Task file
    task_count="$(find "$TASK_DIR" -maxdepth 1 -type f -name "$eval_id-*.prompt.md" | wc -l | tr -d ' ')"
    if [[ "$task_count" -eq 0 ]]; then
      echo " FAIL: no Task file matches id $eval_id"
      failed=1
    else
      echo " PASS: Task exists for id $eval_id"
    fi

    # Plan must reference its own evaluation id
    if grep -Fq "$eval_id" "$file"; then
      echo " PASS: plan references id $eval_id"
    else
      echo " FAIL: plan does not reference evaluation id $eval_id"
      failed=1
    fi

    echo
  done
fi

# ----------------------------------------------------------------------
# 7. If the current task requires a Plan, the referenced plan must exist.
#    This honours the lightweight flow: only enforced when the current
#    task index explicitly points at a plan.
# ----------------------------------------------------------------------
if [[ -f "$STATE_FILE" ]]; then
  plan_ref="$(sed -n 's/^plan:[[:space:]]*\(.*\)/\1/p' "$STATE_FILE" | sed 's/[[:space:]]*#.*$//' | tr -d ' "')"
  if [[ -n "$plan_ref" ]]; then
    resolved="$ROOT/$plan_ref"
    if [[ ! -f "$resolved" ]]; then
      echo "FAIL: current task references a plan that does not exist: $plan_ref"
      failed=1
    else
      echo "PASS: current task plan exists: $plan_ref"
    fi
  fi
fi

echo "----------------------------------------------"

if [[ "$failed" -ne 0 ]]; then
  echo "HARNESS PLAN VERIFY: FAIL"
  exit 1
fi

echo "HARNESS PLAN VERIFY: PASS"
