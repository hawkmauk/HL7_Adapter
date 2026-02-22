"""Component module generation."""
from __future__ import annotations

import re

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
    _get_instance_attributes,
    _resolve_param_type_to_part_def_qname,
    get_preamble_type_part_defs,
)

_RESERVED_REP_NAMES = {"textualRepresentation", "classMembers"}


def _constant_value_to_ts(value_str: str, sysml_type: str | None) -> str:
    """Turn model constant value into a TypeScript literal for the preamble."""
    v = value_str.strip()
    if not v:
        return "0"
    lowered = (sysml_type or "").strip().lower()
    if lowered in ("integer", "int", "natural", "real", "float", "double"):
        if v.startswith("0x") or v.startswith("0X"):
            return v
        try:
            int(v)
            return v
        except ValueError:
            try:
                float(v)
                return v
            except ValueError:
                pass
    if (v.startswith('"') and v.endswith('"')) or (v.startswith("'") and v.endswith("'")):
        return v
    return repr(v)


def _emit_preamble_constants(psm_node: GraphNode | None) -> str:
    """Emit export const lines from the part def's constant declarations (preamble)."""
    if not psm_node:
        return ""
    constants = psm_node.properties.get("constants") or []
    if not constants:
        return ""
    lines: list[str] = []
    for c in constants:
        name = c.get("name", "")
        type_str = c.get("type", "")
        value_str = c.get("value", "")
        if not name:
            continue
        ts_value = _constant_value_to_ts(value_str, type_str)
        ts_name = _to_screaming_snake(name)
        lines.append(f"export const {ts_name} = {ts_value};")
    return "\n".join(lines) if lines else ""


def _emit_preamble_interfaces(
    graph: ModelGraph,
    psm_node: GraphNode | None,
) -> str:
    """Emit TypeScript interfaces and type aliases from part defs referenced by this component's actions.

    All type names and structure are derived from the model (no project-specific lists).
    """
    nodes = get_preamble_type_part_defs(graph, psm_node)
    if not nodes:
        return ""
    # Do not emit the component itself as a type
    component_qname = psm_node.qname if psm_node else None
    nodes = [n for n in nodes if n.qname != component_qname]
    # Skip types that are imported in this part def's rep (e.g. ParsedHL7 in transformer imports from parser)
    imported_type_names: set[str] = set()
    if psm_node:
        for r in psm_node.properties.get("textual_representations") or []:
            if (r.get("language") or "").lower() != "typescript":
                continue
            body = r.get("body") or ""
            for m in re.finditer(r"import\s+(?:type\s+)?\{\s*([^}]+)\s\}\s*from", body):
                for name in m.group(1).split(","):
                    imported_type_names.add(name.strip().split(r"\s+as\s+")[0].strip())
    if imported_type_names:
        nodes = [n for n in nodes if (n.short_name or n.name) not in imported_type_names]
    if not nodes:
        return ""
    preamble_qnames = {n.qname for n in nodes}
    # Part defs with no attributes but a TypeScript rep: use rep body as inline type when referenced
    inline_type_by_qname: dict[str, str] = {}
    for node in nodes:
        attrs = node.properties.get("attributes") or []
        if attrs:
            continue
        reps = node.properties.get("textual_representations") or []
        for r in reps:
            if (r.get("language") or "").lower() != "typescript":
                continue
            body = (r.get("body") or "").strip()
            if body:
                inline_type_by_qname[node.qname] = body
                break

    lines: list[str] = []
    for node in nodes:
        short = node.short_name or node.name
        if node.kind == "enum def":
            literals = node.properties.get("enum_literals") or []
            if literals:
                lines.append(f"export enum {short} {{")
                for lit in literals:
                    lines.append(f"  {lit} = '{lit}',")
                lines.append("}")
            lines.append("")
            continue

        attrs = node.properties.get("attributes") or []
        reps = node.properties.get("textual_representations") or []
        ts_rep_body = ""
        for r in reps:
            if (r.get("language") or "").lower() == "typescript":
                ts_rep_body = (r.get("body") or "").strip()
                break

        supertype_edges = graph.outgoing(node.qname, "supertype")
        supertypes_in_set = [e.target for e in supertype_edges if e.target and e.target in preamble_qnames]

        if not attrs and len(supertypes_in_set) >= 2:
            # Type alias: Union = Super1 | Super2
            super_names = []
            for q in supertypes_in_set:
                sn = graph.get(q)
                super_names.append(sn.short_name or sn.name if sn else q.split("::")[-1])
            lines.append(f"export type {short} = {' | '.join(super_names)};")
        elif not attrs and ts_rep_body:
            # Interface body (e.g. TransformOutput with members and index signature) vs type alias (e.g. SegmentMap = Record<...>)
            if "?:" in ts_rep_body or "[key:" in ts_rep_body or (";" in ts_rep_body and "\n" in ts_rep_body):
                lines.append(f"export interface {short} {{")
                lines.append(ts_rep_body)
                lines.append("}")
            else:
                lines.append(f"export type {short} = {ts_rep_body};")
        elif ts_rep_body and attrs:
            # Model supplies exact interface body via rep (e.g. discriminated union member)
            lines.append(f"export interface {short} {{")
            lines.append(ts_rep_body)
            lines.append("}")
        elif attrs:
            lines.append(f"export interface {short} {{")
            for a in attrs:
                raw_name = a.get("name") or ""
                # Strip [*] from name for TS property (e.g. payload[*] -> payload)
                name = raw_name.replace("[*]", "").strip()
                raw = (a.get("type") or "").strip()
                # Strip default value (e.g. "String = \"env\"") and multiplicity for type-only
                type_only = raw.split("=")[0].strip()
                # Optional in TS when multiplicity is [0..1] or [*] on type, or [*] on attribute name
                optional = (
                    " [0..1]" in type_only
                    or " [*]" in type_only
                    or "[*]" in type_only
                    or "[*]" in raw_name
                )
                type_for_ref = type_only.split("[0..1]")[0].split("[*]")[0].strip()
                ref = _resolve_param_type_to_part_def_qname(
                    graph, type_for_ref, prefer_prefix=None
                )
                ref_node = graph.get(ref) if ref else None
                if ref_node and ref_node.qname in inline_type_by_qname:
                    ts_type = inline_type_by_qname[ref_node.qname]
                elif ref_node and ref_node.qname in preamble_qnames:
                    ts_type = ref_node.short_name or ref_node.name
                else:
                    base = type_for_ref.split("::")[-1].strip()
                    ts_type = _sysml_type_to_ts(base) if base.lower() in ("string", "integer", "boolean", "str", "int", "bool", "real", "natural") else base
                lines.append(f"  {name}{'?' if optional else ''}: {ts_type};")
            lines.append("}")
        elif not attrs and not ts_rep_body:
            # Abstract or attribute-less part def referenced by other preamble types (e.g. SensitiveData)
            lines.append(f"export type {short} = unknown;")
        else:
            continue
        lines.append("")
    return "\n".join(lines)


