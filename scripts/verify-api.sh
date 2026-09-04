#!/usr/bin/env bash

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

OPENAPI_FILE="$ROOT/docs/api/openapi.yaml"

echo "Checking OpenAPI contract..."

if [[ ! -f "$OPENAPI_FILE" ]]; then
    echo "ERROR: OpenAPI specification not found:"
    echo "  $OPENAPI_FILE"
    exit 1
fi

# ------------------------------------------------------------
# Prefer Redocly CLI if available
# ------------------------------------------------------------

if command -v redocly >/dev/null 2>&1; then

    redocly lint "$OPENAPI_FILE"

    echo "OpenAPI contract OK."
    exit 0
fi

# ------------------------------------------------------------
# Fallback: basic structural validation
# ------------------------------------------------------------

if ! grep -q "^openapi:" "$OPENAPI_FILE"; then
    echo "ERROR: Missing 'openapi:' field."
    exit 1
fi

if ! grep -q "^info:" "$OPENAPI_FILE"; then
    echo "ERROR: Missing 'info:' field."
    exit 1
fi

if ! grep -q "^paths:" "$OPENAPI_FILE"; then
    echo "ERROR: Missing 'paths:' field."
    exit 1
fi

echo "OpenAPI basic validation OK."
echo "NOTE: Install Redocly CLI for full validation."
