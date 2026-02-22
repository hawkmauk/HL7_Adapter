#!/usr/bin/env python3
"""
MLLP Emitter — standalone demo tool that sends HL7 messages over MLLP to the
adapter's listener. Sends on a fixed interval with randomised content and
~10% invalid messages to exercise adapter error handling.

Usage:
  python3 emit.py [--host HOST] [--port PORT] [--interval SEC] [--invalid-rate R]
                  [--count N] [--duration SEC] [--verbose]
"""

import argparse
import random
import socket
import sys
import time
from datetime import datetime
from pathlib import Path

# Allow running from repo root: python3 tests/mllpemitter/emit.py
_SCRIPT_DIR = Path(__file__).resolve().parent
if str(_SCRIPT_DIR) not in sys.path:
    sys.path.insert(0, str(_SCRIPT_DIR))

from hl7_gen import build_valid_hl7, get_random_invalid_hl7

# MLLP framing (must match adapter: 0x0B start, 0x1C 0x0D end)
MLLP_START = 0x0B
MLLP_END_FIRST = 0x1C
MLLP_END_SECOND = 0x0D

# Invalid MLLP frame variants for "invalid frame" case
INVALID_FRAME_WRONG_START = 0x00  # wrong start byte
# Partial frame = start + payload but no end bytes (adapter waits or times out / fails)


def frame_mllp(payload: str) -> bytes:
    """Wrap HL7 payload in MLLP frame: 0x0B + payload + 0x1C 0x0D."""
    raw = payload.encode("utf-8")
    return bytes([MLLP_START]) + raw + bytes([MLLP_END_FIRST, MLLP_END_SECOND])


def make_invalid_frame_wrong_start(payload: str) -> bytes:
    """Send payload with wrong start byte so adapter reports 'no start block found'."""
    raw = payload.encode("utf-8")
    return bytes([INVALID_FRAME_WRONG_START]) + raw + bytes([MLLP_END_FIRST, MLLP_END_SECOND])


def make_invalid_frame_no_end(payload: str) -> bytes:
    """Send start + payload only (no end bytes). Adapter may fail with invalid end block or timeout."""
    raw = payload.encode("utf-8")
    return bytes([MLLP_START]) + raw


def make_invalid_frame_random(payload: str) -> bytes:
    """Return one of the invalid MLLP frame variants."""
    return random.choice([
        lambda: make_invalid_frame_wrong_start(payload),
        lambda: make_invalid_frame_no_end(payload),
    ])()


def _connect_target(host: str, port: int) -> tuple[str, int]:
    """Resolve host for IPv4. Use 127.0.0.1 for 'localhost' to avoid IPv6 (::1) when listener is IPv4-only."""
    if host in ("localhost", "localhost."):
        return ("127.0.0.1", port)
    return (host, port)


def connect_with_retry(
    host: str, port: int, verbose: bool, max_attempts: int = 30
) -> tuple[socket.socket | None, Exception | None]:
    """Connect to host:port; retry with backoff. Returns (socket or None, last_error)."""
    target_host, target_port = _connect_target(host, port)
    last_error: Exception | None = None
    for attempt in range(max_attempts):
        try:
            sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            sock.settimeout(10.0)
            sock.connect((target_host, target_port))
            if verbose:
                print(f"Connected to {target_host}:{target_port}", file=sys.stderr)
            return (sock, None)
        except (ConnectionRefusedError, OSError) as e:
            last_error = e
            if verbose:
                print(f"Connection attempt {attempt + 1}/{max_attempts} failed: {e}", file=sys.stderr)
            if attempt < max_attempts - 1:
                time.sleep(1.0 + attempt * 0.5)
    return (None, last_error)


def send_one(sock: socket.socket, data: bytes, verbose: bool) -> None:
    """Send one MLLP message; optionally read response (ACK/NAK)."""
    try:
        sock.sendall(data)
        # Adapter may send back ACK or NAK; read a small buffer to avoid blocking forever
        sock.settimeout(2.0)
        try:
            reply = sock.recv(4096)
            if verbose and reply:
                print(f"  <- response: {len(reply)} bytes", file=sys.stderr)
        except socket.timeout:
            pass
        finally:
            sock.settimeout(10.0)
    except (BrokenPipeError, ConnectionResetError, OSError) as e:
        if verbose:
            print(f"  send/recv error: {e}", file=sys.stderr)
        raise


