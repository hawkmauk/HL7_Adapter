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


@dataclass(slots=True)
class CoverageEntry:
    coverage_id: str
    stakeholder_ids: list[str]
    concern_ids: list[str]
    viewpoint_ids: list[str]
    viewport_ids: list[str]
    document_codes: list[str]
    source: SourceRef
