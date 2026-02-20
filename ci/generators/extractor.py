from __future__ import annotations

from dataclasses import dataclass, field
from typing import Callable, Iterable, Sequence
import re

from .ir import (
    AllocationRowIR,
    AttributeIR,
    CoverageEntry,
    DocumentIR,
    ExposedElement,
    FlowPropertyIR,
    InterfaceEndIR,
    SectionIR,
    SourceRef,
    ViewBinding,
)
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
    base = (
        document_id.removeprefix("DOC_CIM_")
        .removeprefix("DOC_PIM_")
        .removeprefix("DOC_PSM_")
    )
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


def _expand_alias_ref(ref: str, model_index: ModelIndex) -> str:
    """Expand alias prefixes so CIM::Domain -> CIM_Domain, CIM::Domain::** -> CIM_Domain::**."""
    alias_map = getattr(model_index, "alias_map", None) or {}
    if not alias_map:
        return ref
    # Longest key first so we match CIM::Domain before CIM
    for key in sorted(alias_map.keys(), key=len, reverse=True):
        if ref == key:
            return alias_map[key]
        if ref.startswith(key + "::"):
            return alias_map[key] + ref[len(key) :]
    return ref


def _by_reference(ref: str, model_index: ModelIndex) -> list[ModelElement]:
    clean_ref = ref.strip()
    if not clean_ref:
        return []
    expanded = _expand_alias_ref(clean_ref, model_index)
    if expanded in model_index.by_qualified_name:
        return [model_index.by_qualified_name[expanded]]

    by_name = model_index.by_name.get(expanded, [])
    if by_name:
        return sorted(by_name, key=lambda item: item.qualified_name)

    suffix = f"::{expanded}"
    candidates = [
        element
        for element in model_index.elements
        if element.qualified_name == expanded or element.qualified_name.endswith(suffix)
    ]
    return sorted(candidates, key=lambda item: item.qualified_name)


def _title_from_expose_refs(expose_refs: list[str]) -> str | None:
    """Derive a section title from the first expose ref (e.g. CIM::Actions::** -> Actions)."""
    if not expose_refs:
        return None
    ref = expose_refs[0].strip()
    if ref.endswith("::**"):
        ref = ref[:-4].strip()
    elif ref.endswith("::*"):
        ref = ref[:-3].strip()
    parts = ref.split("::")
    return parts[-1] if parts else None


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
            flow_props = [
                FlowPropertyIR(direction=d, kind=k, name=n, type=t)
                for d, k, n, t in getattr(candidate, "flow_properties", [])
            ]
            interface_ends_ir = [
                InterfaceEndIR(role=r, port_type=pt)
                for r, pt in getattr(candidate, "interface_ends", [])
            ]
            constraint_params = list(getattr(candidate, "constraint_params", []))
            supertypes = list(getattr(candidate, "supertypes", []))
            value_assignments = list(getattr(candidate, "value_assignments", []))
            weight_assignments = list(getattr(candidate, "weight_assignments", []))
            resolved[candidate.qualified_name] = ExposedElement(
                qualified_name=candidate.qualified_name,
                kind=candidate.kind,
                name=candidate.name,
                package_path=package_path,
                doc=candidate.doc,
                attributes=[
                    AttributeIR(name=attr.name, type=attr.type, doc="")
                    for attr in getattr(candidate, "attributes", [])
                ],
                flow_properties=flow_props,
                interface_ends=interface_ends_ir,
                constraint_params=constraint_params,
                supertypes=supertypes,
                value_assignments=value_assignments,
                weight_assignments=weight_assignments,
            )
            # If an exposed element is itself a view, include what it exposes.
            if candidate.kind == "view" and candidate.qualified_name not in expanded_views:
                expanded_views.add(candidate.qualified_name)
                for nested_ref in candidate.expose_refs:
                    pending_refs.append(nested_ref.strip())

    return sorted(resolved.values(), key=lambda item: item.qualified_name)


