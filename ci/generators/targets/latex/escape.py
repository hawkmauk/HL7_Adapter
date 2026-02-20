"""LaTeX escaping and slug/label utilities."""
from __future__ import annotations

import re

LATEX_SPECIAL_RE = re.compile(r"([\\{}$&#_%~^])")
LABEL_SAFE_RE = re.compile(r"[^a-z0-9:-]+")


def _escape_latex(value: str) -> str:
    escaped = LATEX_SPECIAL_RE.sub(r"\\\1", value)
    return escaped.replace("<", "\\textless{}").replace(">", "\\textgreater{}")


def _doc_slug(document_id: str) -> str:
    base = document_id.removeprefix("DOC_CIM_")
    return base.lower()


def _label_key(document_id: str) -> str:
    key = document_id.lower().replace("_", "-")
    return LABEL_SAFE_RE.sub("-", key).strip("-")
