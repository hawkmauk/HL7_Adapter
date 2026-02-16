from __future__ import annotations

from dataclasses import dataclass, field
import re

from .ir import CoverageEntry, DocumentIR, ExposedElement, SourceRef, ViewBinding
from .parser import ModelElement, ModelIndex


ID_RE = {
    "stakeholder": re.compile(r"\b(STK_[A-Za-z0-9_]+)\b"),
    "concern": re.compile(r"\b(CON_[A-Za-z0-9_]+)\b"),
    "viewpoint": re.compile(r"\b(VP_[A-Za-z0-9_]+)\b"),
    "viewport": re.compile(r"\b(VPT_[A-Za-z0-9_]+)\b"),
    "document_code": re.compile(r"\b([A-Z]{3,8})\b"),
}


@dataclass(slots=True)
class ExtractionResult:
    documents: list[DocumentIR]
    coverage_entries: list[CoverageEntry]
    unresolved_hints: list[str] = field(default_factory=list)


def _title_from_id(document_id: str) -> str:
    base = document_id.removeprefix("DOC_CIM_")
    parts = base.split("_")
    return " ".join(parts)


def _abstraction_level(document_id: str) -> str:
    if "_CIM_" in document_id:
        return "CIM"
    if "_PIM_" in document_id:
        return "PIM"
    if "_PSM_" in document_id:
        return "PSM"
    return "UNKNOWN"


def _by_reference(ref: str, model_index: ModelIndex) -> list[ModelElement]:
    clean_ref = ref.strip()
    if not clean_ref:
        return []
    if clean_ref in model_index.by_qualified_name:
        return [model_index.by_qualified_name[clean_ref]]

    by_name = model_index.by_name.get(clean_ref, [])
    if by_name:
        return sorted(by_name, key=lambda item: item.qualified_name)

    suffix = f"::{clean_ref}"
    candidates = [
        element
        for element in model_index.elements
        if element.qualified_name == clean_ref or element.qualified_name.endswith(suffix)
    ]
    return sorted(candidates, key=lambda item: item.qualified_name)


def _resolve_expose_elements(expose_refs: list[str], model_index: ModelIndex) -> list[ExposedElement]:
    resolved: dict[str, ExposedElement] = {}
    pending_refs = list(expose_refs)
    processed_refs: set[str] = set()
    expanded_views: set[str] = set()

    while pending_refs:
        ref = pending_refs.pop(0).strip()
        if not ref:
            continue
        if ref in processed_refs:
            continue
        processed_refs.add(ref)

        if ref.endswith("::**"):
            prefix_ref = ref[:-4].strip()
            roots = _by_reference(prefix_ref, model_index)
            candidates: list[ModelElement] = []
            for root in roots:
                prefix = root.qualified_name + "::"
                candidates.extend(
                    [
                        element
                        for element in model_index.elements
                        if element.qualified_name == root.qualified_name
                        or element.qualified_name.startswith(prefix)
                    ]
                )
        else:
            candidates = _by_reference(ref, model_index)

        for candidate in candidates:
            package_path = tuple(candidate.qualified_name.split("::")[:-1])
            resolved[candidate.qualified_name] = ExposedElement(
                qualified_name=candidate.qualified_name,
                kind=candidate.kind,
                name=candidate.name,
                package_path=package_path,
                doc=candidate.doc,
            )
            # If an exposed element is itself a view, include what it exposes.
            if candidate.kind == "view" and candidate.qualified_name not in expanded_views:
                expanded_views.add(candidate.qualified_name)
                for nested_ref in candidate.expose_refs:
                    pending_refs.append(nested_ref.strip())

    return sorted(resolved.values(), key=lambda item: item.qualified_name)


def _extract_document_ir(element: ModelElement, model_index: ModelIndex) -> DocumentIR:
    coverage_refs = []
    for ref in element.expose_refs:
        if "CM_" in ref:
            coverage_refs.append(ref.split("::")[-1].strip())

    return DocumentIR(
        document_id=element.name,
        title=_title_from_id(element.name),
        abstraction_level=_abstraction_level(element.name),
        purpose=element.doc,
        source=SourceRef(
            file_path=element.file_path,
            start_line=element.start_line,
            end_line=element.end_line,
        ),
        binding=ViewBinding(
            satisfy_refs=[ref.strip() for ref in element.satisfy_refs],
            expose_refs=[ref.strip() for ref in element.expose_refs],
            render_kind=element.render_kind,
        ),
        exposed_elements=_resolve_expose_elements(element.expose_refs, model_index),
        coverage_refs=coverage_refs,
    )


def _extract_coverage_entry(element: ModelElement) -> CoverageEntry:
    text = element.doc
    stakeholder_ids = sorted(set(ID_RE["stakeholder"].findall(text)))
    concern_ids = sorted(set(ID_RE["concern"].findall(text)))
    viewpoint_ids = sorted(set(ID_RE["viewpoint"].findall(text)))
    viewport_ids = sorted(set(ID_RE["viewport"].findall(text)))
    document_codes = sorted(set(ID_RE["document_code"].findall(text)))

    return CoverageEntry(
        coverage_id=element.name,
        stakeholder_ids=stakeholder_ids,
        concern_ids=concern_ids,
        viewpoint_ids=viewpoint_ids,
        viewport_ids=viewport_ids,
        document_codes=document_codes,
        source=SourceRef(
            file_path=element.file_path,
            start_line=element.start_line,
            end_line=element.end_line,
        ),
    )


def extract_documents(model_index: ModelIndex) -> ExtractionResult:
    doc_elements = [
        element
        for element in model_index.elements
        if element.kind == "view" and element.name.startswith("DOC_CIM_")
    ]
    doc_elements.sort(key=lambda item: item.name)

    coverage_elements = [
        element
        for element in model_index.elements
        if element.kind == "requirement" and element.name.startswith("CM_")
    ]
    coverage_elements.sort(key=lambda item: item.name)

    documents = [_extract_document_ir(item, model_index) for item in doc_elements]
    coverage_entries = [_extract_coverage_entry(item) for item in coverage_elements]
    return ExtractionResult(documents=documents, coverage_entries=coverage_entries)
