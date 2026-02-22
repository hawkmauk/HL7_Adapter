#!/usr/bin/env bash
set -e

# Demo entrypoint: patch config, start adapter, dashboard, emitter, and HTTPS endpoint.
# All services run in the background; we then wait indefinitely.

ADAPTER_DIR=/app/adapter
CONFIG_JSON=$ADAPTER_DIR/config.json
DASHBOARD_PORT=8081

echo "=== Patching config (tlsRejectUnauthorized = 0) ==="
python3 -c "
import json, sys
path = sys.argv[1]
with open(path) as f:
    c = json.load(f)
c['httpForwarder']['tlsRejectUnauthorized'] = 0
with open(path, 'w') as f:
    json.dump(c, f, separators=(',', ':'))
" "$CONFIG_JSON"

echo "=== Starting adapter ==="
(cd "$ADAPTER_DIR" && node dist/main.js) &
ADAPTER_PID=$!

echo "=== Starting dashboard on port $DASHBOARD_PORT ==="
(cd /app/dashboard && npx -y serve -l tcp://0.0.0.0:$DASHBOARD_PORT) &
DASH_PID=$!
echo "  -> Dashboard: http://localhost:$DASHBOARD_PORT"

echo "=== Waiting 10s before starting emitter and endpoint ==="
sleep 10

echo "=== Starting MLLP emitter ==="
python3 /app/emitter/emit.py &
EMITTER_PID=$!

echo "=== Starting HTTPS endpoint ==="
python3 /app/endpoint/server.py &
ENDPOINT_PID=$!

echo "=== Demo running. Adapter REST: 3000, MLLP: 2575, Dashboard: $DASHBOARD_PORT, Endpoint: 8080 ==="

# Wait for any process to exit (e.g. adapter crash); then keep container alive so dashboard/others stay reachable
wait $ADAPTER_PID $DASH_PID $EMITTER_PID $ENDPOINT_PID 2>/dev/null || true
exec sleep infinity
