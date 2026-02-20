from __future__ import annotations

from .errors import ValidationError
from .extraction import ExtractionResult
from .parsing import ModelIndex


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
