#!/usr/bin/env python3
"""
Demo HTTPS endpoint that receives JSON payloads posted by the adapter's HTTPForwarder.
Accepts POST with application/json, returns 200, optionally logs or appends to a file.
For demo/local use only; run with a self-signed cert (see README).
"""

import argparse
import json
import ssl
import sys
from datetime import datetime
from pathlib import Path
from http.server import HTTPServer, BaseHTTPRequestHandler

# Default cert/key next to this script (after running gen_cert.py)
SCRIPT_DIR = Path(__file__).resolve().parent
DEFAULT_CRT = SCRIPT_DIR / "demo-crt.pem"
DEFAULT_KEY = SCRIPT_DIR / "demo-key.pem"


class DemoPOSTHandler(BaseHTTPRequestHandler):
    """Handle POST only; log payload and optionally append to file."""

    log_to_file: Path | None = None

    def _log_connection(self, method: str, extra: str = "") -> None:
        ts = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        host, port = self.client_address
        msg = f"[{ts}] connection from {host}:{port} {method} {self.path}"
        if extra:
            msg += f" {extra}"
        print(msg, file=sys.stderr)

    def do_POST(self) -> None:
        self._log_connection("POST")
        content_type = self.headers.get("Content-Type", "")
        if "application/json" not in content_type:
            self.send_response(400, "Bad Request")
            self.send_header("Content-Type", "text/plain")
            self.end_headers()
            self.wfile.write(b"Content-Type must be application/json\n")
            return
        length = int(self.headers.get("Content-Length", 0))
        try:
            body = self.rfile.read(length).decode("utf-8")
            payload = json.loads(body)
        except (ValueError, json.JSONDecodeError):
            self.send_response(400, "Bad Request")
            self.send_header("Content-Type", "text/plain")
            self.end_headers()
            self.wfile.write(b"Invalid JSON\n")
            return

        ts = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        print(f"[{ts}] POST {self.path} <- {json.dumps(payload)[:200]}...", file=sys.stderr)

        if self.log_to_file:
            with open(self.log_to_file, "a", encoding="utf-8") as f:
                f.write(json.dumps(payload) + "\n")

        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.end_headers()
        self.wfile.write(json.dumps({"received": True}).encode("utf-8"))

    def do_GET(self) -> None:
        self._log_connection("GET", "(405 Method Not Allowed)")
        self.send_error(405, "Method Not Allowed")

    def log_message(self, format: str, *args: object) -> None:
        # Suppress default request log; we log in do_POST
        pass


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Demo HTTPS endpoint for adapter HTTPForwarder POSTs (demo use only).",
    )
    parser.add_argument("--host", default="0.0.0.0", help="Bind host (default: 0.0.0.0)")
    parser.add_argument("--port", type=int, default=8443, help="Bind port (default: 8443)")
    parser.add_argument("--cert", type=Path, default=DEFAULT_CRT, help="TLS certificate file (default: demo-crt.pem)")
    parser.add_argument("--key", type=Path, default=DEFAULT_KEY, help="TLS key file (default: demo-key.pem)")
    parser.add_argument("--log-file", type=Path, default=None, help="Append each JSON payload to this file (e.g. received.jsonl)")
    args = parser.parse_args()

    if not args.cert.exists() or not args.key.exists():
        print(
            f"Certificate or key not found: {args.cert}, {args.key}\n"
            "Run: python3 gen_cert.py",
            file=sys.stderr,
        )
        sys.exit(1)

    DemoPOSTHandler.log_to_file = args.log_file

    server = HTTPServer((args.host, args.port), DemoPOSTHandler)
    ctx = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
    ctx.load_cert_chain(str(args.cert), str(args.key))
    server.socket = ctx.wrap_socket(server.socket, server_side=True)

    url = f"https://localhost:{args.port}" if args.host == "0.0.0.0" else f"https://{args.host}:{args.port}"
    print(f"Demo HTTPS endpoint listening on {args.host}:{args.port}", file=sys.stderr)
    print(f"Use in adapter config: httpForwarder.baseUrl = {url}", file=sys.stderr)
    print("For demo only; do not use in production.", file=sys.stderr)

    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass
    finally:
        server.shutdown()


if __name__ == "__main__":
    main()
