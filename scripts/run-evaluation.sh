#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

EVAL_DIR="$ROOT/.harness/evaluations"
TASK_DIR="$ROOT/.harness/tasks"
REPORT_DIR="$ROOT/.harness/reports/runs"

EVALUATION_ID="${1:-}"

usage() {
  echo "Usage:"
  echo "  ./scripts/run-evaluation.sh <EVALUATION_ID>"
  echo
  echo "Examples:"
  echo "  ./scripts/run-evaluation.sh 001"
  echo "  ./scripts/run-evaluation.sh 003"
}

# ------------------------------------------------------------
# 1. Validate argument
# ------------------------------------------------------------
if [ -z "$EVALUATION_ID" ]; then
  usage
  exit 1
fi

if ! [[ "$EVALUATION_ID" =~ ^[0-9]+$ ]]; then
  echo "ERROR: invalid Evaluation ID '$EVALUATION_ID'. Expected a numeric ID, e.g. 001."
  exit 1
fi

# ------------------------------------------------------------
# 2. Resolve Evaluation
# ------------------------------------------------------------
if [[ ! -d "$EVAL_DIR" ]]; then
  echo "ERROR: missing .harness/evaluations"
  exit 1
fi

eval_files=()
while IFS= read -r _file; do
  eval_files+=("$_file")
done < <(find "$EVAL_DIR" -maxdepth 1 -type f -name "${EVALUATION_ID}-*.md" 2>/dev/null | sort)

if [[ ${#eval_files[@]} -eq 0 ]]; then
  echo "ERROR: Evaluation '$EVALUATION_ID' not found in $EVAL_DIR"
  exit 1
fi

if [[ ${#eval_files[@]} -gt 1 ]]; then
  echo "ERROR: multiple Evaluations match ID '$EVALUATION_ID':"
  printf '  %s\n' "${eval_files[@]}"
  exit 1
fi

EVALUATION_FILE="${eval_files[0]}"
EVALUATION_NAME="$(basename "$EVALUATION_FILE")"
EVALUATION_SLUG="${EVALUATION_NAME%.md}"
EVALUATION_REL=".harness/evaluations/${EVALUATION_NAME}"

# ------------------------------------------------------------
# 3. Resolve matching Task
# ------------------------------------------------------------
if [[ ! -d "$TASK_DIR" ]]; then
  echo "ERROR: missing .harness/tasks"
  exit 1
fi

task_files=()
while IFS= read -r _file; do
  task_files+=("$_file")
done < <(find "$TASK_DIR" -maxdepth 1 -type f -name "${EVALUATION_ID}-*.prompt.md" 2>/dev/null | sort)

if [[ ${#task_files[@]} -eq 0 ]]; then
  echo "ERROR: no matching Task for Evaluation '$EVALUATION_ID' in $TASK_DIR"
  exit 1
fi

if [[ ${#task_files[@]} -gt 1 ]]; then
  echo "ERROR: multiple Tasks match ID '$EVALUATION_ID':"
  printf '  %s\n' "${task_files[@]}"
  exit 1
fi

TASK_FILE="${task_files[0]}"
TASK_NAME="$(basename "$TASK_FILE")"
TASK_SLUG="${TASK_NAME%.prompt.md}"
TASK_REL=".harness/tasks/${TASK_NAME}"

# ------------------------------------------------------------
# 4. Verify Evaluation/Task naming consistency
# ------------------------------------------------------------
if [[ "$TASK_SLUG" != "$EVALUATION_SLUG" ]]; then
  echo "ERROR: Evaluation and Task naming mismatch:"
  echo "  Evaluation: $EVALUATION_SLUG"
  echo "  Task:       $TASK_SLUG"
  exit 1
fi

# ------------------------------------------------------------
# 5. Report setup
# ------------------------------------------------------------
if ! mkdir -p "$REPORT_DIR"; then
  echo "ERROR: cannot create report directory: $REPORT_DIR"
  exit 1
fi

TIMESTAMP="$(date '+%Y-%m-%d_%H-%M-%S')"
REPORT_FILE="${REPORT_DIR}/${EVALUATION_SLUG}-${TIMESTAMP}.md"

echo "=============================================="
echo "Harness Evaluation Run"
echo "=============================================="
echo "Evaluation: $EVALUATION_SLUG"
echo "Task:       $TASK_SLUG"
echo "Started:    $(date)"
echo

START_TIME="$(date +%s)"

# ------------------------------------------------------------
# 6. Verify environment
# ------------------------------------------------------------
echo "Running environment verification..."
ENV_STATUS="FAIL"
ENV_EXIT=0
set +e
./scripts/verify-env.sh
ENV_EXIT=$?
set -e
if [ "$ENV_EXIT" -eq 0 ]; then
  ENV_STATUS="PASS"
fi
echo "Environment verification: $ENV_STATUS"
echo

# ------------------------------------------------------------
# 7. Run repository verification
# ------------------------------------------------------------
echo "Running repository verification..."
echo "Command: ./scripts/verify.sh"
echo
VERIFY_STATUS="FAIL"
VERIFY_EXIT=0
set +e
./scripts/verify.sh
VERIFY_EXIT=$?
set -e
if [ "$VERIFY_EXIT" -eq 0 ]; then
  VERIFY_STATUS="PASS"
fi
echo
echo "Repository verification: $VERIFY_STATUS (exit code: $VERIFY_EXIT)"

END_TIME="$(date +%s)"
DURATION="$((END_TIME - START_TIME))"

# ------------------------------------------------------------
# 8. Compute result
# ------------------------------------------------------------
if [ "$ENV_STATUS" = "PASS" ] && [ "$VERIFY_STATUS" = "PASS" ]; then
  RESULT="PASS"
else
  RESULT="FAIL"
fi

# ------------------------------------------------------------
# 9. Generate report
# ------------------------------------------------------------
cat > "$REPORT_FILE" <<EOF_REPORT
# Harness Evaluation Run

## Metadata

- Evaluation: ${EVALUATION_SLUG}
- Evaluation ID: ${EVALUATION_ID}
- Task: ${TASK_SLUG}
- Timestamp: ${TIMESTAMP}
- Result: ${RESULT}
- Duration: ${DURATION}s

## Artifacts

- Evaluation: ${EVALUATION_REL}
- Task: ${TASK_REL}

## Environment

- Environment verification: ${ENV_STATUS}

## Repository Verification

Command:

\`\`\`
./scripts/verify.sh
\`\`\`

Result:

${VERIFY_STATUS}

Exit code:

${VERIFY_EXIT}

## Notes

This report records the result of a Harness execution for Evaluation
${EVALUATION_SLUG}. A PASS here means the repository verification
\`./scripts/verify.sh\` completed successfully in the current environment.

It does not claim that every Acceptance Criterion has been independently
proven. Evidence sufficiency remains the responsibility of the Test Agent
and the Reviewer.
EOF_REPORT

echo
echo "=============================================="
echo "Evaluation Run Result"
echo "=============================================="
echo "Evaluation : $EVALUATION_SLUG"
echo "Result     : $RESULT"
echo "Duration   : ${DURATION}s"
echo "Report     : $REPORT_FILE"
echo "=============================================="

if [ "$RESULT" != "PASS" ]; then
  exit 1
fi

exit 0
