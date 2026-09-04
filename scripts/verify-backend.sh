#!/usr/bin/env bash

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

if [[ ! -f "$ROOT/backend/pom.xml" ]]; then
echo "SKIP: backend/pom.xml does not exist yet."
exit 0
fi

cd "$ROOT/backend"

if [[ -x "./mvnw" ]]; then
MVN="./mvnw"
else
if ! command -v mvn >/dev/null 2>&1; then
echo "FAIL: Maven is not installed and backend/mvnw does not exist."
exit 1
fi

MVN="mvn"
fi

echo "Running backend tests..."

"$MVN" test
