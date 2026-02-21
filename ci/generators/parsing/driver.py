"""Top-level entry point: parse_model_directory."""
from __future__ import annotations

from pathlib import Path

from ..errors import ParsingError
from .elements import _extract_elements, _resolve_qualified_names
from .model import ModelElement, ModelIndex
from .nested import (
    _extract_action_usages,
    _extract_inline_states,
    _extract_nested_parts,
    _extract_package_part_usages,
    _extract_signal_defs,
    _extract_state_defs,
)
from .regex import ID_DECL_RE


def parse_model_directory(model_dir: Path) -> ModelIndex:
    files = sorted(model_dir.rglob("*.sysml"))
    if not files:
        raise ParsingError(f"No .sysml files found in {model_dir}")

    all_elements: list[ModelElement] = []
    declared_ids: dict[str, list[Path]] = {}
    for file_path in files:
        text = file_path.read_text(encoding="utf-8")
        block_elements = _extract_elements(file_path, text)
        all_elements.extend(block_elements)
        block_names = {e.name for e in block_elements}
        for sig in _extract_signal_defs(file_path, text):
            if sig.name not in block_names:
                all_elements.append(sig)
        for act in _extract_action_usages(file_path, text):
            if act.name not in block_names:
                all_elements.append(act)
        for sd in _extract_state_defs(file_path, text):
            if sd.name not in block_names:
                all_elements.append(sd)
        for match in ID_DECL_RE.finditer(text):
            symbol = match.group("name")
            declared_ids.setdefault(symbol, []).append(file_path)

    _resolve_qualified_names(all_elements)
    nested: list[ModelElement] = []
    for element in all_elements:
        nested.extend(_extract_nested_parts(element))
    for element in all_elements:
        if element.kind == "package":
            for part_usage in _extract_package_part_usages(element):
                part_usage.qualified_name = element.qualified_name + "::" + part_usage.name
                nested.append(part_usage)
    for element in all_elements:
        children = _extract_inline_states(element)
        existing_qnames = {e.qualified_name for e in all_elements} | {e.qualified_name for e in nested}
        for child in children:
            if child.qualified_name not in existing_qnames:
                nested.append(child)
                existing_qnames.add(child.qualified_name)
    all_elements.extend(nested)
    all_elements.sort(key=lambda e: (str(e.file_path), e.start_index))

    by_qname: dict[str, ModelElement] = {}
    by_name: dict[str, list[ModelElement]] = {}
    by_short_name: dict[str, list[ModelElement]] = {}
    for element in all_elements:
        by_qname[element.qualified_name] = element
        by_name.setdefault(element.name, []).append(element)
        if element.short_name:
            by_short_name.setdefault(element.short_name, []).append(element)
            by_name.setdefault(element.short_name, []).append(element)

    alias_map: dict[str, str] = {}
    for element in all_elements:
        if element.kind == "package" and element.aliases:
            for alias_name, target_name in element.aliases:
                logical = f"{element.qualified_name}::{alias_name}"
                alias_map[logical] = target_name

    return ModelIndex(
        files=files,
        elements=all_elements,
        by_qualified_name=by_qname,
        by_name=by_name,
        by_short_name=by_short_name,
        declared_ids=declared_ids,
        alias_map=alias_map,
    )
