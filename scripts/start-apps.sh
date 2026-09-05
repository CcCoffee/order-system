#!/usr/bin/env bash

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

cd "$ROOT"

if ! command -v mvn >/dev/null 2>&1; then
    echo "FAIL: Maven (mvn) is not installed."
    exit 1
fi

if ! command -v npm >/dev/null 2>&1; then
    echo "FAIL: Node.js / npm is not installed."
    exit 1
fi

if [[ ! -d "$ROOT/frontend/node_modules" ]]; then
    echo "FAIL: frontend/node_modules does not exist."
    echo "Run 'npm ci' inside frontend/."
    exit 1
fi

# Application ports
#   backend  : Spring Boot order-service -> 8083
#   frontend : Vite dev server           -> 5173
BACKEND_PORT=8083
FRONTEND_PORT=5173
BACKEND_URL="http://localhost:$BACKEND_PORT/api/health"
FRONTEND_URL="http://localhost:$FRONTEND_PORT"

BACKEND_LOG="/tmp/order-system-backend.log"
FRONTEND_LOG="/tmp/order-system-frontend.log"

echo "Starting local application processes..."
echo

is_listening() {
    # Only treat the app as running when something actually LISTENs,
    # ignoring established client connections that happen to touch the port.
    lsof -ti tcp:"$1" -sTCP:LISTEN >/dev/null 2>&1
}

wait_for_url() {
    local url="$1"
    local name="$2"
    local tries="${3:-60}"
    local i
    for (( i = 0; i < tries; i++ )); do
        if curl -sf "$url" >/dev/null 2>&1; then
            echo "$name is ready: $url"
            return 0
        fi
        sleep 1
    done
    echo "WARN: $name did not become ready within ${tries}s."
    return 1
}

# ---------------------------------------------------------------------------
# Backend (Spring Boot order-service -> 8083)
# ---------------------------------------------------------------------------
if is_listening "$BACKEND_PORT"; then
    echo "Backend already running on port $BACKEND_PORT. Skipping."
else
    echo "Starting backend (Spring Boot order-service, port $BACKEND_PORT)..."
    (
        cd "$ROOT/backend/order-service" || exit 1
        nohup mvn -q spring-boot:run > "$BACKEND_LOG" 2>&1 &
    )
    wait_for_url "$BACKEND_URL" "Backend" 90 || true
fi

# ---------------------------------------------------------------------------
# Frontend (Vite dev server -> 5173)
# ---------------------------------------------------------------------------
if is_listening "$FRONTEND_PORT"; then
    echo "Frontend already running on port $FRONTEND_PORT. Skipping."
else
    echo "Starting frontend (Vite dev server, port $FRONTEND_PORT)..."
    (
        cd "$ROOT/frontend" || exit 1
        nohup npm run dev > "$FRONTEND_LOG" 2>&1 &
    )
    wait_for_url "$FRONTEND_URL" "Frontend" 60 || true
fi

echo
echo "Backend log : $BACKEND_LOG"
echo "Frontend log: $FRONTEND_LOG"
echo
echo "Application processes started."
