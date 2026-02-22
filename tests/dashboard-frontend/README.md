# Dashboard frontend

A **static frontend** that polls the HL7 Adapter RestAPI and displays an operational dashboard: health, metrics, last 10 delivered messages, and last 10 errors. It lives in the tests folder for demos and manual testing and is **not** part of the SysML model.

## What it does

- **Health** — GET /health: aggregate status (ready/degraded) and per-component status.
- **Metrics** — GET /metrics: message-flow and error counters from `components.errorHandler` (messages_received, messages_parsed, messages_transformed, messages_delivered, errors_total, and per-class error counts).
- **Last 10 messages** — GET /messages; shows message_id, status, received_at, message_type, control_id (sorted by received_at, most recent first).
- **Last 10 errors** — GET /errors; shows id, message_id, error_class, detail, timestamp (sorted by timestamp, most recent first).

Polling runs at a configurable interval. On connection failure, the UI shows the last known data and an error banner.

## Requirements

- A browser (no build step).
- The adapter RestAPI running (e.g. `http://localhost:3000`). See [RestApi_Dashboard_Contract.md](../../docs/RestApi_Dashboard_Contract.md).

## Configuration

- **baseUrl** — RestAPI base URL of the adapter (e.g. `http://localhost:3000`).
- **pollIntervalSeconds** — Seconds between polls (e.g. 5–10).
- **payloadBaseUrl** — (Optional) Base URL of the HTTPS endpoint that receives the adapter’s POSTs (e.g. `https://localhost:8080`). When set, clicking a message row fetches and shows the JSON payload that was sent to that endpoint (via GET `/api/v1/received/:message_id`). The test server in `tests/https-endpoint/` exposes this endpoint.

Edit **`config.json`** in this directory:

```json
{
  "baseUrl": "http://localhost:3000",
  "pollIntervalSeconds": 5,
  "payloadBaseUrl": "https://localhost:8080"
}
```

Alternatively, set `window.DASHBOARD_CONFIG` before the script loads (e.g. in a small inline script in `index.html`):

```html
<script>
  window.DASHBOARD_CONFIG = { baseUrl: 'http://localhost:3000', pollIntervalSeconds: 10 };
</script>
<script src="dashboard.js"></script>
```

## How to run

The dashboard is **static HTML and JavaScript** — there is no app to run, only files to serve. Because it uses `fetch()` to call the API, open it via an HTTP URL (opening `index.html` as `file://` will fail for cross-origin requests). Use any static file server to serve the `tests/dashboard-frontend` directory, then open the page in a browser.

**Examples:**

- **Node (npx):**  
  `cd tests/dashboard-frontend && npx -y serve -l 8081`  
  Then open **http://localhost:8081**

- **Python (built-in):**  
  `cd tests/dashboard-frontend && python3 -m http.server 8081`  
  Then open **http://localhost:8081**

- **From repo root:**  
  Run your static server from the project root and open  
  **http://localhost:&lt;port&gt;/tests/dashboard-frontend/**

Set `baseUrl` in `config.json` to your adapter (e.g. `http://localhost:3000`).

## CORS

If the dashboard is served from a different origin than the adapter (e.g. dashboard on port 8081, API on 3000), the RestAPI must allow the dashboard origin. Configure CORS on the adapter if needed so the browser allows the requests.

## File layout

- **index.html** — Single-page layout: health, metrics, messages table, errors table.
- **dashboard.js** — Loads config, polls /health, /metrics, /messages, /errors, renders tables, handles errors.
- **config.json** — Default baseUrl and pollIntervalSeconds.
- **README.md** — This file.
