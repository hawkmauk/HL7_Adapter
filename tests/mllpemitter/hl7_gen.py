"""
HL7 message generation for the MLLP Emitter demo tool.
Produces randomised but structurally valid HL7 (MSH + optional PID)
and invalid variants for testing adapter error handling.
Uses only Python stdlib; no dependency on model-generated code.
"""

import random
from datetime import datetime

# HL7 segment terminator (carriage return)
SEG_TERM = "\r"

# Message types supported by the adapter parser
MESSAGE_TYPES = ("ADT^A01", "ORU^R01", "ORM^O01")

# Sample values for randomisation
SENDING_APPS = ("SEND", "EMR", "HIS", "LAB")
SENDING_FACILITIES = ("F1", "FAC_A", "MAIN")
RECEIVING_APPS = ("RECV", "ADAPTER", "GATEWAY")
RECEIVING_FACILITIES = ("F2", "FAC_B", "DST")
FIRST_NAMES = ("JOHN", "JANE", "BOB", "ALICE", "CAROL", "DAVE", "EVE", "FRANK")
LAST_NAMES = ("DOE", "SMITH", "PATIENT", "TEST", "JONES", "BROWN", "WILSON")


def _random_ts() -> str:
    """Return current or recent timestamp as YYYYMMDDHHMMSS."""
    return datetime.now().strftime("%Y%m%d%H%M%S")


def _random_dob() -> str:
    """Return random DOB as YYYYMMDD."""
    y = random.randint(1950, 2010)
    m = random.randint(1, 12)
    d = random.randint(1, 28)
    return f"{y:04d}{m:02d}{d:02d}"


def _random_id() -> str:
    """Return a short numeric ID for patient or message control."""
    return str(random.randint(10000, 99999))


def build_msh(
    message_type: str,
    control_id: str,
    *,
    sending_app: str | None = None,
    sending_facility: str | None = None,
    receiving_app: str | None = None,
    receiving_facility: str | None = None,
    timestamp: str | None = None,
) -> str:
    """
    Build MSH segment. Format: MSH|^~\\&|sending_app|sending_fac|recv_app|recv_fac|ts||msg_type|control_id|P|2.5\\r
    """
    sending_app = sending_app or random.choice(SENDING_APPS)
    sending_facility = sending_facility or random.choice(SENDING_FACILITIES)
    receiving_app = receiving_app or random.choice(RECEIVING_APPS)
    receiving_facility = receiving_facility or random.choice(RECEIVING_FACILITIES)
    timestamp = timestamp or _random_ts()
    return (
        f"MSH|^~\\&|{sending_app}|{sending_facility}|{receiving_app}|{receiving_facility}|"
        f"{timestamp}||{message_type}|{control_id}|P|2.5{SEG_TERM}"
    )


def build_pid(patient_id: str | None = None) -> str:
    """
    Build PID segment. Format consistent with adapter Parser verification samples.
    PID|1||id^^^HOSP^MR||family^given^middle||DOB|sex\\r
    """
    patient_id = patient_id or _random_id()
    family = random.choice(LAST_NAMES)
    given = random.choice(FIRST_NAMES)
    middle = random.choice(("A", "B", "C", ""))
    name = f"{family}^{given}^{middle}" if middle else f"{family}^{given}"
    dob = _random_dob()
    sex = random.choice(("M", "F"))
    return f"PID|1||{patient_id}^^^HOSP^MR||{name}||{dob}|{sex}{SEG_TERM}"


def build_valid_hl7(control_id: str | None = None) -> str:
    """
    Build a complete valid HL7 message (MSH + PID) with random type and fields.
    """
    msg_type = random.choice(MESSAGE_TYPES)
    ctrl_id = control_id or f"msg_{_random_id()}"
    msh = build_msh(msg_type, ctrl_id)
    pid = build_pid()
    return msh + pid


def build_invalid_no_msh() -> str:
    """Message without MSH (starts with PID). Adapter expects MSH first."""
    return f"PID|1||x{SEG_TERM}"


def build_invalid_missing_msh9() -> str:
    """MSH segment with empty MSH-9 (message type). Parser rejects 'MSH-9 message type required'."""
    return "MSH|^~\\&|S|F1|R|F2|20250101120000||\r"


def build_invalid_truncated_segment() -> str:
    """Valid MSH followed by truncated PID (no segment terminator)."""
    msg_type = random.choice(MESSAGE_TYPES)
    msh = build_msh(msg_type, f"msg_{_random_id()}")
    return msh + "PID|1||"  # no \r, truncated


def build_invalid_variants() -> list[tuple[str, str]]:
    """
    Return list of (name, payload) for invalid HL7 payloads only (no MLLP frame).
    Used when we send with broken or no MLLP frame.
    """
    return [
        ("no_msh", build_invalid_no_msh()),
        ("missing_msh9", build_invalid_missing_msh9()),
        ("truncated_segment", build_invalid_truncated_segment()),
    ]


def get_random_invalid_hl7() -> str:
    """Return one random invalid HL7 payload (content only)."""
    _, payload = random.choice(build_invalid_variants())
    return payload
