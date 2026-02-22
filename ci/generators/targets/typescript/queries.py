"""Graph query helpers for TypeScript generation.

All component-to-state-machine mappings are derived from the model graph
via ``exhibit`` edges (part def --exhibit--> state usage) rather than
hardcoded lookup tables.
"""
from __future__ import annotations

import re

from ...ir import ExposedElement, GraphEdge, GraphNode, ModelGraph
from .naming import _display_name_to_class_name, _sysml_type_to_ts, _to_camel


PIM_BEHAVIOR_PKG = "PIM_Behavior"


def _resolve_part_def_qname(
    graph: ModelGraph, type_ref: str, prefer_prefix: str | None = None
) -> str | None:
    """Resolve a type reference to a part def qname."""
    last_segment = type_ref.split("::")[-1]
    candidates = [
        n.qname
        for n in graph.nodes.values()
        if n.kind in ("part", "part def")
        and (n.short_name == last_segment or n.name == last_segment)
    ]
    if type_ref in graph.nodes and type_ref not in candidates:
        candidates.append(type_ref)
    if not candidates:
        return None
    if prefer_prefix:
        for q in candidates:
            if q.startswith(prefer_prefix):
                return q
    # Prefer PSM over PIM when prefer_prefix did not match (e.g. MLLPReceiver -> PSM_MLLPReceiver::...)
    psm = [q for q in candidates if q.startswith("PSM_")]
    if psm:
        return psm[0]
    return type_ref if type_ref in graph.nodes else candidates[0]


def _resolve_param_type_to_part_def_qname(
    graph: ModelGraph,
    type_str: str | None,
    prefer_prefix: str | None = None,
) -> str | None:
    """Resolve an action param or attribute type to a part def or enum def qname. Strips [0..1] etc.
    If prefer_prefix is set (e.g. 'PSM'), prefer part defs whose qname starts with that prefix.
    """
    if not type_str:
        return None
    raw = (
        type_str.strip()
        .split("[0..1]")[0]
        .strip()
        .split("[*]")[0]
        .strip()
        .split("=")[0]
        .strip()
    )
    last = raw.split("::")[-1].strip()
    if not last:
        return None
    candidates = [
        n.qname
        for n in graph.nodes.values()
        if n.kind in ("part", "part def", "enum def")
        and (n.short_name == last or n.name == last)
    ]
    if not candidates:
        return None
    if prefer_prefix:
        for q in candidates:
            if q.startswith(prefer_prefix):
                return q
    return candidates[0]


