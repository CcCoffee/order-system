#!/usr/bin/env bash

set -euo pipefail

echo "================================"
echo " Backend Verification"
echo "================================"

if [ -f "./gradlew" ]; then
    ./gradlew test
else
    echo "No Gradle project detected."
    echo "Backend verification placeholder."
fi
