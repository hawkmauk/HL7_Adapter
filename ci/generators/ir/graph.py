from __future__ import annotations

from dataclasses import dataclass, field
from typing import Any

from .document import SourceRef


@dataclass(slots=True)
class GraphNode:
    """One element in the SysML model (package, part, port, state, view, ...)."""
    qname: str
    kind: str
    name: str
    short_name: str | None
    doc: str
    properties: dict[str, Any] = field(default_factory=dict)
    source: SourceRef | None = None


@dataclass(slots=True)
class GraphEdge:
    """Directed labelled relationship between two nodes."""
    source: str
    target: str
    label: str
    properties: dict[str, Any] = field(default_factory=dict)


class ModelGraph:
    """Directed labelled graph over the entire SysML model."""

    __slots__ = ("nodes", "edges", "_out", "_in", "_children")

    def __init__(self) -> None:
        self.nodes: dict[str, GraphNode] = {}
        self.edges: list[GraphEdge] = []
        self._out: dict[str, list[GraphEdge]] = {}
        self._in: dict[str, list[GraphEdge]] = {}
        self._children: dict[str, list[str]] = {}

    # -- mutators -----------------------------------------------------------

    def add_node(self, node: GraphNode) -> None:
        self.nodes[node.qname] = node
        self._out.setdefault(node.qname, [])
        self._in.setdefault(node.qname, [])

    def add_edge(self, edge: GraphEdge) -> None:
        self.edges.append(edge)
        self._out.setdefault(edge.source, []).append(edge)
        self._in.setdefault(edge.target, []).append(edge)
        if edge.label == "contains":
            self._children.setdefault(edge.source, []).append(edge.target)

    # -- queries ------------------------------------------------------------

    def outgoing(self, qname: str, label: str | None = None) -> list[GraphEdge]:
        edges = self._out.get(qname, [])
        if label is not None:
            return [e for e in edges if e.label == label]
        return list(edges)

    def incoming(self, qname: str, label: str | None = None) -> list[GraphEdge]:
        edges = self._in.get(qname, [])
        if label is not None:
            return [e for e in edges if e.label == label]
        return list(edges)

    def children(self, qname: str, kind: str | None = None) -> list[GraphNode]:
        child_qnames = self._children.get(qname, [])
        nodes = [self.nodes[q] for q in child_qnames if q in self.nodes]
        if kind is not None:
            return [n for n in nodes if n.kind == kind]
        return nodes

    def descendants(self, qname: str, kind: str | None = None) -> list[GraphNode]:
        result: list[GraphNode] = []
        stack = list(self._children.get(qname, []))
        while stack:
            cq = stack.pop()
            node = self.nodes.get(cq)
            if node is None:
                continue
            if kind is None or node.kind == kind:
                result.append(node)
            stack.extend(self._children.get(cq, []))
        return result

    def nodes_of_kind(self, kind: str) -> list[GraphNode]:
        return [n for n in self.nodes.values() if n.kind == kind]

    def get(self, qname: str) -> GraphNode | None:
        return self.nodes.get(qname)