def get_preamble_type_part_defs(
    graph: ModelGraph, psm_node: GraphNode | None
) -> list[GraphNode]:
    """Collect part defs referenced by this component's performed actions (param types and type names in action bodies), and their attribute types, in dependency order.

    Used to emit interfaces/type aliases for preamble types from the model (no project-specific lists).
    """
    if not psm_node:
        return []
    adapter_qname, _ = _find_root_adapter_part_def(graph)
    # Prefer part defs from the same top-level namespace as the component (e.g. PSM_* when component is PSM_*)
    first_seg = (psm_node.qname or "").split("::")[0]
    prefer_prefix = (first_seg.split("_")[0] + "_") if first_seg else None

    seen: set[str] = set()
    qnames: list[str] = []
    perform_decls = psm_node.properties.get("perform_actions", [])
    performs_edges = graph.outgoing(psm_node.qname, "performs")
    target_map: dict[str, str] = {}
    for edge in performs_edges:
        action_q = edge.target
        if action_q and action_q not in graph.nodes:
            action_q = _resolve_action_qname(graph, edge.target or "", prefer_prefix)
        if action_q:
            target_map[edge.properties.get("usage_name", "")] = action_q

    # All part def and enum def short names for body-scan matching (generic: no project names)
    part_def_short_names = {
        n.short_name or n.name
        for n in graph.nodes.values()
        if n.kind in ("part", "part def", "enum def") and (n.short_name or n.name)
    }

    def add(q: str) -> None:
        if q in seen:
            return
        if q == psm_node.qname:
            return  # Exclude the component itself from preamble types
        if adapter_qname and q == adapter_qname:
            return  # Exclude the root adapter service (imported from ./service in RestApi etc.)
        seen.add(q)
        node = graph.get(q)
        if not node or node.kind not in ("part", "part def", "enum def"):
            return
        if node.kind == "enum def":
            qnames.append(q)
            return  # enum defs have no attributes to recurse
        for a in node.properties.get("attributes") or []:
            ref = _resolve_param_type_to_part_def_qname(
                graph, a.get("type"), prefer_prefix=prefer_prefix
            )
            if ref:
                add(ref)
        for edge in graph.outgoing(q, "supertype"):
            if edge.target:
                add(edge.target)
        # Collect types referenced in this node's TypeScript rep body (e.g. MappingConfig rep "MappingConfigEntry[]")
        for r in node.properties.get("textual_representations") or []:
            if (r.get("language") or "").lower() != "typescript":
                continue
            body = r.get("body") or ""
            for short in part_def_short_names:
                if re.search(rf"\b{re.escape(short)}\b", body):
                    ref = _resolve_param_type_to_part_def_qname(
                        graph, short, prefer_prefix=prefer_prefix
                    )
                    if ref:
                        add(ref)
        qnames.append(q)

    # Collect types referenced in this part def's own TypeScript reps (e.g. classMembers referencing ErrorClass)
    for r in psm_node.properties.get("textual_representations") or []:
        if (r.get("language") or "").lower() != "typescript":
            continue
        body = r.get("body") or ""
        for short in part_def_short_names:
            if re.search(rf"\b{re.escape(short)}\b", body):
                ref = _resolve_param_type_to_part_def_qname(
                    graph, short, prefer_prefix=prefer_prefix
                )
                if ref:
                    add(ref)

    for decl in perform_decls:
        usage_name = decl.get("name", "")
        action_qname = target_map.get(usage_name)
        if not action_qname:
            continue
        action_node = graph.get(action_qname)
        if not action_node:
            continue
        for p in action_node.properties.get("action_params") or []:
            ref = _resolve_param_type_to_part_def_qname(
                graph, p.get("type"), prefer_prefix=prefer_prefix
            )
            if ref:
                add(ref)
        # Also collect type names that appear in action rep bodies (e.g. ParsedHL7, MSHFields in function body)
        for r in action_node.properties.get("textual_representations") or []:
            if (r.get("language") or "").lower() != "typescript":
                continue
            body = r.get("body") or ""
            for short in part_def_short_names:
                if re.search(rf"\b{re.escape(short)}\b", body):
                    ref = _resolve_param_type_to_part_def_qname(
                        graph, short, prefer_prefix=prefer_prefix
                    )
                    if ref:
                        add(ref)

    # Topological sort: part def A before B if B has an attribute of type A (or B has supertype A)
    dep: dict[str, set[str]] = {q: set() for q in qnames}
    for q in qnames:
        node = graph.get(q)
        if not node:
            continue
        for a in node.properties.get("attributes") or []:
            ref = _resolve_param_type_to_part_def_qname(graph, a.get("type"))
            if ref and ref in dep:
                dep[q].add(ref)
        for edge in graph.outgoing(q, "supertype"):
            if edge.target and edge.target in dep:
                dep[q].add(edge.target)

    sorted_qnames: list[str] = []
    while dep:
        ready = [q for q in dep if not dep[q]]
        if not ready:
            break
        for q in sorted(ready):
            sorted_qnames.append(q)
            del dep[q]
        for q in dep:
            dep[q] -= set(ready)
    for q in qnames:
        if q not in sorted_qnames:
            sorted_qnames.append(q)

    return [graph.get(q) for q in sorted_qnames if graph.get(q)]


def get_preamble_type_names(
    graph: ModelGraph, psm_node: GraphNode | None
) -> list[str]:
    """Return short names of types referenced by this component's actions (for test extra imports)."""
    nodes = get_preamble_type_part_defs(graph, psm_node)
    return sorted({n.short_name or n.name for n in nodes if n.short_name or n.name})