def _collect_section_irs_for_document(
    element: ModelElement, model_index: ModelIndex
) -> list[SectionIR]:
    """
    If the document view is typed by a document template (e.g. ConOps_Document),
    collect nested section views from that template and turn them into SectionIRs.
    """

    # Identify the template view this document is typed by, if any.
    template: ModelElement | None = None
    for super_name in element.supertypes:
        candidates = model_index.by_name.get(super_name, [])
        for candidate in candidates:
            if candidate.kind == "view":
                template = candidate
                break
        if template is not None:
            break

    if template is None:
        return []

    # Section views are nested view blocks within the template's body.
    nested_views: list[ModelElement] = [
        item
        for item in model_index.elements
        if item.kind == "view"
        and item.file_path == template.file_path
        and template.start_index < item.start_index < item.end_index < template.end_index
    ]
    nested_views.sort(key=lambda item: item.start_index)

    sections: list[SectionIR] = []
    for section_elem in nested_views:
        exposed = _resolve_expose_elements(section_elem.expose_refs, model_index)
        # Prefer title from expose ref package name (e.g. CIM::Actions::** -> "Actions")
        title_from_ref = _title_from_expose_refs(section_elem.expose_refs)
        display_name = section_elem.name.strip("'")
        title = title_from_ref if title_from_ref else display_name
        sections.append(
            SectionIR(
                id=section_elem.short_name or section_elem.name,
                title=title,
                depth=1,  # Top-level document sections
                intro=section_elem.doc,
                exposed_elements=exposed,
            )
        )

    return sections


def _extract_document_ir(element: ModelElement, model_index: ModelIndex) -> DocumentIR:
    coverage_refs: list[str] = []
    for ref in element.expose_refs:
        if "CM_" in ref:
            coverage_refs.append(ref.split("::")[-1].strip())

    # Base exposed elements come from the document view's own expose refs
    # (e.g. DOC_CIM_* bindings to viewports and coverage requirements).
    base_exposed = _resolve_expose_elements(element.expose_refs, model_index)

    # Sections are derived from the document template (e.g. ConOps_Document)
    # and each section has its own resolved exposed elements.
    sections = _collect_section_irs_for_document(element, model_index)

    # For backwards compatibility, keep DocumentIR.exposed_elements as the union
    # of the document-level exposure and all section-level elements.
    if sections:
        by_qname: dict[str, ExposedElement] = {item.qualified_name: item for item in base_exposed}
        for section in sections:
            for exposed in section.exposed_elements:
                by_qname.setdefault(exposed.qualified_name, exposed)
        exposed_elements = sorted(by_qname.values(), key=lambda item: item.qualified_name)
    else:
        exposed_elements = base_exposed

    # Special handling for CIM Operational Scenarios: also include CIM::UseCases.*
    # so that CIM-level use case narratives can be rendered in the document even
    # though the current view definition exposes CIM::Operations only.
    if element.name == "DOC_CIM_OperationalScenarios":
        for model_el in model_index.elements:
            if model_el.kind == "use case" and model_el.qualified_name.startswith("CIM::UseCases::"):
                package_path = tuple(model_el.qualified_name.split("::")[:-1])
                qname = model_el.qualified_name
                if not any(e.qualified_name == qname for e in exposed_elements):
                    exposed_elements.append(
                        ExposedElement(
                            qualified_name=qname,
                            kind=model_el.kind,
                            name=model_el.name,
                            package_path=package_path,
                            doc=model_el.doc,
                            attributes=[
                                AttributeIR(name=attr.name, type=attr.type, doc="")
                                for attr in getattr(model_el, "attributes", [])
                            ],
                            constraint_params=list(getattr(model_el, "constraint_params", [])),
                            supertypes=list(getattr(model_el, "supertypes", [])),
                            value_assignments=list(getattr(model_el, "value_assignments", [])),
                            weight_assignments=list(getattr(model_el, "weight_assignments", [])),
                        )
                    )
        exposed_elements = sorted(exposed_elements, key=lambda item: item.qualified_name)

    # Special handling for CIM ConOps: include CIM::Events::* occurrences so they
    # can be rendered in the document even if not explicitly exposed yet.
    if element.name == "DOC_CIM_ConOps":
        for model_el in model_index.elements:
            if model_el.kind == "occurrence" and model_el.qualified_name.startswith("CIM::Events::"):
                package_path = tuple(model_el.qualified_name.split("::")[:-1])
                qname = model_el.qualified_name
                if not any(e.qualified_name == qname for e in exposed_elements):
                    flow_props = [
                        FlowPropertyIR(direction=d, kind=k, name=n, type=t)
                        for d, k, n, t in getattr(model_el, "flow_properties", [])
                    ]
                    interface_ends_ir = [
                        InterfaceEndIR(role=r, port_type=pt)
                        for r, pt in getattr(model_el, "interface_ends", [])
                    ]
                    constraint_params = list(getattr(model_el, "constraint_params", []))
                    exposed_elements.append(
                        ExposedElement(
                            qualified_name=qname,
                            kind=model_el.kind,
                            name=model_el.name,
                            package_path=package_path,
                            doc=model_el.doc,
                            attributes=[
                                AttributeIR(name=attr.name, type=attr.type, doc="")
                                for attr in getattr(model_el, "attributes", [])
                            ],
                            flow_properties=flow_props,
                            interface_ends=interface_ends_ir,
                            constraint_params=constraint_params,
                            supertypes=list(getattr(model_el, "supertypes", [])),
                            value_assignments=list(getattr(model_el, "value_assignments", [])),
                            weight_assignments=list(getattr(model_el, "weight_assignments", [])),
                        )
                    )
        exposed_elements = sorted(exposed_elements, key=lambda item: item.qualified_name)

    # DOC_PIM_Allocation: build traceability matrix from satisfy + refinement in PIM_Allocations.
    allocation_matrix: list[AllocationRowIR] = []
    if element.name == "DOC_PIM_Allocation":
        refinement_map: dict[str, str] = {}
        allocation_elements = [
            e for e in model_index.elements
            if e.qualified_name.startswith("PIM_Allocations") or e.qualified_name == "PIM_Allocations"
        ]
        for model_el in allocation_elements:
            for pim_req, cim_req in getattr(model_el, "refinement_dependencies", []):
                refinement_map[pim_req] = cim_req
        for model_el in allocation_elements:
            for req_name, logical_block in getattr(model_el, "allocation_satisfy", []):
                allocation_matrix.append(
                    AllocationRowIR(
                        requirement=req_name,
                        logical_block=logical_block,
                        cim_derive=refinement_map.get(req_name),
                    )
                )
        allocation_matrix.sort(key=lambda r: (r.requirement, r.logical_block))

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
        exposed_elements=exposed_elements,
        coverage_refs=coverage_refs,
        sections=sections,
        allocation_matrix=allocation_matrix,
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


