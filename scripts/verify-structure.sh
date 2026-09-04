#!/usr/bin/env bash

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

echo "Checking repository structure..."

required_paths=(
"AGENTS.md"
".github"
".github/agents"
".github/instructions"
".harness"
".harness/evaluations"
".harness/tasks"
".harness/reports"
".harness/state"
"backend"
"frontend"
"infra/docker"
"docs"
"scripts"
)

for path in "${required_paths[@]}"; do
if [[ ! -e "$ROOT/$path" ]]; then
echo "FAIL: missing $path"
exit 1
fi
done

echo "PASS: repository structure"