def _get_exhibited_state(graph: ModelGraph, part_def_qname: str) -> str | None:
    """Follow exhibit edges from a part def (or its supertype chain) to find the state usage name.

    Walks the supertype chain so that PSM part defs that refine PIM part defs
    inherit the exhibit relationship. Handles unresolved supertype edges by
    matching the last segment of the target to all candidate nodes.
    """
    visited: set[str] = set()
    queue = [part_def_qname]
    while queue:
        qname = queue.pop(0)
        if qname in visited:
            continue
        visited.add(qname)
        for edge in graph.outgoing(qname, "exhibit"):
            target_node = graph.get(edge.target)
            if target_node and target_node.kind == "state":
                return target_node.name
        for edge in graph.outgoing(qname, "supertype"):
            target = edge.target
            if not target or target in visited:
                continue
            if target in graph.nodes:
                queue.append(target)
            else:
                for candidate in _resolve_all_part_defs(graph, target):
                    if candidate not in visited:
                        queue.append(candidate)
    return None


def _resolve_all_part_defs(graph: ModelGraph, type_ref: str) -> list[str]:
    """Resolve a type reference to all matching part/part def qnames."""
    last_segment = type_ref.split("::")[-1]
    return [
        n.qname
        for n in graph.nodes.values()
        if n.kind in ("part", "part def")
        and (n.short_name == last_segment or n.name == last_segment)
    ]


def _find_root_adapter_part_def(graph: ModelGraph) -> tuple[str | None, str | None]:
    """Find the adapter part def and its state machine usage name.

    Looks for a part def with 5+ child parts that exhibits a state machine.
    Prefers PSM-level part defs over PIM-level ones.
    """
    fallback: tuple[str | None, str | None] = (None, None)
    for node in graph.nodes.values():
        if node.kind not in ("part", "part def"):
            continue
        component_children = graph.children(node.qname, kind="part")
        if len(component_children) < 5:
            continue
        state_machine = _get_exhibited_state(graph, node.qname)
        if not state_machine:
            continue
        if node.qname.startswith("PSM"):
            return (node.qname, state_machine)
        fallback = (node.qname, state_machine)
    return fallback


def _find_root_adapter_from_exposed(
    graph: ModelGraph, exposed_elements: list[ExposedElement]
) -> tuple[str | None, str | None]:
    """Find the adapter part def and state machine name from a view's exposed elements."""
    exposed_qnames = {
        e.qualified_name
        for e in exposed_elements
        if e.kind in ("part", "part def")
    }
    for qname in sorted(exposed_qnames, key=lambda q: (not q.startswith("PSM"), q)):
        node = graph.get(qname)
        if not node or node.kind not in ("part", "part def"):
            continue
        component_children = graph.children(qname, kind="part")
        if len(component_children) < 5:
            continue
        state_machine = _get_exhibited_state(graph, qname)
        if not state_machine:
            continue
        return (qname, state_machine)
    return (None, None)


def get_component_map(
    graph: ModelGraph,
    document: object | None = None,
) -> list[dict[str, str]]:
    """Derive component map from the model via exhibit edges.

    For each child part of the adapter, resolves its part def, walks the
    supertype chain to find the exhibit edge, and derives the state machine
    usage name, output filename, and class name from the model.
    """
    if document is not None and getattr(document, "exposed_elements", None):
        adapter_part_def_qname, _ = _find_root_adapter_from_exposed(
            graph, document.exposed_elements
        )
        if not adapter_part_def_qname:
            adapter_part_def_qname, _ = _find_root_adapter_part_def(graph)
    else:
        adapter_part_def_qname, _ = _find_root_adapter_part_def(graph)
    if not adapter_part_def_qname:
        return []

    adapter_prefix = adapter_part_def_qname.split("::")[0]
    result: list[dict[str, str]] = []
    for comp_usage in graph.children(adapter_part_def_qname, kind="part"):
        for edge in graph.outgoing(comp_usage.qname, "supertype"):
            type_ref = (edge.target or "").strip()
            if not type_ref:
                continue
            part_def_qname = _resolve_part_def_qname(
                graph, type_ref, prefer_prefix=adapter_prefix
            )
            if not part_def_qname:
                continue
            part_def_node = graph.get(part_def_qname)
            if not part_def_node:
                continue
            state_machine = _get_exhibited_state(graph, part_def_qname)
            if not state_machine:
                continue
            display = (part_def_node.name or part_def_node.short_name or "").strip()
            output_file = display.replace(" ", "_").lower() + ".ts"
            class_name = _display_name_to_class_name(display)
            result.append({
                "psm_short": part_def_node.short_name or part_def_node.name,
                "state_machine": state_machine,
                "output_file": output_file,
                "class_name": class_name,
                "part_def_qname": part_def_qname,
            })
            break

    result.sort(key=lambda c: c["part_def_qname"])
    return result


