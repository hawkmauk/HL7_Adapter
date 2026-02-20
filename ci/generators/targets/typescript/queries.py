"""Graph query helpers and constants for TypeScript generation."""
from __future__ import annotations

from ...ir import GraphEdge, GraphNode, ModelGraph
from .naming import _sysml_type_to_ts


PSM_PKG = "PSM_PhysicalArchitecture"
PIM_BEHAVIOR_PKG = "PIM_Behavior"

COMPONENT_MAP: list[dict[str, str]] = [
    {
        "psm_short": "MLLPReceiver",
        "state_machine": "mllpReceiver",
        "output_file": "mllp_receiver.ts",
        "class_name": "MllpReceiver",
    },
    {
        "psm_short": "Parser",
        "state_machine": "hl7Handler",
        "output_file": "parser.ts",
        "class_name": "Hl7Parser",
    },
    {
        "psm_short": "Transformer",
        "state_machine": "hl7Transformer",
        "output_file": "transformer.ts",
        "class_name": "Hl7Transformer",
    },
    {
        "psm_short": "HTTPForwarder",
        "state_machine": "httpForwarder",
        "output_file": "http_forwarder.ts",
        "class_name": "HttpForwarder",
    },
    {
        "psm_short": "ErrorHandler",
        "state_machine": "errorHandler",
        "output_file": "error_handler.ts",
        "class_name": "ErrorHandler",
    },
]

ADAPTER_STATE_MACHINE = "hl7AdapterController"
ADAPTER_PSM_SHORT = "HL7AdapterService"


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


def _find_psm_node(graph: ModelGraph, short_name: str) -> GraphNode | None:
    """Find a PSM part def by short name."""
    for node in graph.nodes_of_kind("part"):
        if node.qname.startswith(PSM_PKG + "::") and node.short_name == short_name:
            return node
    return None


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