def _action_has_function_body_rep(action_node: GraphNode) -> bool:
    """True if the action def has a TypeScript rep named functionBody."""
    reps_raw = action_node.properties.get("textual_representations", [])
    return any(
        (r.get("name") == "functionBody" and (r.get("language") or "").lower() == "typescript")
        for r in reps_raw
    )


def _strip_outer_method_signature(body: str) -> str:
    """If body is 'methodName(...): type { ... }', return only the inner content to avoid double-wrapping."""
    stripped = body.strip()
    # Match first line like "start(): void {" or "async foo(x: number): Promise<void> {"
    match = re.match(r"^(\s*)(?:async\s+)?\w+\s*\([^)]*\)\s*:\s*[^{]+\s*\{\s*", stripped, re.DOTALL)
    if not match:
        return body
    # Remove the first line; remove one matching trailing "}"
    rest = stripped[match.end() :].rstrip()
    if rest.endswith("}"):
        rest = rest[: rest.rfind("}")].rstrip()
    return rest


def _build_method_params(action_params: list[dict]) -> str:
    """Build params string for a class method from action_params. Excludes 'self'. Optional [0..1] -> param?."""
    in_params = [
        p for p in action_params
        if p.get("dir") == "in" and p.get("name") != "self"
    ]
    parts = []
    for p in in_params:
        raw_type = (p.get("type") or "").strip()
        optional = " [0..1]" in raw_type
        type_only = raw_type.split(" [0..1]")[0].strip().split("=")[0].strip()
        ts_type = _sysml_type_to_ts(type_only, pass_through_unknown=True)
        name = p.get("name") or ""
        suffix = "?" if optional else ""
        parts.append(f"{name}{suffix}: {ts_type}")
    return ", ".join(parts)


