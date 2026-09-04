#!/usr/bin/env bash

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

cd "$ROOT/frontend"

echo "Checking React frontend..."

if [[ ! -f package.json ]]; then
    echo "ERROR: frontend/package.json not found."
    exit 1
fi

if [[ ! -d node_modules ]]; then
    echo "Installing frontend dependencies..."

    npm install
fi

echo
echo "Running frontend tests..."

npm test -- --run

echo
echo "Running frontend build..."

npm run build

echo
echo "Frontend verification OK."
