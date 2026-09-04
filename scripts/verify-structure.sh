#!/usr/bin/env bash

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "Checking repository structure..."

REQUIRED_FILES=(
    "AGENTS.md"
    ".github/copilot-instructions.md"
)

REQUIRED_DIRS=(
    ".github"
    ".github/agents"
    ".github/instructions"
    "docs"
    "scripts"
    ".harness"
    ".harness/evaluations"
    ".harness/tasks"
)

for file in "${REQUIRED_FILES[@]}"; do
    if [[ ! -f "$ROOT/$file" ]]; then
        echo "Missing required file: $file"
        exit 1
    fi
done

for dir in "${REQUIRED_DIRS[@]}"; do
    if [[ ! -d "$ROOT/$dir" ]]; then
        echo "Missing required directory: $dir"
        exit 1
    fi
done

echo "Repository structure OK."
