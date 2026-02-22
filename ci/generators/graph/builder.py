"""Build a ModelGraph from a parsed ModelIndex.

Walks every ModelElement and creates GraphNodes + typed GraphEdges
(containment, supertype, transition, satisfy, expose, etc.) so that
downstream targets can query the model as a directed labelled graph.
"""
from __future__ import annotations

from ..ir import GraphEdge, GraphNode, ModelGraph, SourceRef
from ..parsing import ModelElement, ModelIndex


def build_model_graph(index: ModelIndex) -> ModelGraph:
    graph = ModelGraph()

    for elem in index.elements:
        _add_node(graph, elem)

    for elem in index.elements:
        _add_containment(graph, elem)
        _add_supertypes(graph, elem)
        _add_transitions(graph, elem, index)
        _add_entry_do(graph, elem)
        _add_satisfy(graph, elem)
        _add_expose(graph, elem)
        _add_state_ports(graph, elem)
        _add_perform_actions(graph, elem)
        _add_verify_refs(graph, elem)
        _add_subject_ref(graph, elem)
        _add_exhibit_refs(graph, elem)

    return graph


def _source_ref(elem: ModelElement) -> SourceRef:
    return SourceRef(
        file_path=elem.file_path,
        start_line=elem.start_line,
        end_line=elem.end_line,
    )


def _add_node(graph: ModelGraph, elem: ModelElement) -> None:
    props: dict = {}
    if elem.attributes:
        props["attributes"] = [
            {"name": a.name, "type": a.type} for a in elem.attributes
        ]
    if getattr(elem, "constants", None):
        props["constants"] = [
            {"name": n, "type": t, "value": v} for n, t, v in elem.constants
        ]
    if elem.flow_properties:
        props["flow_properties"] = [
            {"direction": d, "kind": k, "name": n, "type": t}
            for d, k, n, t in elem.flow_properties
        ]
    if elem.interface_ends:
        props["interface_ends"] = [
            {"role": r, "port_type": pt} for r, pt in elem.interface_ends
        ]
    if elem.value_assignments:
        props["value_assignments"] = list(elem.value_assignments)
    if elem.weight_assignments:
        props["weight_assignments"] = list(elem.weight_assignments)
    if elem.allocation_satisfy:
        props["allocation_satisfy"] = [
            {"requirement": r, "block": b} for r, b in elem.allocation_satisfy
        ]
    if elem.refinement_dependencies:
        props["refinement_dependencies"] = [
            {"pim": p, "cim": c} for p, c in elem.refinement_dependencies
        ]
    if elem.constraint_params:
        props["constraint_params"] = [
            {"name": n, "type": t} for n, t in elem.constraint_params
        ]
    if elem.render_kind:
        props["render_kind"] = elem.render_kind
    if elem.aliases:
        props["aliases"] = [{"alias": a, "target": t} for a, t in elem.aliases]
    if elem.entry_target:
        props["entry_target"] = elem.entry_target
    if elem.entry_action:
        props["entry_action"] = elem.entry_action
    if elem.do_action:
        props["do_action"] = elem.do_action
    if elem.state_ports:
        props["state_ports"] = [
            {"direction": d, "name": n, "type": t}
            for d, n, t in elem.state_ports
        ]
    if getattr(elem, "textual_representations", None):
        props["textual_representations"] = [
            {"name": n, "language": l, "body": b}
            for n, l, b in elem.textual_representations
        ]
    if getattr(elem, "perform_actions", None):
        props["perform_actions"] = [
            {"name": n, "type": t}
            for n, t in elem.perform_actions
        ]
    if getattr(elem, "action_params", None):
        props["action_params"] = [
            {"dir": d, "name": n, "type": t} for d, n, t in elem.action_params
        ]
    if elem.kind == "verification def":
        if getattr(elem, "verify_refs", None):
            props["verify_refs"] = list(elem.verify_refs)
        if getattr(elem, "subject_ref", None):
            props["subject_ref"] = {"name": elem.subject_ref[0], "type": elem.subject_ref[1]}
    if getattr(elem, "exhibit_refs", None):
        props["exhibit_refs"] = list(elem.exhibit_refs)
    if elem.kind == "enum def" and getattr(elem, "enum_literals", None):
        props["enum_literals"] = list(elem.enum_literals)

    graph.add_node(
        GraphNode(
            qname=elem.qualified_name,
            kind=elem.kind,
            name=elem.name,
            short_name=elem.short_name,
            doc=elem.doc,
            properties=props,
            source=_source_ref(elem),
        )
    )


