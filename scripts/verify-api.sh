#!/usr/bin/env bash

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

OPENAPI="$ROOT/docs/api/openapi.yaml"

if [[ ! -f "$OPENAPI" ]]; then
echo "FAIL: $OPENAPI does not exist."
exit 1
fi

echo "OpenAPI specification exists."

if command -v npx >/dev/null 2>&1; then

if npx --yes @redocly/cli lint "$OPENAPI"; then
echo "PASS: OpenAPI lint"
exit 0
fi

echo "FAIL: OpenAPI lint failed."
exit 1
fi

echo "FAIL: npx is required for OpenAPI validation."
exit 1
