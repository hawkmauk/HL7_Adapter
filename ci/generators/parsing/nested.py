"""Extraction functions for nested / inline / standalone declarations."""
from __future__ import annotations

from pathlib import Path

from .elements import _line_no
from .model import ModelElement, _strip_quotes, _strip_short_name
from .regex import (
    ACTION_USAGE_RE,
    ATTR_DEF_SIGNAL_RE,
    INLINE_STATE_RE,
    PART_INLINE_RE,
    STATE_DEF_RE,
)


def _extract_signal_defs(file_path: Path, text: str) -> list[ModelElement]:
    """Extract standalone 'attribute def SignalName;' declarations (no body block)."""
    signals: list[ModelElement] = []
    for match in ATTR_DEF_SIGNAL_RE.finditer(text):
        name = match.group("name")
        start_line = _line_no(text, match.start())
        signals.append(
            ModelElement(
                kind="attribute def",
                name=name,
                short_name=None,
                file_path=file_path,
                start_index=match.start(),
                end_index=match.end(),
                start_line=start_line,
                end_line=start_line,
                body="",
            )
        )
    return signals


def _extract_action_usages(file_path: Path, text: str) -> list[ModelElement]:
    """Extract standalone 'action name : ActionDef;' declarations."""
    usages: list[ModelElement] = []
    for match in ACTION_USAGE_RE.finditer(text):
        name = match.group("name")
        action_type = match.group("type").strip()
        start_line = _line_no(text, match.start())
        usages.append(
            ModelElement(
                kind="action",
                name=name,
                short_name=None,
                file_path=file_path,
                start_index=match.start(),
                end_index=match.end(),
                start_line=start_line,
                end_line=start_line,
                body="",
                supertypes=[action_type],
            )
        )
    return usages


def _extract_inline_states(parent: ModelElement) -> list[ModelElement]:
    """Extract inline 'state StateName;' declarations from a state machine body."""
    children: list[ModelElement] = []
    if not parent.body or parent.kind != "state":
        return children
    for match in INLINE_STATE_RE.finditer(parent.body):
        name = match.group("name")
        child = ModelElement(
            kind="state",
            name=name,
            short_name=None,
            file_path=parent.file_path,
            start_index=parent.start_index + match.start(),
            end_index=parent.start_index + match.end(),
            start_line=parent.start_line,
            end_line=parent.start_line,
            body="",
            qualified_name=parent.qualified_name + "::" + name if parent.qualified_name else name,
        )
        children.append(child)
    return children


def _extract_state_defs(file_path: Path, text: str) -> list[ModelElement]:
    """Extract standalone 'state def StateName;' declarations (no body block)."""
    defs: list[ModelElement] = []
    for match in STATE_DEF_RE.finditer(text):
        name = match.group("name")
        start_line = _line_no(text, match.start())
        defs.append(
            ModelElement(
                kind="state",
                name=name,
                short_name=None,
                file_path=file_path,
                start_index=match.start(),
                end_index=match.end(),
                start_line=start_line,
                end_line=start_line,
                body="",
            )
        )
    return defs


def _extract_nested_parts(parent: ModelElement) -> list[ModelElement]:
    """Extract nested part declarations from a part block body (e.g. 'part nodeScored : ScoredX;'). Only part blocks are scanned so package bodies are not traversed (avoiding wrong qualified_name)."""
    children: list[ModelElement] = []
    if not parent.body or parent.kind != "part":
        return children
    for match in PART_INLINE_RE.finditer(parent.body):
        name = _strip_quotes(match.group("name"))
        short = _strip_short_name(match.group("short"))
        types_str = (match.group("types") or "").strip()
        supertypes = [t.strip() for t in types_str.split(",") if t.strip()]
        child = ModelElement(
            kind="part",
            name=name,
            short_name=short,
            file_path=parent.file_path,
            start_index=parent.start_index,
            end_index=parent.end_index,
            start_line=parent.start_line,
            end_line=parent.end_line,
            body="",
            qualified_name=parent.qualified_name + "::" + name if parent.qualified_name else name,
            doc="",
            supertypes=supertypes,
        )
        children.append(child)
    return children
