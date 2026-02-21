from __future__ import annotations

from .base import GeneratorTarget
from .errors import ValidationError
from .extraction import ExtractionResult
from .ir import ModelGraph
from .parsing import ModelIndex

DOCUMENTATION_VIEWPOINT_QNAME = "MDA_Viewpoint::DocumentationViewpoint"
EXECUTABLE_VIEWPOINT_QNAME = "MDA_Viewpoint::ExecutableViewpoint"
TEST_VIEWPOINT_QNAME = "MDA_Viewpoint::TestViewpoint"


def validate_model_index(model_index: ModelIndex) -> None:
    duplicate_ids = {
        symbol: paths
        for symbol, paths in model_index.declared_ids.items()
        if len(paths) > 1
    }
    if duplicate_ids:
        lines = []
        for symbol in sorted(duplicate_ids):
            joined = ", ".join(str(path) for path in duplicate_ids[symbol])
            lines.append(f"{symbol}: {joined}")
        message = "Duplicate stable IDs found:\n" + "\n".join(lines)
        raise ValidationError(message)


def _extract_last_token(ref: str) -> str | None:
    value = ref.strip()
    if not value or value.endswith("**"):
        return None
    return value.split("::")[-1].strip()


def _has_symbol(model_index: ModelIndex, symbol: str) -> bool:
    return bool(model_index.by_name.get(symbol))


def validate_extraction_graph(extraction: ExtractionResult, model_index: ModelIndex) -> None:
    if not extraction.documents:
        raise ValidationError("No DOC_CIM_* views found. Cannot generate artifacts.")

    unresolved: list[str] = []

    for document in extraction.documents:
        if not document.purpose:
            unresolved.append(f"{document.document_id}: missing doc/purpose text")

        for ref in document.binding.satisfy_refs:
            token = _extract_last_token(ref)
            if token and token.startswith("VP_") and not _has_symbol(model_index, token):
                unresolved.append(f"{document.document_id}: unresolved satisfy ref '{ref}'")

        for ref in document.binding.expose_refs:
            token = _extract_last_token(ref)
            if token and (token.startswith("VPT_") or token.startswith("CM_")) and not _has_symbol(model_index, token):
                unresolved.append(f"{document.document_id}: unresolved expose ref '{ref}'")

    coverage_map = {entry.coverage_id: entry for entry in extraction.coverage_entries}
    for document in extraction.documents:
        for coverage_ref in document.coverage_refs:
            if coverage_ref not in coverage_map:
                unresolved.append(
                    f"{document.document_id}: coverage reference '{coverage_ref}' does not exist"
                )

    if unresolved:
        raise ValidationError("Validation failed:\n" + "\n".join(unresolved))


def _resolve_viewpoint_type(graph: ModelGraph, viewpoint_def_qname: str) -> str | None:
    """Walk supertype chain from viewpoint def; return 'documentation', 'executable', 'test', or None."""
    def is_doc(q: str) -> bool:
        return q == DOCUMENTATION_VIEWPOINT_QNAME or q.endswith("::DocumentationViewpoint") or q == "DocumentationViewpoint"

    def is_exec(q: str) -> bool:
        return q == EXECUTABLE_VIEWPOINT_QNAME or q.endswith("::ExecutableViewpoint") or q == "ExecutableViewpoint"

    def is_test(q: str) -> bool:
        return q == TEST_VIEWPOINT_QNAME or q.endswith("::TestViewpoint") or q == "TestViewpoint"

    visited: set[str] = set()
    stack = [viewpoint_def_qname]
    while stack:
        qname = stack.pop()
        if qname in visited:
            continue
        visited.add(qname)
        if is_doc(qname):
            return "documentation"
        if is_exec(qname):
            return "executable"
        if is_test(qname):
            return "test"
        node = graph.get(qname)
        if node:
            for edge in graph.outgoing(qname, "supertype"):
                if edge.target:
                    stack.append(edge.target)
    return None