def extract_documents(
    model_index: ModelIndex,
    *,
    doc_prefixes: Sequence[str] | None = None,
    coverage_prefix: str = "CM_",
    is_document: Callable[[ModelElement], bool] | None = None,
) -> ExtractionResult:
    """
    Extract document and coverage information from a ModelIndex.

    By default this targets DOC_CIM_* and DOC_PIM_* views and CM_* coverage
    requirements, but callers can override the prefixes or provide an explicit
    document predicate for other abstraction levels (PSM) or document families.
    """
    effective_doc_prefixes: Sequence[str] = tuple(doc_prefixes or ("DOC_CIM_", "DOC_PIM_", "DOC_PSM_"))

    def _default_is_document(element: ModelElement) -> bool:
        if element.kind != "view":
            return False
        return any(element.name.startswith(prefix) for prefix in effective_doc_prefixes)

    document_predicate: Callable[[ModelElement], bool] = is_document or _default_is_document

    doc_elements = [element for element in model_index.elements if document_predicate(element)]
    doc_elements.sort(key=lambda item: item.name)

    coverage_elements = [
        element
        for element in model_index.elements
        if element.kind == "requirement" and element.name.startswith(coverage_prefix)
    ]
    coverage_elements.sort(key=lambda item: item.name)

    documents = [_extract_document_ir(item, model_index) for item in doc_elements]
    coverage_entries = [_extract_coverage_entry(item) for item in coverage_elements]
    return ExtractionResult(documents=documents, coverage_entries=coverage_entries)