def _parent_qname(qname: str) -> str | None:
    parts = qname.rsplit("::", 1)
    return parts[0] if len(parts) > 1 else None


def _add_containment(graph: ModelGraph, elem: ModelElement) -> None:
    parent = _parent_qname(elem.qualified_name)
    if parent and parent in graph.nodes:
        graph.add_edge(GraphEdge(source=parent, target=elem.qualified_name, label="contains"))


def _add_supertypes(graph: ModelGraph, elem: ModelElement) -> None:
    for st in elem.supertypes:
        target_qname = _resolve_name(graph, elem, st)
        if target_qname:
            graph.add_edge(GraphEdge(source=elem.qualified_name, target=target_qname, label="supertype"))
        else:
            graph.add_edge(GraphEdge(
                source=elem.qualified_name,
                target=st,
                label="supertype",
                properties={"unresolved": True},
            ))


def _add_transitions(graph: ModelGraph, elem: ModelElement, index: ModelIndex) -> None:
    if elem.kind != "state" or not elem.transitions:
        return
    for from_state_name, signal_name, target_name, transition_action in elem.transitions:
        signal_qname = _resolve_name(graph, elem, signal_name)
        from_qname = _resolve_sibling_state(graph, elem, from_state_name)
        target_qname = _resolve_sibling_state(graph, elem, target_name)
        props: dict = {
            "signal": signal_qname or signal_name,
            "signal_name": signal_name,
            "machine": elem.qualified_name,
        }
        if transition_action:
            props["transition_action"] = transition_action
        graph.add_edge(GraphEdge(
            source=from_qname or f"{elem.qualified_name}::{from_state_name}",
            target=target_qname or target_name,
            label="transition",
            properties=props,
        ))


def _add_entry_do(graph: ModelGraph, elem: ModelElement) -> None:
    if elem.kind != "state":
        return
    if elem.entry_action:
        action_qname = _resolve_name(graph, elem, elem.entry_action)
        graph.add_edge(GraphEdge(
            source=elem.qualified_name,
            target=action_qname or elem.entry_action,
            label="entry_action",
        ))
    if elem.do_action:
        action_qname = _resolve_name(graph, elem, elem.do_action)
        graph.add_edge(GraphEdge(
            source=elem.qualified_name,
            target=action_qname or elem.do_action,
            label="do_action",
        ))
    if elem.entry_target:
        target_qname = _resolve_sibling_state(graph, elem, elem.entry_target)
        graph.add_edge(GraphEdge(
            source=elem.qualified_name,
            target=target_qname or elem.entry_target,
            label="initial_transition",
        ))


def _add_satisfy(graph: ModelGraph, elem: ModelElement) -> None:
    for ref in elem.satisfy_refs:
        graph.add_edge(GraphEdge(source=elem.qualified_name, target=ref.strip(), label="satisfy"))


def _add_expose(graph: ModelGraph, elem: ModelElement) -> None:
    for ref in elem.expose_refs:
        graph.add_edge(GraphEdge(source=elem.qualified_name, target=ref.strip(), label="expose"))


def _add_state_ports(graph: ModelGraph, elem: ModelElement) -> None:
    if elem.kind != "state" or not elem.state_ports:
        return
    for direction, name, port_type in elem.state_ports:
        graph.add_edge(GraphEdge(
            source=elem.qualified_name,
            target=port_type,
            label="state_port",
            properties={"direction": direction, "name": name},
        ))


