"""Dataclasses for the model index: ModelAttribute, ModelElement, ModelIndex."""
from __future__ import annotations

from dataclasses import dataclass, field
from pathlib import Path


@dataclass(slots=True)
class ModelAttribute:
    name: str
    type: str | None


@dataclass(slots=True)
class ModelElement:
    kind: str
    name: str
    short_name: str | None
    file_path: Path
    start_index: int
    end_index: int
    start_line: int
    end_line: int
    body: str
    qualified_name: str = ""
    doc: str = ""
    expose_refs: list[str] = field(default_factory=list)
    satisfy_refs: list[str] = field(default_factory=list)
    frame_refs: list[str] = field(default_factory=list)
    render_kind: str | None = None
    supertypes: list[str] = field(default_factory=list)
    attributes: list[ModelAttribute] = field(default_factory=list)
    constants: list[tuple[str, str, str]] = field(default_factory=list)  # (name, type, value_str) for constant decls
    aliases: list[tuple[str, str]] = field(default_factory=list)  # (alias_name, target_name)
    flow_properties: list[tuple[str, str, str, str]] = field(default_factory=list)  # (direction, kind, name, type)
    interface_ends: list[tuple[str, str]] = field(default_factory=list)  # (role, port_type) for interface def
    allocation_satisfy: list[tuple[str, str]] = field(default_factory=list)  # (requirement_name, logical_block_path)
    refinement_dependencies: list[tuple[str, str]] = field(default_factory=list)  # (pim_req, cim_req)
    constraint_params: list[tuple[str, str]] = field(default_factory=list)  # (name, type) for constraint def
    value_assignments: list[float] = field(default_factory=list)  # attribute ::> value = N (order preserved)
    weight_assignments: list[float] = field(default_factory=list)  # attribute ::> weight = N (order preserved)
    transitions: list[tuple[str, str, str]] = field(default_factory=list)  # (source_state, signal, target_state)
    entry_target: str | None = None  # initial state from "entry; then X;"
    entry_action: str | None = None  # "entry actionName { ... }"
    do_action: str | None = None  # "do actionName { ... }"
    state_ports: list[tuple[str, str, str]] = field(default_factory=list)  # (dir, name, type) for in/out ports on states
    textual_representations: list[tuple[str, str, str]] = field(default_factory=list)  # (name, language, body) for named rep blocks
    perform_actions: list[tuple[str, str]] = field(default_factory=list)  # (name, type) for perform action usages
    action_params: list[tuple[str, str, str | None]] = field(default_factory=list)  # (dir, name, type) for in/out params on action defs
    verify_refs: list[str] = field(default_factory=list)  # requirement refs from objective { verify X; } in verification def
    subject_ref: tuple[str, str] | None = None  # (name, type) from subject name : Type; in verification def
    exhibit_refs: list[str] = field(default_factory=list)  # state usage names from exhibit <name>;


@dataclass(slots=True)
class ModelIndex:
    files: list[Path]
    elements: list[ModelElement]
    by_qualified_name: dict[str, ModelElement]
    by_name: dict[str, list[ModelElement]]
    by_short_name: dict[str, list[ModelElement]]
    declared_ids: dict[str, list[Path]]
    alias_map: dict[str, str] = field(default_factory=dict)  # logical path -> actual qualified name

    def get_single(self, name: str) -> ModelElement | None:
        candidates = self.by_name.get(name, [])
        if len(candidates) == 1:
            return candidates[0]
        return None


def _strip_quotes(value: str) -> str:
    if value.startswith("'") and value.endswith("'"):
        return value[1:-1]
    return value


def _strip_short_name(value: str | None) -> str | None:
    if value is None:
        return None
    clean = value.strip()
    if clean.startswith("'") and clean.endswith("'"):
        clean = clean[1:-1]
    return clean or None