def get_service_lifecycle_initial_do_action(
    graph: ModelGraph,
    document: object | None = None,
) -> str:
    """Return the name of the do action on the adapter's exhibited state machine initial state, or empty string.

    Uses the same exhibited state machine as get_adapter_state_machine() (e.g. hl7AdapterController).
    Reads do_action from that state node (e.g. 'initialize' from 'do action initialize : Initialize;').
    Used to generate service.initialize() and main calling it, without project-specific logic.
    """
    machine_name = get_adapter_state_machine(graph, document=document)
    if not machine_name:
        return ""
    state_qname = f"{PIM_BEHAVIOR_PKG}::{machine_name}"
    state_node = graph.get(state_qname)
    if not state_node or state_node.kind != "state":
        return ""
    do_action = (state_node.properties.get("do_action") or "").strip()
    return do_action if do_action else ""


def get_service_run_action_body(
    graph: ModelGraph,
    document: object | None = None,
) -> str:
    """Return the TypeScript body of the service part def's performed action matching the service lifecycle do action.

    If the PIM service state machine has 'do action initialize', returns the body of the service's performed
    'initialize' action (e.g. RunAdapter). Used to generate the method called by start() from the model.
    """
    do_action = get_service_lifecycle_initial_do_action(graph, document=document)
    if not do_action:
        return ""
    if document is not None and getattr(document, "exposed_elements", None):
        adapter_qname, _ = _find_root_adapter_from_exposed(graph, document.exposed_elements)
        if not adapter_qname:
            adapter_qname, _ = _find_root_adapter_part_def(graph)
    else:
        adapter_qname, _ = _find_root_adapter_part_def(graph)
    if not adapter_qname:
        return ""
    adapter_node = graph.get(adapter_qname)
    implementations = _collect_action_implementations(graph, adapter_node)
    for usage_name, body, _is_method, _node in implementations:
        if usage_name == do_action:
            return body
    return ""


def get_initialize_from_binding_calls(
    graph: ModelGraph,
    document: object | None = None,
) -> list[tuple[str, list[str]]]:
    """Return (part_field_name, arg_exprs) for each adapter part that has initializeFromBinding.

    Used to generate service.initialize(config) body: for each part, emit
    this.<field>.initializeFromBinding(...args). Arg expressions: config.<field> for binding-like
    params, 'this' for service param. Part field name is camelCase class name (e.g. restApi, httpForwarder).
    """
    component_map = get_component_map(graph, document=document)
    if not component_map:
        return []
    adapter_prefix = ""
    if document is not None and getattr(document, "exposed_elements", None):
        adapter_qname, _ = _find_root_adapter_from_exposed(graph, document.exposed_elements)
        if not adapter_qname:
            adapter_qname, _ = _find_root_adapter_part_def(graph)
    else:
        adapter_qname, _ = _find_root_adapter_part_def(graph)
    if adapter_qname:
        adapter_prefix = (adapter_qname.split("::")[0] + "_") if "::" in adapter_qname else ""

    result: list[tuple[str, list[str]]] = []
    for comp in component_map:
        part_def_qname = comp.get("part_def_qname")
        if not part_def_qname:
            continue
        part_node = graph.get(part_def_qname)
        if not part_node:
            continue
        perform_decls = part_node.properties.get("perform_actions") or []
        if not isinstance(perform_decls, list):
            continue
        init_name = "initializeFromBinding"
        if not any(
            (d.get("name") if isinstance(d, dict) else None) == init_name
            for d in perform_decls
        ):
            continue
        prefer_prefix = (part_def_qname.split("::")[0] + "_") if "::" in part_def_qname else adapter_prefix
        for edge in graph.outgoing(part_def_qname, "performs"):
            if edge.properties.get("usage_name") != init_name:
                continue
            action_qname = edge.target
            if action_qname and action_qname not in graph.nodes:
                action_qname = _resolve_action_qname(graph, edge.target or "", prefer_prefix)
            action_node = graph.get(action_qname) if action_qname else None
            if not action_node:
                break
            # Only include parts whose initializeFromBinding has an implementation (body)
            reps = _collect_named_reps(action_node)
            body = (reps.get("functionBody") or reps.get("textualRepresentation") or "").strip()
            if not body:
                break
            action_params = action_node.properties.get("action_params") or []
            field_name = _to_camel(comp["class_name"])
            arg_exprs: list[str] = []
            for p in action_params:
                if p.get("dir") != "in":
                    continue
                pname = (p.get("name") or "").strip()
                if pname == "self":
                    continue
                if pname == "service":
                    arg_exprs.append("this")
                else:
                    arg_exprs.append(f"config.{field_name}")
            result.append((field_name, arg_exprs))
            break
    return result


