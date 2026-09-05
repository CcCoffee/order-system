#!/usr/bin/env bash

# Resolve the Frontend agent's visual verification mode.
#
# Priority (highest wins):
#   1. FRONTEND_VISUAL_MODE environment variable
#   2. .harness/config/frontend.yaml -> visual_verification.mode
#   3. default: auto
#
# Valid modes: auto | always | never
#
# Usage:
#   ./scripts/frontend-visual-mode.sh
#   FRONTEND_VISUAL_MODE=never ./scripts/frontend-visual-mode.sh

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CONFIG="$ROOT/.harness/config/frontend.yaml"

MODE="${FRONTEND_VISUAL_MODE:-}"

if [[ -z "$MODE" && -f "$CONFIG" ]]; then
  # Extract the first `mode:` value (the config file is intentionally tiny).
  MODE="$(sed -n 's/^[[:space:]]*mode:[[:space:]]*//p' "$CONFIG" | head -n 1 | tr -d '[:space:]"')"
fi

if [[ -z "$MODE" ]]; then
  MODE="auto"
fi

case "$MODE" in
  auto|always|never)
    echo "$MODE"
    exit 0
    ;;
  *)
    echo "ERROR: invalid FRONTEND_VISUAL_MODE '$MODE' (expected auto | always | never)" >&2
    exit 1
    ;;
esac
