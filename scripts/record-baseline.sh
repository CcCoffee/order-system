#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

mkdir -p .harness/reports/baseline

TIMESTAMP="$(date '+%Y-%m-%d_%H-%M-%S')"
REPORT=".harness/reports/baseline/single-agent-${TIMESTAMP}.md"

START="$(date +%s)"

echo "=============================================="
echo "Single-Agent Baseline Run"
echo "=============================================="
echo

set +e
./scripts/verify.sh
EXIT_CODE=$?
set -e

END="$(date +%s)"
DURATION="$((END - START))"

if [ "$EXIT_CODE" -eq 0 ]; then
  RESULT="PASS"
else
  RESULT="FAIL"
fi

cat > "$REPORT" <<EOF_REPORT
# Single-Agent Baseline

## Run

- Timestamp: ${TIMESTAMP}
- Result: ${RESULT}
- Duration: ${DURATION}s
- Verification exit code: ${EXIT_CODE}

## Agent

- Agent: Order System Engineer
- Mode: Single-Agent

## Metrics

| Metric | Value |
|---|---:|
| Task success | ${RESULT} |
| Human intervention | TODO |
| Verification attempts | TODO |
| Self repair iterations | TODO |
| Architecture violations | TODO |
| Regression failures | TODO |
| Duration seconds | ${DURATION} |
| Token cost | TODO |

## Human Intervention

Describe whether manual intervention was required.

## Failure / Repair Log

Record:

1. Verification failure
2. Agent diagnosis
3. Fix
4. Verification result

## Conclusion

TODO

EOF_REPORT

echo
echo "Baseline result: $RESULT"
echo "Report: $REPORT"

exit "$EXIT_CODE"