def run(
    host: str,
    port: int,
    interval: float,
    invalid_rate: float,
    count: int | None,
    duration: float | None,
    verbose: bool,
) -> None:
    """Main send loop."""
    target_host, target_port = _connect_target(host, port)
    print(f"Sending to {target_host}:{target_port}", file=sys.stderr)

    sent = 0
    invalid_count = 0
    start_time = time.monotonic()

    while True:
        if count is not None and sent >= count:
            if verbose:
                print(f"Reached count {count}, exiting.", file=sys.stderr)
            break
        if duration is not None and (time.monotonic() - start_time) >= duration:
            if verbose:
                print(f"Reached duration {duration}s, exiting.", file=sys.stderr)
            break

        sock, last_error = connect_with_retry(host, port, verbose)
        if sock is None:
            target_host, target_port = _connect_target(host, port)
            err = f" Last error: {last_error}." if last_error else ""
            print(
                "Could not connect to {}:{}.{}\n"
                "Check that the application is listening on this port and interface "
                "(e.g. bindHost 0.0.0.0 or 127.0.0.1). Try --verbose for per-attempt errors.".format(
                    target_host, target_port, err
                ),
                file=sys.stderr,
            )
            sys.exit(1)

        try:
            is_invalid = random.random() < invalid_rate
            if is_invalid:
                invalid_count += 1
                # Either invalid HL7 in correct frame, or valid-looking HL7 in broken frame
                if random.random() < 0.5:
                    payload = get_random_invalid_hl7()
                    data = frame_mllp(payload)  # valid frame, bad HL7
                    frame_ok = True
                else:
                    payload = build_valid_hl7()  # good HL7
                    data = make_invalid_frame_random(payload)  # bad frame
                    frame_ok = False
                if verbose:
                    print(f"  [{sent + 1}] sending invalid message ({len(data)} bytes)", file=sys.stderr)
            else:
                payload = build_valid_hl7()
                data = frame_mllp(payload)
                frame_ok = True
                if verbose:
                    print(f"  [{sent + 1}] sending valid message ({len(data)} bytes)", file=sys.stderr)

            # Console output: timestamp and message payload so we can track what and when was sent
            ts = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
            kind = "invalid" if is_invalid else "valid"
            if is_invalid and not frame_ok:
                kind = "invalid (bad MLLP frame)"
            # Show payload as single line (replace \r with space for readability)
            payload_line = payload.replace("\r", " ").strip()
            print(f"[{ts}] ({kind}) {payload_line}")

            send_one(sock, data, verbose)
            sent += 1
        except (BrokenPipeError, ConnectionResetError, OSError):
            if verbose:
                print("Connection lost; will reconnect on next iteration.", file=sys.stderr)
        finally:
            try:
                sock.close()
            except OSError:
                pass

        if count is not None and sent >= count:
            break
        if duration is not None and (time.monotonic() - start_time) >= duration:
            break
        time.sleep(interval)

    if verbose:
        print(f"Sent {sent} messages ({invalid_count} invalid).", file=sys.stderr)


def main() -> None:
    parser = argparse.ArgumentParser(
        description="MLLP Emitter: send HL7 messages over MLLP to the adapter for demos and testing.",
    )
    parser.add_argument("--host", default="localhost", help="Adapter MLLP listener host (default: localhost)")
    parser.add_argument("--port", type=int, default=2575, help="Adapter MLLP listener port (default: 2575)")
    parser.add_argument("--interval", type=float, default=5.0, help="Seconds between messages (default: 5)")
    parser.add_argument("--invalid-rate", type=float, default=0.1, help="Fraction of messages that are invalid (default: 0.1)")
    parser.add_argument("--count", type=int, default=None, help="Exit after sending N messages")
    parser.add_argument("--duration", type=float, default=None, help="Exit after D seconds")
    parser.add_argument("--verbose", "-v", action="store_true", help="Log to stderr")
    args = parser.parse_args()

    if args.count is None and args.duration is None:
        if args.verbose:
            print("Running indefinitely (use --count N or --duration D to limit). Ctrl+C to stop.", file=sys.stderr)

    run(
        host=args.host,
        port=args.port,
        interval=args.interval,
        invalid_rate=args.invalid_rate,
        count=args.count,
        duration=args.duration,
        verbose=args.verbose,
    )


if __name__ == "__main__":
    main()
