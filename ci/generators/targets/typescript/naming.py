"""Name conversion utilities for TypeScript generation."""
from __future__ import annotations

import re


def _to_screaming_snake(name: str) -> str:
    """Convert PascalCase to SCREAMING_SNAKE_CASE for enum members."""
    s = re.sub(r"(?<=[a-z0-9])([A-Z])", r"_\1", name)
    return s.upper()


def _to_camel(name: str) -> str:
    """Ensure a name is camelCase."""
    if not name:
        return name
    return name[0].lower() + name[1:]


def _sysml_type_to_ts(sysml_type: str | None) -> str:
    if not sysml_type:
        return "string"
    clean = sysml_type.strip().split("=")[0].strip().split("{")[0].strip()
    lowered = clean.lower()
    if lowered in ("string", "str"):
        return "string"
    if lowered in ("integer", "int", "natural"):
        return "number"
    if lowered in ("boolean", "bool"):
        return "boolean"
    if lowered in ("real", "float", "double"):
        return "number"
    return "string"
