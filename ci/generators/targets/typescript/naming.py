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


def _display_name_to_class_name(display_name: str) -> str:
    """Convert a display name (e.g. 'MLLP Receiver') to TypeScript PascalCase class name (e.g. 'MllpReceiver')."""
    if not display_name:
        return ""
    return "".join(w.capitalize() for w in display_name.split())


def _action_param_type_to_ts(sysml_type: str | None) -> str:
    """Map SysML type to TypeScript for action param/return types; unknown types pass through."""
    return _sysml_type_to_ts(sysml_type, pass_through_unknown=True)


def _sysml_type_to_ts(
    sysml_type: str | None,
    *,
    pass_through_unknown: bool = False,
) -> str:
    """Map SysML type names to TypeScript.

    When pass_through_unknown is False (default), unknown types map to "string"
    (e.g. for config attributes). When True, unknown types are returned as-is
    (e.g. Buffer, ParseMllpResult for action param signatures).
    """
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
    if lowered == "buffer":
        return "Buffer"
    if pass_through_unknown:
        return clean
    return "string"