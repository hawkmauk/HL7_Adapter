# Demo image: HL7 Adapter + dashboard + MLLP emitter + HTTPS endpoint.
# Build context must include built out/typescript (dist/, config.json) and tests/.
# Build in CI after generating and building the TypeScript adapter.

FROM node:20-bookworm-slim

# Python for emitter and HTTPS endpoint (stdlib only; bookworm has python3)
RUN apt-get update && apt-get install -y --no-install-recommends python3 && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Adapter: package.json, lockfile if present, config, and built dist (preserve dist/ subdir)
COPY out/typescript/package*.json out/typescript/config.json ./adapter/
COPY out/typescript/dist ./adapter/dist
RUN cd adapter && npm ci --omit=dev 2>/dev/null || npm install --omit=dev

# Dashboard (static + npx serve at runtime)
COPY tests/dashboard-frontend ./dashboard/

# MLLP emitter and HTTPS endpoint (Python)
COPY tests/mllp-emitter ./emitter/
COPY tests/https-endpoint ./endpoint/

# Entrypoint that starts all services
COPY scripts/docker-demo-entrypoint.sh /app/scripts/
RUN chmod +x /app/scripts/docker-demo-entrypoint.sh

EXPOSE 3000 2575 8080 8081

ENTRYPOINT ["/app/scripts/docker-demo-entrypoint.sh"]
