#!/usr/bin/env bash

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

cd "$ROOT/backend"

echo "Running integration tests..."

if [[ -f "./mvnw" ]]; then

    chmod +x ./mvnw

    ./mvnw test \
        -Dgroups=integration

elif [[ -f "pom.xml" ]]; then

    mvn test \
        -Dgroups=integration

else

    echo "ERROR: Maven project not found."
    exit 1

fi

echo
echo "Integration tests OK."
