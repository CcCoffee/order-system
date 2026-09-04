#!/usr/bin/env bash

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

cd "$ROOT/backend"

echo "Checking architecture..."

if [[ -f "./mvnw" ]]; then
    ./mvnw test -Dgroups=architecture
    exit 0
fi

if [[ -f "pom.xml" ]]; then
    mvn test -Dgroups=architecture
    exit 0
fi

echo "ERROR: Backend Maven project not found."
exit 1