def _add_perform_actions(graph: ModelGraph, elem: ModelElement) -> None:
    if elem.kind not in ("part", "part def") or not getattr(elem, "perform_actions", None):
        return
    for _name, action_type in elem.perform_actions:
        target_qname = _resolve_name(graph, elem, action_type)
        graph.add_edge(GraphEdge(
            source=elem.qualified_name,
            target=target_qname or action_type,
            label="performs",
            properties={"usage_name": _name},
        ))


def _add_verify_refs(graph: ModelGraph, elem: ModelElement) -> None:
    if elem.kind != "verification def" or not getattr(elem, "verify_refs", None):
        return
    for ref in elem.verify_refs:
        target_qname = _resolve_name(graph, elem, ref.strip())
        graph.add_edge(GraphEdge(
            source=elem.qualified_name,
            target=target_qname or ref.strip(),
            label="verify",
        ))


def _add_subject_ref(graph: ModelGraph, elem: ModelElement) -> None:
    if elem.kind != "verification def" or not getattr(elem, "subject_ref", None):
        return
    _name, type_ref = elem.subject_ref
    target_qname = _resolve_name(graph, elem, type_ref.strip())
    graph.add_edge(GraphEdge(
        source=elem.qualified_name,
        target=target_qname or type_ref.strip(),
        label="subject",
        properties={"subject_name": _name},
    ))


def _add_exhibit_refs(graph: ModelGraph, elem: ModelElement) -> None:
    if elem.kind not in ("part", "part def") or not getattr(elem, "exhibit_refs", None):
        return
    for ref in elem.exhibit_refs:
        target_qname = _resolve_exhibit_target(graph, elem, ref.strip())
        graph.add_edge(GraphEdge(
            source=elem.qualified_name,
            target=target_qname or ref.strip(),
            label="exhibit",
        ))


def _resolve_exhibit_target(graph: ModelGraph, context: ModelElement, name: str) -> str | None:
    """Resolve an exhibit reference, preferring state nodes over part nodes."""
    candidates: list[str] = []
    for node in graph.nodes.values():
        if node.name == name or node.short_name == name:
            candidates.append(node.qname)
    if not candidates:
        return _resolve_name(graph, context, name)
    state_candidates = [q for q in candidates if graph.nodes[q].kind == "state"]
    if state_candidates:
        return state_candidates[0]
    return candidates[0]


def _resolve_name(graph: ModelGraph, context: ModelElement, name: str) -> str | None:
    """Try to resolve a short name to a qualified name in the graph, searching from the context outward."""
    if name in graph.nodes:
        return name

    parent = _parent_qname(context.qualified_name)
    while parent:
        candidate = f"{parent}::{name}"
        if candidate in graph.nodes:
            return candidate
        parent = _parent_qname(parent)

    # Qualified reference (e.g. PSM_HTTPForwarder_Actions::SendJSONPayload): match by prefix + short_name
    if "::" in name:
        prefix, local = name.rsplit("::", 1)
        for node in graph.nodes.values():
            node_parent = _parent_qname(node.qname)
            if node_parent == prefix and (local == (node.short_name or node.name)):
                return node.qname
            if node.qname == name:
                return node.qname

    for node in graph.nodes.values():
        if node.name == name or node.short_name == name:
            return node.qname

    return None


def _resolve_sibling_state(graph: ModelGraph, context: ModelElement, name: str) -> str | None:
    """Resolve a state name as a child of the current state machine."""
    candidate = f"{context.qualified_name}::{name}"
    if candidate in graph.nodes:
        return candidate
    parent = _parent_qname(context.qualified_name)
    if parent:
        candidate = f"{parent}::{name}"
        if candidate in graph.nodes:
            return candidate
    return _resolve_name(graph, context, name)
