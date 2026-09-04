#!/usr/bin/env bash

set -euo pipefail

echo "================================"
echo " Frontend Verification"
echo "================================"

if [ -f "frontend/package.json" ]; then
    cd frontend

    npm run lint
    npm run test
    npm run build
else
    echo "No frontend package.json detected."
    echo "Frontend verification placeholder."
fi