def _resolve_satisfy_ref_to_viewpoint_def(
    ref: str, model_index: ModelIndex, graph: ModelGraph
) -> str | None:
    """Resolve a satisfy ref (viewpoint usage or def name) to the viewpoint def qualified name.

    Viewpoint usages (e.g. 'viewpoint platformRealizationViewpoint : X;') are often not
    parsed as block elements, so we resolve the ref as a usage name by trying the
    corresponding viewpoint def name (PascalCase): e.g. platformRealizationViewpoint -> PlatformRealizationViewpoint.
    """
    ref_clean = ref.strip()
    if not ref_clean:
        return None
    token = ref_clean.split("::")[-1]
    try_names = [token]
    if len(token) > 1:
        try_names.append(token[0].upper() + token[1:])
    if token.startswith("pim") and len(token) > 3:
        try_names.append("PIM" + token[3].upper() + token[4:])
    for try_name in try_names:
        if not try_name:
            continue
        candidates = model_index.by_name.get(try_name, [])
        for elem in candidates:
            if elem.kind != "viewpoint":
                continue
            qname = elem.qualified_name
            if qname not in graph.nodes:
                continue
            out = graph.outgoing(qname, "supertype")
            if out and out[0].target and elem.name == token:
                return out[0].target  # usage -> def (ref matched usage name)
            return qname  # element is the def itself (e.g. found by PascalCase)
    if ref_clean in graph.nodes:
        node = graph.get(ref_clean)
        if node and node.kind == "viewpoint":
            out = graph.outgoing(ref_clean, "supertype")
            if out and out[0].target:
                return out[0].target
            return ref_clean
    return None


def _is_viewpoint_ref(ref: str) -> bool:
    """True if ref looks like a viewpoint reference (identifier or qualified name), not doc text."""
    r = ref.strip()
    if not r or "\n" in r or "*/" in r or "expose" in r.lower() or "::**" in r:
        return False
    return all(c.isalnum() or c in ":_" for c in r)


def resolve_document_viewpoint_type(
    document_id: str,
    satisfy_refs: list[str],
    model_index: ModelIndex,
    graph: ModelGraph,
) -> str | None:
    """Resolve a document's viewpoint type from its satisfy_refs, or from a supertype template's satisfy_refs.
    Returns 'documentation', 'executable', or None."""
    for ref in satisfy_refs:
        if not _is_viewpoint_ref(ref):
            continue
        viewpoint_def_qname = _resolve_satisfy_ref_to_viewpoint_def(ref, model_index, graph)
        if viewpoint_def_qname:
            vp_type = _resolve_viewpoint_type(graph, viewpoint_def_qname)
            if vp_type:
                return vp_type
    # Fallback: document view may have no satisfy_refs but subtype a template that does (e.g. PSM doc views).
    for elem in model_index.by_name.get(document_id, []):
        if elem.kind != "view":
            continue
        for st in getattr(elem, "supertypes", []):
            seen_qnames: set[str] = set()
            for cand in list(model_index.by_name.get(st, [])) + list(model_index.by_short_name.get(st, [])):
                if cand.qualified_name in seen_qnames:
                    continue
                seen_qnames.add(cand.qualified_name)
                if cand.kind != "view":
                    continue
                for ref in getattr(cand, "satisfy_refs", []):
                    if not _is_viewpoint_ref(ref):
                        continue
                    viewpoint_def_qname = _resolve_satisfy_ref_to_viewpoint_def(ref, model_index, graph)
                    if viewpoint_def_qname:
                        vp_type = _resolve_viewpoint_type(graph, viewpoint_def_qname)
                        if vp_type:
                            return vp_type
    return None


def validate_documents_for_target(
    *,
    documents: list,
    model_index: ModelIndex,
    graph: ModelGraph,
    target: GeneratorTarget,
) -> None:
    """Ensure every document's viewpoint type is in the target's supported_viewpoint_types (if set)."""
    supported = getattr(target, "supported_viewpoint_types", None)
    if not supported:
        return

    errors: list[str] = []
    for doc in documents:
        vp_type = resolve_document_viewpoint_type(
            doc.document_id,
            doc.binding.satisfy_refs,
            model_index,
            graph,
        )
        if vp_type is None:
            errors.append(
                f"{doc.document_id}: could not resolve viewpoint type from satisfy refs {doc.binding.satisfy_refs!r}"
            )
            continue
        if vp_type not in supported:
            errors.append(
                f"{doc.document_id}: viewpoint type '{vp_type}' is not supported by target '{target.name}'. "
                f"Supported: {sorted(supported)}."
            )
    if errors:
        raise ValidationError("Viewpoint type validation failed:\n" + "\n".join(errors))
