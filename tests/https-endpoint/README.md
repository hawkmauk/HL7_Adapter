# Demo HTTPS endpoint

A **simple HTTPS server** that receives the JSON payloads the adapter’s **HTTPForwarder** posts. It is used for **demos and manual testing** and is **not** part of the SysML/PIM/PSM model. It allows you to run the full path: HL7 (MLLP) → adapter → transform → **HTTPS POST** with TLS.

**For demo/local use only.** Do not use in production. Use a self-signed certificate; the adapter must be configured to allow it (see below).

## What it does

- Listens on **HTTPS** (TLS) on a configurable host/port (default `0.0.0.0:8080`).
- Accepts **POST** at **`/api/v1/messages`** with `Content-Type: application/json` and JSON body (the same shape the HTTPForwarder sends: e.g. `messageType`, `messageControlId`, demographics).
- Returns **200** with a small JSON body so the adapter sees delivery success.
- Logs each received payload to the console and can append to a file (e.g. `received.jsonl`) for demo visibility.
- **GET `/api/v1/received/<message_id>`** — Returns the last received payload whose `messageControlId` (or `message_id`) matches. Used by the dashboard so you can click a message and view the JSON that was sent. Payloads are kept in memory (last 500). CORS is enabled so the dashboard can call this from another origin.

## Requirements

- **Python 3**
- **OpenSSL** (for generating the self-signed cert; or use the manual command below)

## Self-signed certificate

Generate a key and certificate once (e.g. in this directory):

```bash
cd tests/demo-https-endpoint
python3 gen_cert.py
```

This creates `demo-crt.pem` and `demo-key.pem` (CN=localhost, valid 365 days). If `openssl` is not installed, run manually:

```bash
openssl req -x509 -newkey rsa:2048 -keyout demo-key.pem -out demo-crt.pem -days 365 -nodes -subj /CN=localhost
```

**Do not use these certs in production.**

## How to run

From the project root:

```bash
python3 tests/demo-https-endpoint/server.py
```

Or from this directory (after generating the cert):

```bash
cd tests/demo-https-endpoint
python3 server.py
```

### Options

| Option | Default | Description |
|--------|---------|-------------|
| `--host` | `0.0.0.0` | Bind address. |
| `--port` | `8080` | Bind port. |
| `--cert` | `demo-crt.pem` | TLS certificate file. |
| `--key` | `demo-key.pem` | TLS key file. |
| `--log-file` | — | Append each JSON payload to this file (e.g. `received.jsonl`). |

### Example with log file

```bash
python3 tests/demo-https-endpoint/server.py --log-file received.jsonl
```

## URL for the adapter

Use this as the adapter’s **HTTPForwarder base URL** in `config.json`:

- **`https://localhost:8080/api/v1/messages`** (default port 8080, path `/api/v1/messages`)

Because the endpoint uses a **self-signed certificate**, you must set **`httpForwarder.tlsRejectUnauthorized`** to **`0`** in `config.json` for the adapter to accept the cert. **Do this only for demo/local; never in production.**

## Full demo flow

1. **Generate the cert** (once):  
   `python3 tests/demo-https-endpoint/gen_cert.py`

2. **Start the demo HTTPS endpoint**:  
   `python3 tests/demo-https-endpoint/server.py`  
   (Leave it running; it will print the URL to use.)

3. **Configure the adapter** in `out/typescript/config.json`:
   - `httpForwarder.baseUrl` = `https://localhost:8080/api/v1/messages`
   - `httpForwarder.tlsRejectUnauthorized` = `0` (demo only)

4. **Start the adapter**:  
   `cd out/typescript && npm run start`

5. **Start the MLLP emitter**:  
   `python3 tests/mllpemitter/emit.py`

6. **Observe** JSON payloads in the demo endpoint’s console (and in `received.jsonl` if you used `--log-file`). You can also check adapter health/metrics at `http://localhost:3000/health` and `http://localhost:3000/metrics`.

## File layout

- **`server.py`** — HTTPS server entrypoint; POST handler, optional file logging.
- **`gen_cert.py`** — Generates `demo-crt.pem` and `demo-key.pem` (requires OpenSSL).
- **`README.md`** — This file.

No dependency on `out/typescript` or the SysML model.
