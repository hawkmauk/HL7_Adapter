# MLLP Emitter — Demo and Testing Tool

The **MLLP Emitter** is a standalone script that sends HL7 messages over MLLP (Minimal Lower Layer Protocol) to the HL7 Adapter’s listener. It is used for **demos and manual testing** and is **not** part of the SysML/PIM/PSM model or generated code.

## What it does

- **Interval**: Sends one MLLP-framed HL7 message every **5 seconds** by default (configurable).
- **Randomised content**: Each valid message has random message type (ADT^A01, ORU^R01, ORM^O01), random patient ID, name, timestamp, and optional PID segment, so each run produces varied traffic.
- **Invalid messages**: About **10%** of messages are invalid (configurable rate): either malformed HL7 (e.g. no MSH, missing MSH-9, truncated segment) or corrupt MLLP framing (wrong start/end bytes). The adapter should respond with NAK, error logging, and metrics for these.
- **MLLP framing**: Valid messages use correct MLLP framing: start byte `0x0B`, end bytes `0x1C` `0x0D`.
- **Console output**: Each message sent is printed to the console with a timestamp and the HL7 payload (valid/invalid), so you can track what was sent and when.

## Requirements

- **Python 3** (stdlib only: no pip install required).

## How to run

From the project root:

```bash
python3 tests/mllpemitter/emit.py
```

Or from this directory:

```bash
cd tests/mllpemitter
python3 emit.py
```

### Options

| Option | Default | Description |
|--------|---------|-------------|
| `--host` | `localhost` | Adapter MLLP listener host. |
| `--port` | `2575` | Adapter MLLP listener port. |
| `--interval` | `5` | Seconds between messages. |
| `--invalid-rate` | `0.1` | Fraction of messages that are invalid (0.0–1.0). |
| `--count N` | — | Exit after sending N messages. |
| `--duration D` | — | Exit after D seconds. |
| `--verbose`, `-v` | off | Log each send and connection to stderr. |

### Examples

```bash
# Default: localhost:2575, every 5 s, 10% invalid, run until Ctrl+C
python3 tests/mllpemitter/emit.py

# Send 20 messages then exit
python3 tests/mllpemitter/emit.py --count 20 --verbose

# Custom host/port and interval
python3 tests/mllpemitter/emit.py --host 192.168.1.10 --port 2575 --interval 3

# Run for 60 seconds
python3 tests/mllpemitter/emit.py --duration 60 -v
```

## Running adapter and emitter together (demos)

1. **Start the adapter** so its MLLP listener is bound to port 2575:
   - Build the TypeScript target: `./scripts/build.sh typescript`
   - Run the adapter from the generated output:
     ```bash
     cd out/typescript
     npm run start
     ```
   - Ensure `config.json` has `mllpReceiver.bindPort` set to `2575` (or the port you will use).

2. **Start the emitter** in another terminal, pointing at the same host/port:
   ```bash
   python3 tests/mllpemitter/emit.py --port 2575 --verbose
   ```

3. **Observe**:
   - Adapter logs: ACK for valid messages, NAK or parse errors for invalid ones.
   - REST dashboard: GET `http://localhost:3000/health` and `http://localhost:3000/metrics` to see message-flow and error counters (see `docs/RestApi_Dashboard_Contract.md`).

## File layout

- **`emit.py`** — Main entrypoint: CLI, connect/send loop, MLLP framing.
- **`hl7_gen.py`** — HL7 message builders (valid MSH/PID and invalid variants).
- **`README.md`** — This file.

No dependency on `out/typescript` or the SysML model; the emitter is a standalone demo tool.

### Troubleshooting: cannot connect

If the emitter cannot connect to a listener on port 2575:

1. **Use 127.0.0.1**  
   The emitter resolves `localhost` to `127.0.0.1` (IPv4). If your listener is IPv4-only, use:
   ```bash
   python3 tests/mllpemitter/emit.py --host 127.0.0.1 --port 2575 --verbose
   ```

2. **Listener binding**  
   The application must listen on an address the emitter can reach (e.g. `127.0.0.1` or `0.0.0.0`). For the HL7 Adapter, set `mllpReceiver.bindHost` in `config.json` to `"0.0.0.0"` (all interfaces) or `"127.0.0.1"` (local only). Default in the model is `"localhost"` (effectively 127.0.0.1).

3. **See the actual error**  
   Run with `--verbose` to see each connection attempt and the last error (e.g. *Connection refused*, *No route to host*).

4. **Confirm the port**  
   Ensure nothing else is using the port and that the app really is listening (e.g. `lsof -i :2575` or your OS’s equivalent).
