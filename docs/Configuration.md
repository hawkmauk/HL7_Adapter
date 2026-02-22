# Configuration

## Running the TypeScript adapter with config.json

The generated adapter reads configuration from a **`config.json`** file in the **current working directory** when you run it. The build script places a default `config.json` in `out/typescript/` and runs `npm run start` from there after tests.

### To run the adapter yourself

1. Build the TypeScript target (see [Building](Building.md)), then:
   ```bash
   cd out/typescript
   npm run start
   ```
   This runs `node dist/main.js`, which loads `config.json` from the current directory.

2. **Config file location:** The entry point resolves the path as `join(process.cwd(), 'config.json')`. So either run from `out/typescript/` (where the generator puts `config.json`), or place/copy a `config.json` in whatever directory you use as the working directory.

3. **Config shape:** `config.json` must be a JSON object with one key per component, each holding that component’s config object. Example (with RestApi listening on port 3000):

   ```json
   {
     "errorHandler": {
       "logLevel": "",
       "metricsPrefix": "",
       "deadLetterPath": "",
       "classificationTaxonomy": ""
     },
     "httpForwarder": {
       "baseUrl": "https://localhost:8080/api/v1/messages",
       "requestTimeoutMs": 5000,
       "maxRetries": 3,
       "retryBackoffMs": 1000,
       "tlsMinVersion": "TLSv1.2",
       "tlsRejectUnauthorized": 1
     },
     "mllpReceiver": {
       "bindHost": "127.0.0.1",
       "bindPort": 2575,
       "maxPayloadSize": 1048576,
       "connectionIdleTimeoutMs": 30000
     },
     "operationalStore": {
       "dialect": "sqlite",
       "path": "",
       "connectionString": ""
     },
     "parser": {
       "encodingFallback": "",
       "strictValidation": 0,
       "segmentWhitelist": ""
     },
     "restApi": {
       "listenPort": 3000
     },
     "transformer": {
       "mappingConfigPath": "",
       "jsonPrettyPrint": 0,
       "schemaValidateOutput": 0
     }
   }
   ```

   Set **`restApi.listenPort`** (e.g. `3000`) for the health and metrics HTTP server. If omitted or `0`, the server may bind to an ephemeral port. **`httpForwarder.baseUrl`** must be set to the downstream URL the adapter will POST JSON to (e.g. `https://localhost:8080/api/v1/messages` for the [demo HTTPS endpoint](../tests/https-endpoint/README.md)); if empty, the adapter will not post and will log "Failed to parse URL". Fill in other fields (e.g. `mllpReceiver.bindPort`) for your environment. **`httpForwarder.tlsRejectUnauthorized`** defaults to `1` (verify server certificates). Set to `0` only for demo/local use with self-signed certs; must not be used in production.

4. **Health and metrics:** Once the adapter is running, GET **`/health`** and **`/metrics`** on the configured host/port (e.g. `http://localhost:3000/health`). See [Rest API dashboard contract](RestApi_Dashboard_Contract.md) for the response shapes.

## Operational store and database

The adapter includes an **operational data store** for message audit (lifecycle, delivery attempts, errors). Technology choice is documented in **`model/PSM/technology_selection.sysml`** (trade study: SQLite for local dev, PostgreSQL for production).

- **SQLite (local):** Set `operationalStore.dialect` to `"sqlite"` and optionally `operationalStore.path` (e.g. `"./data/store.db"`). If `path` is omitted or empty, the store uses an in-memory database. Tables are created automatically on first run.
- **Initialize schema only (SQLite):** The TypeScript generator copies `scripts/init-db.ts` from `ci/generators/templates/typescript/` into the TypeScript output (e.g. `out/typescript/scripts/init-db.ts`). From that output directory, run:
  ```bash
  cd out/typescript && npx ts-node scripts/init-db.ts [path]
  ```
  Default path is `./data/store.db` or `STORE_PATH` env. For PostgreSQL, use your migration tool or run the adapter once (schema creation is dialect-aware in the component).

## Demo and testing tools

- **MLLP Emitter** ([tests/mllp-emitter](../tests/mllp-emitter/)) sends HL7 messages over MLLP to the adapter on a configurable interval, with randomised content and a small fraction of invalid messages to exercise error handling. See [tests/mllp-emitter/README.md](../tests/mllp-emitter/README.md).
- **Demo HTTPS endpoint** ([tests/https-endpoint](../tests/https-endpoint/)) is a simple HTTPS server that receives the JSON payloads the adapter’s HTTPForwarder posts. Use it with a self-signed cert to run the full path: HL7 (MLLP) → adapter → transform → HTTPS POST. See [tests/https-endpoint/README.md](../tests/https-endpoint/README.md) for cert generation, how to start the server, and the full demo flow (endpoint, adapter config with `tlsRejectUnauthorized: 0` for demo, adapter, MLLP emitter).
- **Dashboard** ([tests/dashboard-frontend](../tests/dashboard-frontend/)) is a static dashboard served alongside the demo; see the Docker entrypoint or [Building](Building.md) for running the full demo.
