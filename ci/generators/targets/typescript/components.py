"""Component module generation."""
from __future__ import annotations

from ...ir import ModelGraph
from .naming import _to_screaming_snake
from .queries import PIM_BEHAVIOR_PKG, _collect_states, _collect_transitions, _find_psm_node, _get_config_attributes


def _build_component_module(
    graph: ModelGraph,
    comp: dict[str, str],
) -> str:
    """Generate the TypeScript source for a single component module."""
    psm_node = _find_psm_node(graph, comp["psm_short"])
    machine_qname = f"{PIM_BEHAVIOR_PKG}::{comp['state_machine']}"
    class_name = comp["class_name"]

    states = _collect_states(graph, machine_qname)
    transitions = _collect_transitions(graph, machine_qname)
    config_attrs = _get_config_attributes(psm_node) if psm_node else []

    machine_node = graph.get(machine_qname)
    initial_state = machine_node.properties.get("entry_target") if machine_node else None

    lines: list[str] = []
    lines.append("import { EventEmitter } from 'events';")
    lines.append("import pino from 'pino';")
    lines.append("")

    lines.append(f"const logger = pino({{ name: '{comp['class_name']}' }});")
    lines.append("")

    enum_name = f"{class_name}State"
    lines.append(f"export enum {enum_name} {{")
    for state in states:
        lines.append(f"  {_to_screaming_snake(state)} = '{state}',")
    lines.append("}")
    lines.append("")

    signal_names = sorted({t["signal"] for t in transitions})
    if signal_names:
        lines.append(f"export type {class_name}Signal =")
        for i, sig in enumerate(signal_names):
            sep = ";" if i == len(signal_names) - 1 else ""
            lines.append(f"  | '{sig}'{sep}")
        lines.append("")

    if config_attrs:
        lines.append(f"export interface {class_name}Config {{")
        for attr in config_attrs:
            lines.append(f"  {attr['name']}: {attr['type']};")
        lines.append("}")
        lines.append("")

    config_param = f"config: {class_name}Config" if config_attrs else ""
    lines.append(f"export class {class_name} extends EventEmitter {{")
    lines.append(f"  private _state: {enum_name};")
    if config_attrs:
        lines.append(f"  private readonly _config: {class_name}Config;")
    lines.append("")

    lines.append(f"  constructor({config_param}) {{")
    lines.append("    super();")
    if config_attrs:
        lines.append("    this._config = config;")
    if initial_state:
        lines.append(f"    this._state = {enum_name}.{_to_screaming_snake(initial_state)};")
    else:
        first_state = states[0] if states else "UNKNOWN"
        lines.append(f"    this._state = {enum_name}.{_to_screaming_snake(first_state)};")
    lines.append("  }")
    lines.append("")

    lines.append(f"  get state(): {enum_name} {{")
    lines.append("    return this._state;")
    lines.append("  }")
    lines.append("")

    if signal_names:
        lines.append(f"  dispatch(signal: {class_name}Signal): void {{")
    else:
        lines.append("  dispatch(signal: string): void {")
    lines.append("    const prev = this._state;")
    lines.append("    switch (this._state) {")

    transitions_by_source: dict[str, list[dict[str, str]]] = {}
    for t in transitions:
        from_state = t["from_state"]
        transitions_by_source.setdefault(from_state, []).append(t)

    for state in states:
        from_transitions = transitions_by_source.get(state, [])
        if not from_transitions:
            continue
        lines.append(f"      case {enum_name}.{_to_screaming_snake(state)}:")
        lines.append("        switch (signal) {")
        seen_signals: set[str] = set()
        for t in from_transitions:
            if t["signal"] in seen_signals:
                continue
            seen_signals.add(t["signal"])
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
    lines.append("      logger.info({ from: prev, to: this._state, signal }, 'state transition');")
    lines.append("      this.emit('transition', { from: prev, to: this._state, signal });")
    lines.append("    }")
    lines.append("  }")

    lines.append("}")
    lines.append("")
    return "\n".join(lines)
