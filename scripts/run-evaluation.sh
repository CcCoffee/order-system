#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

EVALUATION_ID="${1:-}"

if [ -z "$EVALUATION_ID" ]; then
  echo "Usage:"
  echo "  ./scripts/run-evaluation.sh 001"
  echo "  ./scripts/run-evaluation.sh 002"
  echo "  ./scripts/run-evaluation.sh 003"
  echo "  ./scripts/run-evaluation.sh 004"
  echo "  ./scripts/run-evaluation.sh 005"
  exit 1
fi

case "$EVALUATION_ID" in
  001)
    EVALUATION="001-order-system-mvp"
    ;;
  002)
    EVALUATION="002-order-cancellation"
    ;;
  003)
    EVALUATION="003-inventory-concurrency"
    ;;
  004)
    EVALUATION="004-order-idempotency"
    ;;
  005)
    EVALUATION="005-regression"
    ;;
  *)
    echo "Unknown evaluation: $EVALUATION_ID"
    exit 1
    ;;
esac

TIMESTAMP="$(date '+%Y-%m-%d_%H-%M-%S')"
REPORT_DIR=".harness/reports/runs"
REPORT_FILE="${REPORT_DIR}/${EVALUATION}-${TIMESTAMP}.md"

mkdir -p "$REPORT_DIR"

START_TIME="$(date +%s)"

echo "=============================================="
echo "Harness Evaluation"
echo "=============================================="
echo "Evaluation: $EVALUATION"
echo "Started:    $(date)"
echo

echo "Running environment verification..."

if ./scripts/verify-env.sh; then
  ENV_STATUS="PASS"
else
  ENV_STATUS="FAIL"
fi

echo
echo "Running complete verification suite..."
echo

VERIFY_STATUS="PASS"

set +e
./scripts/verify.sh
EXIT_CODE=$?
set -e

if [ "$EXIT_CODE" -ne 0 ]; then
  VERIFY_STATUS="FAIL"
fi

END_TIME="$(date +%s)"
DURATION="$((END_TIME - START_TIME))"

if [ "$ENV_STATUS" = "PASS" ] && [ "$VERIFY_STATUS" = "PASS" ]; then
  RESULT="PASS"
else
  RESULT="FAIL"
fi

cat > "$REPORT_FILE" <<EOF_REPORT
# Harness Evaluation Run

## Metadata

- Evaluation: ${EVALUATION}
- Timestamp: ${TIMESTAMP}
- Result: ${RESULT}
- Duration: ${DURATION}s
- Verification exit code: ${EXIT_CODE}

## Environment

- Environment verification: ${ENV_STATUS}

## Verification

Command:

\`\`\`
./scripts/verify.sh
\`\`\`

Result:

${VERIFY_STATUS}

Exit code:

${EXIT_CODE}

## Metrics

| Metric | Value |
|---|---:|
| Task success | ${RESULT} |
| Human intervention | TODO |
| Verification attempts | 1 |
| Self repair iterations | TODO |
| Architecture violations | TODO |
| Regression failures | TODO |
| Duration seconds | ${DURATION} |

## Notes

Add manual observations here.

EOF_REPORT

echo
echo "=============================================="
echo "Evaluation Result"
echo "=============================================="
echo "Evaluation : $EVALUATION"
echo "Result     : $RESULT"
echo "Duration   : ${DURATION}s"
echo "Report     : $REPORT_FILE"
echo "=============================================="

if [ "$RESULT" != "PASS" ]; then
  exit 1
fi
