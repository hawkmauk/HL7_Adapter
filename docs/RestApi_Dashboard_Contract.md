# RestApi dashboard data contract

The HL7 Adapter exposes REST endpoints for health and metrics. This document defines the guaranteed JSON shape for dashboard consumers.

**Base URL:** `http://<host>:<listenPort>` (default port 3000; set via RestApi config `listenPort`).

### cURL examples

Assume the adapter is running on `localhost` with RestApi `listenPort` 3000.

**Health (overall and per-component status):**

```bash
curl -s http://localhost:3000/health | jq
```

**Metrics (message-flow and error counters):**

```bash
curl -s http://localhost:3000/metrics | jq
```

**Message status (query list, optional filters):**

```bash
curl -s "http://localhost:3000/messages?status=received&since=2025-01-01T00:00:00Z" | jq
```

**Single message by ID:**

```bash
curl -s http://localhost:3000/messages/msg-123 | jq
```

**Error history (optional filters):**

```bash
curl -s "http://localhost:3000/errors?since=2025-01-01T00:00:00Z&message_id=msg-123" | jq
```

**Unknown route (expect 404):**

```bash
curl -s -o /dev/null -w "%{http_code}" http://localhost:3000/unknown
# outputs: 404
```

Without `jq`, omit `| jq` to see raw JSON.

---

## GET /health

**Response:** `200 OK`, `Content-Type: application/json`

**Guaranteed fields:**

| Field        | Type   | Description |
|-------------|--------|-------------|
| `status`    | `'ready' \| 'degraded'` | Aggregate status. `degraded` if any critical component (e.g. ErrorHandler) reports an issue. |
| `components`| object | Per-component status. Keys: `errorHandler`, `mllpReceiver`, `parser`, `transformer`, `httpForwarder`, `restApi`. |

**Component status shape (where available):**

- `errorHandler`: `{ status: 'ready' | 'degraded', lastError?: string }`
- Other components (`mllpReceiver`, `parser`, `transformer`, `httpForwarder`, `restApi`): `{ status: string }` — the component’s current state machine state (e.g. `'Idle'`, `'Serving'`, `'Initializing'`, `'Parsing'`).

---

## GET /metrics

**Response:** `200 OK`, `Content-Type: application/json`

**Guaranteed structure:** Nested under `components.errorHandler` (and future components as they expose metrics).

**ErrorHandler metrics (all numbers, default 0):**

| Field                        | Type   | Description |
|-----------------------------|--------|-------------|
| `errors_total`              | number | Total integration errors. |
| `errors_parse_error`         | number | Count for ParseError. |
| `errors_validation_error`   | number | Count for ValidationError. |
| `errors_connection_error`  | number | Count for ConnectionError. |
| `errors_timeout_error`     | number | Count for TimeoutError. |
| `errors_http_client_error` | number | Count for HTTPClientError. |
| `errors_http_server_error`  | number | Count for HTTPServerError. |
| `messages_received`        | number | MLLP frames received. |
| `messages_parsed`          | number | Messages parsed successfully. |
| `messages_transformed`     | number | Messages transformed. |
| `messages_delivered`       | number | Messages delivered (HTTP 2xx). |

---

## GET /messages

**Response:** `200 OK`, `Content-Type: application/json`

**Query parameters (optional):** `status` (filter by lifecycle status), `since` (ISO timestamp, filter by `received_at`).

**Body:** Array of message status objects: `{ message_id, status, received_at, message_type?, control_id? }`. Supports message lifecycle tracking (received, parsed, transformed, delivered, failed).

---

## GET /messages/:id

**Response:** `200 OK` with one message status object, or **404** if not found.

**Body:** `{ message_id, status, received_at, message_type?, control_id? }`.

---

## GET /errors

**Response:** `200 OK`, `Content-Type: application/json`

**Query parameters (optional):** `since` (ISO timestamp), `message_id` (filter by message).

**Body:** Array of error records: `{ id, message_id, error_class, detail, timestamp }`.

---

## Other routes

- **GET** or **POST** to any path other than `/health`, `/metrics`, `/messages`, `/messages/:id`, and `/errors`: **404** (no body).

---

## Optional: combined endpoint

A single **GET /api/status** (or **GET /api/dashboard**) that returns both health and metrics may be added in a follow-on; until then, clients should call `/health` and `/metrics` separately.
