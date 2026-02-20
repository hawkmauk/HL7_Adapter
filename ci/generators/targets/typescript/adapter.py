"""Adapter orchestrator module generation."""
from __future__ import annotations

from ...ir import ModelGraph
from .naming import _to_camel, _to_screaming_snake
from .queries import (
    ADAPTER_STATE_MACHINE,
    COMPONENT_MAP,
    PIM_BEHAVIOR_PKG,
    _collect_states,
    _collect_transitions,
    _find_psm_node,
    _get_config_attributes,
)


def _build_adapter_module(graph: ModelGraph) -> str:
    """Generate the adapter.ts orchestrator that wires all components together."""
    machine_qname = f"{PIM_BEHAVIOR_PKG}::{ADAPTER_STATE_MACHINE}"
    states = _collect_states(graph, machine_qname)
    transitions = _collect_transitions(graph, machine_qname)
    machine_node = graph.get(machine_qname)
    initial_state = machine_node.properties.get("entry_target") if machine_node else "Idle"

    lines: list[str] = []

    imports: list[str] = []
    for comp in COMPONENT_MAP:
        module = comp["output_file"].replace(".ts", "")
        psm = _find_psm_node(graph, comp["psm_short"])
        attrs = _get_config_attributes(psm) if psm else []
        if attrs:
            imports.append(f"import {{ {comp['class_name']}, {comp['class_name']}Config }} from './{module}';")
        else:
            imports.append(f"import {{ {comp['class_name']} }} from './{module}';")
    lines.extend(imports)
    lines.append("import { EventEmitter } from 'events';")
    lines.append("import pino from 'pino';")
    lines.append("")
    lines.append("const logger = pino({ name: 'HL7Adapter' });")
    lines.append("")

    enum_name = "AdapterState"
    lines.append(f"export enum {enum_name} {{")
    for state in states:
        lines.append(f"  {_to_screaming_snake(state)} = '{state}',")
    lines.append("}")
    lines.append("")

    signal_names = sorted({t["signal"] for t in transitions})
    if signal_names:
        lines.append("export type AdapterSignal =")
        for i, sig in enumerate(signal_names):
            sep = ";" if i == len(signal_names) - 1 else ""
            lines.append(f"  | '{sig}'{sep}")
        lines.append("")

    lines.append("export class HL7Adapter extends EventEmitter {")
    lines.append(f"  private _state: {enum_name};")
    for comp in COMPONENT_MAP:
        field = _to_camel(comp["class_name"])
        lines.append(f"  readonly {field}: {comp['class_name']};")
    lines.append("")

    constructor_params: list[str] = []
    for comp in COMPONENT_MAP:
        psm = _find_psm_node(graph, comp["psm_short"])
        attrs = _get_config_attributes(psm) if psm else []
        if attrs:
            constructor_params.append(f"{_to_camel(comp['class_name'])}Config: {comp['class_name']}Config")

    config_imports: list[str] = []
    for comp in COMPONENT_MAP:
        psm = _find_psm_node(graph, comp["psm_short"])
        attrs = _get_config_attributes(psm) if psm else []
        if attrs:
            config_imports.append(f"{comp['class_name']}Config")

    param_str = ", ".join(constructor_params) if constructor_params else ""
    lines.append(f"  constructor({param_str}) {{")
    lines.append("    super();")
    lines.append(f"    this._state = {enum_name}.{_to_screaming_snake(initial_state or 'Idle')};")
    for comp in COMPONENT_MAP:
        field = _to_camel(comp["class_name"])
        psm = _find_psm_node(graph, comp["psm_short"])
        attrs = _get_config_attributes(psm) if psm else []
        if attrs:
            lines.append(f"    this.{field} = new {comp['class_name']}({_to_camel(comp['class_name'])}Config);")
        else:
            lines.append(f"    this.{field} = new {comp['class_name']}();")
    lines.append("  }")
    lines.append("")

    lines.append(f"  get state(): {enum_name} {{")
    lines.append("    return this._state;")
    lines.append("  }")
    lines.append("")

    if signal_names:
        lines.append("  dispatch(signal: AdapterSignal): void {")
    else:
        lines.append("  dispatch(signal: string): void {")
    lines.append("    const prev = this._state;")
    lines.append("    switch (this._state) {")

    transitions_by_source: dict[str, list[dict[str, str]]] = {}
    for t in transitions:
        transitions_by_source.setdefault(t["from_state"], []).append(t)

    for state in states:
        from_transitions = transitions_by_source.get(state, [])
        if not from_transitions:
            continue
        lines.append(f"      case {enum_name}.{_to_screaming_snake(state)}:")
        lines.append("        switch (signal) {")
        seen: set[str] = set()
        for t in from_transitions:
            if t["signal"] in seen:
                continue
            seen.add(t["signal"])
            lines.append(f"          case '{t['signal']}':")
            lines.append(f"            this._state = {enum_name}.{_to_screaming_snake(t['to_state'])};")
            lines.append("            break;")
        lines.append("          default:")
        lines.append("            break;")
        lines.append("        }")
        lines.append("        break;")

    lines.append("      default:")
    lines.append("        break;")
    lines.append("    }")
    lines.append("    if (this._state !== prev) {")
    lines.append("      logger.info({ from: prev, to: this._state, signal }, 'adapter state transition');")
    lines.append("      this.emit('transition', { from: prev, to: this._state, signal });")
    lines.append("    }")
    lines.append("  }")
    lines.append("}")
    lines.append("")
    return "\n".join(lines)
