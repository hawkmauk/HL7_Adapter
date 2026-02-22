"""Service orchestrator module generation."""
from __future__ import annotations

from ...ir import ModelGraph
from .naming import _display_name_to_class_name, _to_camel, _to_screaming_snake
from .queries import (
    _find_root_adapter_part_def,
    _find_root_adapter_from_exposed,
    get_adapter_state_machine,
    get_component_map,
    get_initialize_from_binding_calls,
    get_part_property_for_action,
    get_service_lifecycle_action_params,
    get_service_lifecycle_initial_do_action,
    get_service_run_action_body,
    PIM_BEHAVIOR_PKG,
    _collect_states,
    _collect_transitions,
    _find_psm_node,
    _get_config_attributes,
)


def get_service_constructor_params(
    graph: ModelGraph, document: object | None = None
) -> list[dict]:
    """Return constructor param specs for the service (same logic as _build_service_module).

    Each item: {"param_name": str, "config_type": str, "class_name": str, "config_attrs": list}.
    Used by the service generator and by vitest to build service test initialisation.
    """
    component_map = get_component_map(graph, document=document)
    result: list[dict] = []
    for comp in component_map:
        psm = _find_psm_node(graph, comp["psm_short"], comp.get("part_def_qname"))
        attrs = _get_config_attributes(psm) if psm else []
        if attrs:
            result.append({
                "param_name": _to_camel(comp["class_name"]),
                "config_type": f"{comp['class_name']}Config",
                "class_name": comp["class_name"],
                "config_attrs": attrs,
            })
    return result


def _derive_service_class_name(graph: ModelGraph, document: object | None = None) -> str:
    """Derive the service class name from the model's service part def display name."""
    if document is not None and getattr(document, "exposed_elements", None):
        qname, _ = _find_root_adapter_from_exposed(graph, document.exposed_elements)
        if not qname:
            qname, _ = _find_root_adapter_part_def(graph)
    else:
        qname, _ = _find_root_adapter_part_def(graph)
    if qname:
        node = graph.get(qname)
        if node:
            display = (node.name or node.short_name or "").strip()
            return _display_name_to_class_name(display)
    return "Service"


