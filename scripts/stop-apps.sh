#!/usr/bin/env bash

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

cd "$ROOT"

echo "Stopping local application processes..."
echo

# Application ports
#   backend  : Spring Boot order-service -> 8083
#   frontend : Vite dev server           -> 5173
BACKEND_PORT=8083
FRONTEND_PORT=5173

stopped_any=0

# Stop every process that is listening on the given port.
stop_port() {
    local port="$1"
    local name="$2"
    local pids

    pids="$(lsof -ti tcp:"$port" 2>/dev/null || true)"
    if [[ -n "$pids" ]]; then
        echo "Stopping $name (port $port): $pids"
        # Intentional word splitting: $pids may hold multiple PIDs.
        # shellcheck disable=SC2086
        kill $pids 2>/dev/null || true
        stopped_any=1
    fi
}

stop_port "$BACKEND_PORT" "backend"
stop_port "$FRONTEND_PORT" "frontend"

# Fall back to process-name matching for servers that may not be listening yet.
pkill -f "spring-boot:run" 2>/dev/null || true
pkill -f "vite" 2>/dev/null || true

echo
if [[ "$stopped_any" -eq 1 ]]; then
    echo "Application processes stopped."
else
    echo "No running application processes were found."
fi
