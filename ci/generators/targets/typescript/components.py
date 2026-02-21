"""Component module generation."""
from __future__ import annotations

from ...ir import GraphNode, ModelGraph
from .naming import _sysml_type_to_ts, _to_screaming_snake
from .queries import (
    PIM_BEHAVIOR_PKG,
    _collect_action_implementations,
    _collect_named_reps,
    _collect_states,
    _collect_transitions,
    _find_psm_node,
    _get_config_attributes,
)


_RESERVED_REP_NAMES = {"textualRepresentation", "classMembers"}


def _action_has_function_body_rep(action_node: GraphNode) -> bool:
    """True if the action def has a TypeScript rep named functionBody."""
    reps_raw = action_node.properties.get("textual_representations", [])
    return any(
        (r.get("name") == "functionBody" and (r.get("language") or "").lower() == "typescript")
        for r in reps_raw
    )


def _build_function_signature(usage_name: str, action_params: list[dict]) -> tuple[str, str]:
    """Build (params_str, return_type) from action_params. Excludes 'self'."""
    in_params = [
        p for p in action_params
        if p.get("dir") == "in" and p.get("name") != "self"
    ]
    out_params = [p for p in action_params if p.get("dir") == "out"]
    params_str = ", ".join(
        f"{p['name']}: {_sysml_type_to_ts(p.get('type'), pass_through_unknown=True)}"
        for p in in_params
    )
    if len(out_params) == 1:
        return_type = _sysml_type_to_ts(out_params[0].get("type"), pass_through_unknown=True)
    else:
        return_type = "void"
    return params_str, return_type


def _emit_free_function(usage_name: str, body: str, action_node: GraphNode | None) -> str:
    """Emit a free function: either signature + body (when functionBody rep) or body verbatim."""
    if action_node and _action_has_function_body_rep(action_node):
        action_params = action_node.properties.get("action_params", [])
        params_str, return_type = _build_function_signature(usage_name, action_params)
        sig = f"export function {usage_name}({params_str}): {return_type}"
        indented = _indent(body.strip(), 2)
        return f"{sig} {{\n{indented}\n}}"
    return body


def _build_component_module(
    graph: ModelGraph,
    comp: dict[str, str],
) -> str:
    """Generate the TypeScript source for a single component module.

    Assembles from auto-generated skeleton (PIM state machine), named rep
    hooks from the PSM part def, and action implementations from performed
    PSM action defs:
      1. textualRepresentation  -> module preamble (imports, constants, interfaces)
      2. performed actions (no `in self`)  -> free functions
      3. skeleton imports, enum, signals, config, class, dispatch
      4. classMembers           -> extra field declarations (after skeleton fields)
      5. performed actions (`in self`)     -> class methods (after dispatch)
      6. other named reps       -> additional class methods (after dispatch)
    """
    psm_node = _find_psm_node(graph, comp["psm_short"], comp.get("part_def_qname"))
    reps = _collect_named_reps(psm_node)
    action_impls = _collect_action_implementations(graph, psm_node)
    free_fn_actions = [(n, b, node) for n, b, m, node in action_impls if not m]
    method_actions = [(n, b) for n, b, m, _ in action_impls if m]
    has_method_reps = bool(reps.keys() - _RESERVED_REP_NAMES) or bool(method_actions)

    machine_qname = f"{PIM_BEHAVIOR_PKG}::{comp['state_machine']}"
    class_name = comp["class_name"]

    states = _collect_states(graph, machine_qname)
    transitions = _collect_transitions(graph, machine_qname)
    config_attrs = _get_config_attributes(psm_node) if psm_node else []

    machine_node = graph.get(machine_qname)
    initial_state = machine_node.properties.get("entry_target") if machine_node else None

    lines: list[str] = []

    # --- 1. Module preamble from textualRepresentation rep ---
    preamble = reps.get("textualRepresentation", "").strip()
    if preamble:
        lines.append(preamble)
        lines.append("")

    # --- 2. Free-function action implementations (no `in self`) ---
    for action_name, action_body, action_node in free_fn_actions:
        lines.append(_emit_free_function(action_name, action_body, action_node))
        lines.append("")

    # --- 3. Skeleton standard imports + logger ---
    lines.append("import { EventEmitter } from 'events';")
    lines.append("import pino from 'pino';")
    lines.append("")
    lines.append(f"const logger = pino({{ name: '{class_name}' }});")
    lines.append("")

    # --- 4. Skeleton enum, signal type, config interface ---
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

    # --- 5. Open class + skeleton fields ---
    config_param = f"config: {class_name}Config" if config_attrs else ""
    lines.append(f"export class {class_name} extends EventEmitter {{")
    lines.append(f"  private _state: {enum_name};")
    if config_attrs:
        lines.append(f"  private readonly _config: {class_name}Config;")

    # --- 6. classMembers rep (extra field declarations) ---
    class_members = reps.get("classMembers", "").strip()
    if class_members:
        lines.append(_indent(class_members, 2))

    lines.append("")

    # --- 7. Constructor ---
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

    # --- 8. State getter ---
    lines.append(f"  get state(): {enum_name} {{")
    lines.append("    return this._state;")
    lines.append("  }")
    lines.append("")

    # --- 9. Dispatch (private _dispatch + public wrapper when method reps exist) ---
    _emit_dispatch(lines, enum_name, class_name, signal_names, states, transitions, has_method_reps)

    # --- 10. Method actions (`in self`) + named method reps ---
    for _action_name, action_body in method_actions:
        lines.append("")
        lines.append(_indent(action_body, 2))
    for rep_name, rep_body in reps.items():
        if rep_name in _RESERVED_REP_NAMES:
            continue
        method_code = rep_body.strip()
        if method_code:
            lines.append("")
            lines.append(_indent(method_code, 2))

    # --- 11. Close class ---
    lines.append("}")
    lines.append("")
    return "\n".join(lines)


def _emit_dispatch(
    lines: list[str],
    enum_name: str,
    class_name: str,
    signal_names: list[str],
    states: list[str],
    transitions: list[dict[str, str]],
    private: bool,
) -> None:
    """Emit the dispatch method. When *private* is True, emit ``_dispatch``
    (private) + a thin public ``dispatch`` wrapper so that method reps can
    call ``this._dispatch()`` internally."""
    sig_type = f"{class_name}Signal" if signal_names else "string"
    method_name = "_dispatch" if private else "dispatch"
    visibility = "private " if private else ""

    lines.append(f"  {visibility}{method_name}(signal: {sig_type}): void {{")
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

    if private:
        lines.append("")
        lines.append(f"  dispatch(signal: {sig_type}): void {{")
        lines.append("    this._dispatch(signal);")
        lines.append("  }")


def _indent(text: str, spaces: int) -> str:
    """Indent each line of *text* by *spaces*, preserving empty lines."""
    prefix = " " * spaces
    return "\n".join(
        prefix + line if line.strip() else line
        for line in text.splitlines()
    )
