#!/usr/bin/env bash

set -euo pipefail

echo "== Backend verification =="

if [ -f "./gradlew" ]; then
    ./gradlew test
else
    echo "Gradle project not initialized yet; skipping backend build."
fi
