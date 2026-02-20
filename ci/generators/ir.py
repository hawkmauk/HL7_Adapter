from __future__ import annotations

from dataclasses import dataclass, field
from pathlib import Path


@dataclass(slots=True)
class SourceRef:
    file_path: Path
    start_line: int
    end_line: int


@dataclass(slots=True)
class ViewBinding:
    satisfy_refs: list[str] = field(default_factory=list)
    expose_refs: list[str] = field(default_factory=list)
    render_kind: str | None = None


@dataclass(slots=True)
class ExposedElement:
    qualified_name: str
    kind: str
    name: str
    package_path: tuple[str, ...]
    doc: str
    attributes: list["AttributeIR"] = field(default_factory=list)
    flow_properties: list["FlowPropertyIR"] = field(default_factory=list)
    interface_ends: list["InterfaceEndIR"] = field(default_factory=list)
    constraint_params: list[tuple[str, str]] = field(default_factory=list)  # (name, type) for constraint def
    supertypes: list[str] = field(default_factory=list)  # part/view supertypes for filtering (e.g. Scored*Alternative)
    value_assignments: list[float] = field(default_factory=list)  # attribute ::> value = N (for score)
    weight_assignments: list[float] = field(default_factory=list)  # attribute ::> weight = N (for score)


@dataclass(slots=True)
class SectionIR:
    """Represents a logical document section derived from a section view."""

    id: str
    title: str
    depth: int
    intro: str
    exposed_elements: list[ExposedElement] = field(default_factory=list)


@dataclass(slots=True)
class AllocationRowIR:
    """One row in the allocation traceability matrix (requirement -> logical block, optional CIM derive)."""
    requirement: str
    logical_block: str
    cim_derive: str | None = None


@dataclass(slots=True)
class DocumentIR:
    document_id: str
    title: str
    abstraction_level: str
    purpose: str
    source: SourceRef
    binding: ViewBinding
    exposed_elements: list[ExposedElement] = field(default_factory=list)
    coverage_refs: list[str] = field(default_factory=list)
    sections: list[SectionIR] = field(default_factory=list)
    allocation_matrix: list[AllocationRowIR] = field(default_factory=list)


@dataclass(slots=True)
class CoverageEntry:
    coverage_id: str
    stakeholder_ids: list[str]
    concern_ids: list[str]
    viewpoint_ids: list[str]
    viewport_ids: list[str]
    document_codes: list[str]
    source: SourceRef


@dataclass(slots=True)
class FlowPropertyIR:
    """Single flow property on a port (item or signal/attribute)."""
    direction: str  # "in" | "out"
    kind: str       # "item" | "attribute"
    name: str
    type: str | None


@dataclass(slots=True)
class InterfaceEndIR:
    """One end of an interface (role and port type)."""
    role: str
    port_type: str


@dataclass(slots=True)
class AttributeIR:
    name: str
    type: str | None
    doc: str = ""