def get_service_lifecycle_action_params(
    graph: ModelGraph,
    document: object | None = None,
) -> list[dict]:
    """Return action_params (excluding self) for the service's performed lifecycle action (e.g. InitializeAdapter)."""
    do_action = get_service_lifecycle_initial_do_action(graph, document=document)
    if not do_action:
        return []
    if document is not None and getattr(document, "exposed_elements", None):
        adapter_qname, _ = _find_root_adapter_from_exposed(graph, document.exposed_elements)
        if not adapter_qname:
            adapter_qname, _ = _find_root_adapter_part_def(graph)
    else:
        adapter_qname, _ = _find_root_adapter_part_def(graph)
    if not adapter_qname:
        return []
    adapter_node = graph.get(adapter_qname)
    if not adapter_node:
        return []
    perform_decls = adapter_node.properties.get("perform_actions") or []
    for decl in perform_decls:
        if (decl.get("name") if isinstance(decl, dict) else None) != do_action:
            continue
        break
    else:
        return []
    first_seg = (adapter_qname or "").split("::")[0]
    prefer_prefix = (first_seg + "_") if first_seg else None
    for edge in graph.outgoing(adapter_qname, "performs"):
        if edge.properties.get("usage_name") != do_action:
            continue
        action_qname = edge.target
        if action_qname and action_qname not in graph.nodes:
            action_qname = _resolve_action_qname(graph, edge.target or "", prefer_prefix)
        action_node = graph.get(action_qname) if action_qname else None
        if not action_node:
            return []
        params = action_node.properties.get("action_params") or []
        return [p for p in params if p.get("dir") == "in" and (p.get("name") or "").strip() != "self"]
    return []


def get_adapter_state_machine(
    graph: ModelGraph,
    document: object | None = None,
) -> str | None:
    """Return the adapter state machine usage name (e.g. hl7AdapterController)."""
    if document is not None and getattr(document, "exposed_elements", None):
        _, adapter_state = _find_root_adapter_from_exposed(
            graph, document.exposed_elements
        )
        if not adapter_state:
            _, adapter_state = _find_root_adapter_part_def(graph)
    else:
        _, adapter_state = _find_root_adapter_part_def(graph)
    return adapter_state


def _collect_states(graph: ModelGraph, machine_qname: str) -> list[str]:
    """Return child state names of a state machine, sorted."""
    children = graph.children(machine_qname, kind="state")
    return sorted(c.name for c in children)


def _collect_transitions(graph: ModelGraph, machine_qname: str) -> list[dict[str, str]]:
    """Return unique transitions from a state machine: [{signal, from_state, to_state, transition_action?}]."""
    seen: set[tuple[str, str, str]] = set()
    result: list[dict[str, str]] = []

    machine_node = graph.get(machine_qname)
    if not machine_node:
        return result

    children = graph.children(machine_qname, kind="state")

    all_edges: list[GraphEdge] = []
    for child in children:
        all_edges.extend(graph.outgoing(child.qname, "transition"))
    all_edges.extend(graph.outgoing(machine_qname, "transition"))

    for edge in all_edges:
        signal_name = edge.properties.get("signal_name", "")
        target = edge.target.split("::")[-1]
        source_name = edge.source.split("::")[-1]
        key = (signal_name, source_name, target)
        if key not in seen:
            seen.add(key)
            t_dict: dict[str, str] = {
                "signal": signal_name,
                "from_state": source_name,
                "to_state": target,
            }
            transition_action = edge.properties.get("transition_action")
            if transition_action:
                t_dict["transition_action"] = transition_action
            result.append(t_dict)

    result.sort(key=lambda t: (t["from_state"], t["signal"], t["to_state"]))
    return result