def _build_service_module(graph: ModelGraph, document: object | None = None) -> str:
    """Generate the service.ts orchestrator that wires all components together."""
    if document is not None and getattr(document, "exposed_elements", None):
        adapter_qname, _ = _find_root_adapter_from_exposed(graph, document.exposed_elements)
        if not adapter_qname:
            adapter_qname, _ = _find_root_adapter_part_def(graph)
    else:
        adapter_qname, _ = _find_root_adapter_part_def(graph)
    component_map = get_component_map(graph, document=document)
    service_state_machine = get_adapter_state_machine(graph, document=document)
    if not service_state_machine:
        return ""
    service_class = _derive_service_class_name(graph, document)
    machine_qname = f"{PIM_BEHAVIOR_PKG}::{service_state_machine}"
    states = _collect_states(graph, machine_qname)
    transitions = _collect_transitions(graph, machine_qname)
    machine_node = graph.get(machine_qname)
    initial_state = machine_node.properties.get("entry_target") if machine_node else "Idle"

    lines: list[str] = []

    imports: list[str] = []
    for comp in component_map:
        module = comp["output_file"].replace(".ts", "")
        psm = _find_psm_node(graph, comp["psm_short"], comp.get("part_def_qname"))
        attrs = _get_config_attributes(psm) if psm else []
        if attrs:
            imports.append(f"import {{ {comp['class_name']}, {comp['class_name']}Config }} from './{module}';")
        else:
            imports.append(f"import {{ {comp['class_name']} }} from './{module}';")
    lines.extend(imports)
    lines.append("import { EventEmitter } from 'events';")
    lines.append("import pino from 'pino';")
    lines.append("")
    lines.append(f"const logger = pino({{ name: '{service_class}' }});")
    lines.append("")

    enum_name = "ServiceState"
    lines.append(f"export enum {enum_name} {{")
    for state in states:
        lines.append(f"  {_to_screaming_snake(state)} = '{state}',")
    lines.append("}")
    lines.append("")

    signal_names = sorted({t["signal"] for t in transitions})
    if signal_names:
        lines.append("export type ServiceSignal =")
        for i, sig in enumerate(signal_names):
            sep = ";" if i == len(signal_names) - 1 else ""
            lines.append(f"  | '{sig}'{sep}")
        lines.append("")

    constructor_params_spec = get_service_constructor_params(graph, document=document)
    if constructor_params_spec:
        lines.append("export interface ServiceConfig {")
        for p in constructor_params_spec:
            lines.append(f"  {p['param_name']}: {p['config_type']};")
        lines.append("}")
        lines.append("")

    lines.append(f"export class {service_class} extends EventEmitter {{")
    lines.append(f"  private _state: {enum_name};")
    for comp in component_map:
        field = _to_camel(comp["class_name"])
        lines.append(f"  readonly {field}: {comp['class_name']};")
    lines.append("")

    constructor_params: list[str] = []
    for comp in component_map:
        psm = _find_psm_node(graph, comp["psm_short"], comp.get("part_def_qname"))
        attrs = _get_config_attributes(psm) if psm else []
        if attrs:
            constructor_params.append(f"{_to_camel(comp['class_name'])}Config: {comp['class_name']}Config")

    config_imports: list[str] = []
    for comp in component_map:
        psm = _find_psm_node(graph, comp["psm_short"], comp.get("part_def_qname"))
        attrs = _get_config_attributes(psm) if psm else []
        if attrs:
            config_imports.append(f"{comp['class_name']}Config")

    param_str = ", ".join(constructor_params) if constructor_params else ""
    lines.append(f"  constructor({param_str}) {{")
    lines.append("    super();")
    lines.append(f"    this._state = {enum_name}.{_to_screaming_snake(initial_state or 'Idle')};")
    for comp in component_map:
        field = _to_camel(comp["class_name"])
        psm = _find_psm_node(graph, comp["psm_short"], comp.get("part_def_qname"))
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
        lines.append("  dispatch(signal: ServiceSignal): void {")
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
            action_name = t.get("transition_action")
            if action_name and adapter_qname:
                part = get_part_property_for_action(graph, adapter_qname, action_name, document=document)
                if part:
                    lines.append(f"            this.{part}.{action_name}();")
                else:
                    lines.append(f"            this.{action_name}();")
            lines.append("            break;")
        lines.append("          default:")
        lines.append("            break;")
        lines.append("        }")
        lines.append("        break;")

    lines.append("      default:")
    lines.append("        break;")
    lines.append("    }")
    lines.append("    if (this._state !== prev) {")
    lines.append("      logger.info({ from: prev, to: this._state, signal }, 'service state transition');")
    lines.append("      this.emit('transition', { from: prev, to: this._state, signal });")
    lines.append("    }")
    lines.append("  }")

    do_action = get_service_lifecycle_initial_do_action(graph, document=document)
    lifecycle_params = get_service_lifecycle_action_params(graph, document=document)
    init_calls = get_initialize_from_binding_calls(graph, document=document)
    lifecycle_body = get_service_run_action_body(graph, document=document)
    if do_action:
        lines.append("")
        if lifecycle_params and init_calls and constructor_params_spec:
            lines.append("  initialize(config: ServiceConfig): void {")
            for field_name, arg_exprs in init_calls:
                args_str = ", ".join(arg_exprs)
                lines.append(f"    this.{field_name}.initializeFromBinding({args_str});")
            lines.append("  }")
        else:
            lines.append(f"  {do_action}(): void {{")
            if lifecycle_body:
                for line in lifecycle_body.split("\n"):
                    lines.append("    " + line if line.strip() else "")
            lines.append("  }")

    lines.append("}")
    lines.append("")
    return "\n".join(lines)
