#!/usr/bin/env bash

set -euo pipefail

echo "== Frontend verification =="

if [ -f "frontend/package.json" ]; then
    cd frontend

    npm run lint
    npm run test
    npm run build
else
    echo "Frontend project not initialized yet; skipping frontend build."
fi