def get_part_property_for_action(
    graph: ModelGraph,
    adapter_qname: str,
    action_usage_name: str,
    document: object | None = None,
) -> str:
    """Return the adapter part property name (camelCase) that performs the given action usage, or empty string.

    Used by the service generator to emit this.<part>.<actionName>() when a transition has a transition_action.
    """
    component_map = get_component_map(graph, document=document)
    for comp in component_map:
        part_def_qname = comp.get("part_def_qname")
        if not part_def_qname:
            continue
        for edge in graph.outgoing(part_def_qname, "performs"):
            if edge.properties.get("usage_name") == action_usage_name:
                return _to_camel(comp["class_name"])
    # Adapter itself may perform the action (e.g. initialize); emit this.<actionName>() when part is ""
    adapter_node = graph.get(adapter_qname)
    if adapter_node:
        for edge in graph.outgoing(adapter_qname, "performs"):
            if edge.properties.get("usage_name") == action_usage_name:
                return ""
    return ""


def _find_psm_node(graph: ModelGraph, short_name: str, part_def_qname: str | None = None) -> GraphNode | None:
    """Find a part def by short name or by part_def_qname (from component map)."""
    if part_def_qname:
        return graph.get(part_def_qname)
    for node in graph.nodes.values():
        if node.kind not in ("part", "part def"):
            continue
        if node.short_name != short_name:
            continue
        for edge in graph.incoming(node.qname, "contains"):
            parent = graph.get(edge.source)
            if parent and parent.kind == "package":
                return node
    return None


def _collect_named_reps(node: GraphNode | None) -> dict[str, str]:
    """Return {rep_name: body} for all TypeScript reps on a PSM node."""
    if not node:
        return {}
    reps_raw = node.properties.get("textual_representations", [])
    return {
        r["name"]: r["body"]
        for r in reps_raw
        if (r.get("language") or "").lower() == "typescript"
    }


def _resolve_action_qname(graph: ModelGraph, type_ref: str, prefer_prefix: str | None) -> str | None:
    """Resolve an action type ref (e.g. Actions::HandleIntegrationError) to an action def qname.
    Used when edge target is an alias and not a graph node key."""
    if type_ref in graph.nodes:
        return type_ref
    last = type_ref.split("::")[-1].strip()
    if not last:
        return None
    candidates = [
        n.qname
        for n in graph.nodes.values()
        if n.kind == "action def"
        and (n.short_name == last or n.name == last)
    ]
    if not candidates:
        return None
    if prefer_prefix:
        for q in candidates:
            if q.startswith(prefer_prefix):
                return q
    return candidates[0]


def _collect_action_implementations(
    graph: ModelGraph, psm_node: GraphNode | None,
) -> list[tuple[str, str, bool, GraphNode | None]]:
    """Return [(action_name, ts_body, is_method, action_node)] for performed PSM action defs.

    ``is_method`` is True when the action def declares ``in self;``.
    For free functions, body is from ``functionBody`` rep if present, else ``textualRepresentation``.
    ``action_node`` is passed so the component builder can build the signature from action_params
    when body came from ``functionBody``.
    """
    if not psm_node:
        return []
    perform_decls = psm_node.properties.get("perform_actions", [])
    performs_edges = graph.outgoing(psm_node.qname, "performs")
    first_seg = (psm_node.qname or "").split("::")[0]
    prefer_prefix = (first_seg.split("_")[0] + "_") if first_seg else None
    target_map: dict[str, GraphNode] = {}
    for edge in performs_edges:
        action_qname = edge.target
        if action_qname and action_qname not in graph.nodes:
            action_qname = _resolve_action_qname(graph, edge.target or "", prefer_prefix)
        node = graph.get(action_qname) if action_qname else None
        if node:
            target_map[edge.properties.get("usage_name", "")] = node

    result: list[tuple[str, str, bool, GraphNode | None]] = []
    for decl in perform_decls:
        usage_name = decl["name"]
        action_node = target_map.get(usage_name)
        if not action_node:
            continue
        reps = _collect_named_reps(action_node)
        action_params = action_node.properties.get("action_params", [])
        is_method = any(p["name"] == "self" for p in action_params)
        # Prefer functionBody (body-only); fall back to full textualRepresentation for both methods and free functions
        body = (reps.get("functionBody") or reps.get("textualRepresentation") or "").strip()
        if not body:
            continue
        result.append((usage_name, body, is_method, action_node))
    return result