def _build_function_signature(usage_name: str, action_params: list[dict]) -> tuple[str, str]:
    """Build (params_str, return_type) from action_params. Excludes 'self'. Optional [0..1] -> param?."""
    in_params = [
        p for p in action_params
        if p.get("dir") == "in" and p.get("name") != "self"
    ]
    out_params = [p for p in action_params if p.get("dir") == "out"]
    parts = []
    for p in in_params:
        raw_type = (p.get("type") or "").strip()
        optional = " [0..1]" in raw_type
        type_only = raw_type.split(" [0..1]")[0].strip().split("=")[0].strip()
        ts_type = _sysml_type_to_ts(type_only, pass_through_unknown=True)
        name = p.get("name") or ""
        suffix = "?" if optional else ""
        parts.append(f"{name}{suffix}: {ts_type}")
    params_str = ", ".join(parts)
    if len(out_params) == 1:
        raw_out = (out_params[0].get("type") or "").strip()
        type_only = raw_out.split(" [0..1]")[0].strip().split("=")[0].strip()
        return_type = _sysml_type_to_ts(type_only, pass_through_unknown=True)
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
    method_actions = [(n, b, node) for n, b, m, node in action_impls if m]
    has_method_reps = bool(reps.keys() - _RESERVED_REP_NAMES) or bool(method_actions)

    machine_qname = f"{PIM_BEHAVIOR_PKG}::{comp['state_machine']}"
    class_name = comp["class_name"]

    states = _collect_states(graph, machine_qname)
    transitions = _collect_transitions(graph, machine_qname)
    config_attrs = _get_config_attributes(psm_node) if psm_node else []

    machine_node = graph.get(machine_qname)
    initial_state = machine_node.properties.get("entry_target") if machine_node else None

    lines: list[str] = []

    # --- 1. Preamble: constants from part def (model constant decls) ---
    preamble_constants = _emit_preamble_constants(psm_node)
    if preamble_constants:
        lines.append(preamble_constants)
        lines.append("")
    # --- 1b. Preamble: interfaces/type aliases from part defs referenced by this component's actions ---
    preamble_from_model = _emit_preamble_interfaces(graph, psm_node)
    if preamble_from_model:
        lines.append(preamble_from_model)
    # --- 1c. Module preamble from part def's textualRepresentation rep (imports, etc.) ---
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

    # --- 6. Private instance attributes (part def attributes whose name starts with '_') ---
    instance_attrs = _get_instance_attributes(psm_node) if psm_node else []
    for attr in instance_attrs:
        optional = attr.get("optional", False)
        composite = attr.get("composite", False)
        if optional:
            lines.append(f"  private {attr['name']}?: {attr['type']};")
        elif composite:
            # Part/interface type: no field initializer; will be set in constructor
            lines.append(f"  private {attr['name']}: {attr['type']};")
        else:
            lines.append(f"  private {attr['name']}: {attr['type']} = {attr['default']};")

    # --- 7. classMembers rep (extra field declarations, legacy) ---
    class_members = reps.get("classMembers", "").strip()
    if class_members:
        lines.append(_indent(class_members, 2))

    lines.append("")

    # --- 8. Constructor ---
    lines.append(f"  constructor({config_param}) {{")
    lines.append("    super();")
    if config_attrs:
        lines.append("    this._config = config;")
    if initial_state:
        lines.append(f"    this._state = {enum_name}.{_to_screaming_snake(initial_state)};")
    else:
        first_state = states[0] if states else "UNKNOWN"
        lines.append(f"    this._state = {enum_name}.{_to_screaming_snake(first_state)};")
    for attr in instance_attrs:
        if attr.get("optional", False):
            continue
        if attr.get("composite", False):
            # Composite types from the model are emitted as TS interfaces, not classes; use object literal + type assertion
            lines.append(f"    this.{attr['name']} = {{}} as {attr['type']};")
        else:
            lines.append(f"    this.{attr['name']} = {attr['default']};")
    lines.append("  }")
    lines.append("")

    # --- 9. State getter ---
    lines.append(f"  get state(): {enum_name} {{")
    lines.append("    return this._state;")
    lines.append("  }")
    lines.append("")

    # --- 10. Dispatch (private _dispatch + public wrapper when method reps exist) ---
    _emit_dispatch(lines, enum_name, class_name, signal_names, states, transitions, has_method_reps)

    # --- 11. Method actions (`in self`) + named method reps ---
    for action_name, action_body, action_node in method_actions:
        params_str = ""
        return_type = "void"
        if action_node:
            action_params = action_node.properties.get("action_params", [])
            params_str = _build_method_params(action_params)
            _, return_type = _build_function_signature(action_name, action_params)
        body_only = _strip_outer_method_signature(action_body)
        async_suffix = "async " if "await " in action_body or "await(" in action_body else ""
        if async_suffix:
            return_type = "Promise<void>" if return_type == "void" else f"Promise<{return_type}>"
        elif return_type == "void" and action_name == "getStatus":
            return_type = "{ status: 'degraded' | 'ready'; lastError?: string }"
        lines.append("")
        lines.append(f"  {async_suffix}{action_name}({params_str}): {return_type} {{")
        lines.append(_indent(body_only.strip(), 4))
        lines.append("  }")
    for rep_name, rep_body in reps.items():
        if rep_name in _RESERVED_REP_NAMES:
            continue
        method_code = rep_body.strip()
        if method_code:
            lines.append("")
            lines.append(_indent(method_code, 2))

    # --- 12. Close class ---
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
            action_name = t.get("transition_action")
            if action_name:
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
