#!/usr/bin/env python3
"""
Generate a self-signed certificate and key for the demo HTTPS endpoint.
Uses openssl (must be installed). Output: demo-crt.pem, demo-key.pem in script directory.
For demo/local use only; do not use in production.
"""

import os
import subprocess
import sys
from pathlib import Path

SCRIPT_DIR = Path(__file__).resolve().parent
CRT_PATH = SCRIPT_DIR / "demo-crt.pem"
KEY_PATH = SCRIPT_DIR / "demo-key.pem"


def main() -> None:
    if KEY_PATH.exists() and CRT_PATH.exists():
        print(f"Cert and key already exist: {CRT_PATH}, {KEY_PATH}", file=sys.stderr)
        print("Delete them and re-run to regenerate.", file=sys.stderr)
        sys.exit(0)

    # openssl req -x509 -newkey rsa:2048 -keyout key.pem -out cert.pem -days 365 -nodes -subj "/CN=localhost"
    cmd = [
        "openssl", "req", "-x509", "-newkey", "rsa:2048",
        "-keyout", str(KEY_PATH),
        "-out", str(CRT_PATH),
        "-days", "365",
        "-nodes",
        "-subj", "/CN=localhost",
    ]
    try:
        subprocess.run(cmd, check=True, capture_output=True, text=True)
    except FileNotFoundError:
        print("openssl not found. Install OpenSSL or run the following manually:", file=sys.stderr)
        print(f"  openssl req -x509 -newkey rsa:2048 -keyout {KEY_PATH} -out {CRT_PATH} -days 365 -nodes -subj /CN=localhost", file=sys.stderr)
        sys.exit(1)
    except subprocess.CalledProcessError as e:
        print(f"openssl failed: {e}", file=sys.stderr)
        sys.exit(1)

    print(f"Generated {CRT_PATH} and {KEY_PATH} (valid 365 days, CN=localhost).")
    print("For demo use only; do not use in production.")


if __name__ == "__main__":
    main()
