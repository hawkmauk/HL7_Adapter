#!/usr/bin/env bash
set -e

# Project root (one level up from scripts/)
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
PROJECT_ROOT=$(cd "$SCRIPT_DIR/.." && pwd)
cd "$PROJECT_ROOT"

CONFIG_JSON="$PROJECT_ROOT/out/typescript/config.json"
DASHBOARD_PORT=8081

echo "=== Demo: setting tlsRejectUnauthorized to 0 in config ==="
if [ ! -f "$CONFIG_JSON" ]; then
    echo "Error: $CONFIG_JSON not found. Run the TypeScript generator and build first (e.g. scripts/build.sh typescript or build from model)." >&2
    exit 1
fi
python3 -c "
import json, sys
path = sys.argv[1]
with open(path) as f:
    c = json.load(f)
c['httpForwarder']['tlsRejectUnauthorized'] = 0
with open(path, 'w') as f:
    json.dump(c, f, separators=(',', ':'))
" "$CONFIG_JSON"
echo "Done."

echo ""
echo "=== Starting adapter (out/typescript) ==="
(cd "$PROJECT_ROOT/out/typescript" && npm run start) &
ADAPTER_PID=$!

echo ""
echo "=== Starting dashboard (tests/dashboard-frontend) ==="
(cd "$PROJECT_ROOT/tests/dashboard-frontend" && npx -y serve -l $DASHBOARD_PORT) &
DASH_PID=$!
echo "Dashboard serving at http://localhost:$DASHBOARD_PORT"
echo "  -> Open a browser to: http://localhost:$DASHBOARD_PORT"
echo ""

echo "=== Starting MLLP emitter (tests/mllp-emitter) ==="
python3 "$PROJECT_ROOT/tests/mllp-emitter/emit.py" &
EMITTER_PID=$!

echo "=== Waiting 10 seconds before starting HTTPS endpoint ==="
sleep 10

echo ""
echo "=== Starting HTTP(S) endpoint (tests/https-endpoint) ==="
python3 "$PROJECT_ROOT/tests/https-endpoint/server.py" &
ENDPOINT_PID=$!

cleanup() {
    echo ""
    echo "Stopping all services..."
    kill $ADAPTER_PID $DASH_PID $EMITTER_PID $ENDPOINT_PID 2>/dev/null || true
    exit 0
}
trap cleanup INT TERM

echo ""
echo "All services started. Press Enter to stop all and exit."
read

cleanup
