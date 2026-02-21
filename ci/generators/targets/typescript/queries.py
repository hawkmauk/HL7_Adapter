"""Graph query helpers for TypeScript generation.

All component-to-state-machine mappings are derived from the model graph
via ``exhibit`` edges (part def --exhibit--> state usage) rather than
hardcoded lookup tables.
"""
from __future__ import annotations

from ...ir import ExposedElement, GraphEdge, GraphNode, ModelGraph
from .naming import _display_name_to_class_name, _sysml_type_to_ts


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
    return type_ref if type_ref in graph.nodes else candidates[0]


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


def get_adapter_state_machine(
    graph: ModelGraph,
    document: object | None = None,
) -> str | None:
    """Return the adapter state machine usage name (e.g. hl7AdapterController)."""
    if document is not None and getattr(document, "exposed_elements", None):
        _, adapter_state = _find_root_adapter_from_exposed(
            graph, document.exposed_elements
        )
    else:
        _, adapter_state = _find_root_adapter_part_def(graph)
    return adapter_state


def _collect_states(graph: ModelGraph, machine_qname: str) -> list[str]:
    """Return child state names of a state machine, sorted."""
    children = graph.children(machine_qname, kind="state")
    return sorted(c.name for c in children)


def _collect_transitions(graph: ModelGraph, machine_qname: str) -> list[dict[str, str]]:
    """Return unique transitions from a state machine: [{signal, from_state, to_state}]."""
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
            result.append({
                "signal": signal_name,
                "from_state": source_name,
                "to_state": target,
            })

    result.sort(key=lambda t: (t["from_state"], t["signal"], t["to_state"]))
    return result


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
    target_map: dict[str, GraphNode] = {}
    for edge in performs_edges:
        node = graph.get(edge.target)
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
        # Free functions: prefer functionBody (body-only); methods: use full textualRepresentation
        if is_method:
            body = reps.get("textualRepresentation", "").strip()
        else:
            body = (reps.get("functionBody") or reps.get("textualRepresentation") or "").strip()
        if not body:
            continue
        result.append((usage_name, body, is_method, action_node))
    return result


def _get_config_attributes(node: GraphNode) -> list[dict[str, str]]:
    """Extract config attributes from a PSM part node."""
    raw = node.properties.get("attributes", [])
    result = []
    for attr in raw:
        name = attr.get("name", "")
        raw_type = attr.get("type", "")
        ts_type = _sysml_type_to_ts(raw_type)
        result.append({"name": name, "type": ts_type})
    return result