def get_free_function_export_names(graph: ModelGraph, psm_node: GraphNode | None) -> list[str]:
    """Return usage names of performed actions that are free functions (no in self).

    Used to derive test file imports from the existing perform action connection:
    the component module exports these as top-level functions.
    """
    if not psm_node:
        return []
    perform_decls = psm_node.properties.get("perform_actions", [])
    performs_edges = graph.outgoing(psm_node.qname, "performs")
    target_map: dict[str, GraphNode] = {}
    for edge in performs_edges:
        node = graph.get(edge.target)
        if node:
            target_map[edge.properties.get("usage_name", "")] = node

    result: list[str] = []
    for decl in perform_decls:
        usage_name = decl["name"]
        action_node = target_map.get(usage_name)
        if not action_node:
            continue
        action_params = action_node.properties.get("action_params", [])
        is_method = any(p.get("name") == "self" for p in action_params)
        if is_method:
            continue
        reps = _collect_named_reps(action_node)
        body = (reps.get("functionBody") or reps.get("textualRepresentation") or "").strip()
        if body:
            result.append(usage_name)
    return result


def _get_config_attributes(node: GraphNode) -> list[dict[str, str]]:
    """Extract config attributes from a PSM part node. Excludes attributes whose name starts with '_' (private instance fields).
    When the model specifies a default (e.g. 'Integer = 3000'), parses it so config.json can use it."""
    raw = node.properties.get("attributes", [])
    result = []
    for attr in raw:
        name = attr.get("name", "")
        if name.startswith("_"):
            continue
        raw_type = (attr.get("type") or "").strip()
        default: str | None = None
        if "=" in raw_type:
            type_part, default_part = raw_type.split("=", 1)
            raw_type = type_part.strip()
            default = default_part.strip()
        ts_type = _sysml_type_to_ts(raw_type)
        item: dict[str, str] = {"name": name, "type": ts_type}
        if default is not None:
            item["default"] = default
        result.append(item)
    return result


def _is_primitive_ts_type(ts_type: str) -> bool:
    """True if the TypeScript type is a primitive (string, number, boolean) or union with null."""
    t = ts_type.strip()
    if t in ("string", "number", "boolean"):
        return True
    if "|" in t:
        left = t.split("|")[0].strip()
        if left in ("string", "number", "boolean"):
            return True
    return False


def _get_instance_attributes(node: GraphNode) -> list[dict[str, str | bool]]:
    """Extract private instance attributes from a PSM part node (name starts with '_'). Returns name (with [*] stripped), type (TS), default, optional flag, and composite (true when type is another part/interface, needs constructor init)."""
    raw = node.properties.get("attributes", [])
    result: list[dict[str, str | bool]] = []
    for attr in raw:
        name = attr.get("name", "")
        if not name.startswith("_"):
            continue
        # Strip SysML multiplicity from name so we emit a valid TS identifier (e.g. _metrics[*] -> _metrics)
        name_clean = name.replace("[*]", "").replace("[0..1]", "").strip()
        raw_type = (attr.get("type") or "").strip()
        type_only = raw_type.split(" [0..1]")[0].strip().split("=")[0].strip()
        ts_type = _sysml_type_to_ts(type_only, pass_through_unknown=True)
        optional = " [0..1]" in raw_type or "[*]" in name
        composite = not _is_primitive_ts_type(ts_type)
        if optional and "string" in ts_type.lower():
            ts_type = "string | null"
            default = "null"
        elif optional:
            default = "null"
        else:
            default = "undefined"
        result.append({"name": name_clean, "type": ts_type, "default": default, "optional": optional, "composite": composite})
    return result
