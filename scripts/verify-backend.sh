#!/usr/bin/env bash

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

cd "$ROOT/backend"

echo "Checking Spring Boot backend..."

if [[ -f "./mvnw" ]]; then

    chmod +x ./mvnw

    echo "Running Maven tests..."

    ./mvnw test

elif [[ -f "pom.xml" ]]; then

    if ! command -v mvn >/dev/null 2>&1; then
        echo "ERROR: Maven is not installed."
        exit 1
    fi

    mvn test

else

    echo "ERROR: Maven project not found."
    echo "Expected backend/pom.xml"
    exit 1

fi

echo
echo "Backend verification OK."
