from __future__ import annotations

from dataclasses import dataclass, field
from pathlib import Path
import re


BLOCK_DECL_RE = re.compile(
    r"(?m)^(?P<indent>\s*)(?P<kind>package|view|viewpoint|concern|requirement|part)\s+"
    r"(?:(?:def)\s+)?"
    r"(?:(?:<(?P<short>[^>]+)>)\s+)?"
    r"(?P<name>'[^']+'|[A-Za-z_][A-Za-z0-9_]*)"
    r"[^{;\n]*\{"
)

ID_DECL_RE = re.compile(
    r"(?m)^\s*(?P<kind>view|viewpoint|concern|requirement|part)\s+"
    r"(?:(?:def)\s+)?"
    r"(?P<name>[A-Z]+_[A-Za-z0-9_]+)\b"
)

DOC_RE = re.compile(r"doc\s*/\*(?P<doc>.*?)\*/", re.DOTALL)
EXPOSE_RE = re.compile(r"(?m)^\s*expose\s+(?P<ref>[^;]+);")
SATISFY_RE = re.compile(r"(?m)^\s*satisfy\s+(?P<ref>[^;]+);")
FRAME_RE = re.compile(r"(?m)^\s*frame\s+(?P<ref>[^;]+);")
RENDER_RE = re.compile(r"(?m)^\s*render\s+as(?P<kind>[A-Za-z0-9_]+)\s*;")


@dataclass(slots=True)
class ModelElement:
    kind: str
    name: str
    short_name: str | None
    file_path: Path
    start_index: int
    end_index: int
    start_line: int
    end_line: int
    body: str
    qualified_name: str = ""
    doc: str = ""
    expose_refs: list[str] = field(default_factory=list)
    satisfy_refs: list[str] = field(default_factory=list)
    frame_refs: list[str] = field(default_factory=list)
    render_kind: str | None = None


@dataclass(slots=True)
class ModelIndex:
    files: list[Path]
    elements: list[ModelElement]
    by_qualified_name: dict[str, ModelElement]
    by_name: dict[str, list[ModelElement]]
    by_short_name: dict[str, list[ModelElement]]
    declared_ids: dict[str, list[Path]]

    def get_single(self, name: str) -> ModelElement | None:
        candidates = self.by_name.get(name, [])
        if len(candidates) == 1:
            return candidates[0]
        return None


def _strip_quotes(value: str) -> str:
    if value.startswith("'") and value.endswith("'"):
        return value[1:-1]
    return value


def _strip_short_name(value: str | None) -> str | None:
    if value is None:
        return None
    clean = value.strip()
    if clean.startswith("'") and clean.endswith("'"):
        clean = clean[1:-1]
    return clean or None


def _line_no(text: str, index: int) -> int:
    return text.count("\n", 0, index) + 1


def _find_matching_brace(text: str, open_brace_index: int) -> int:
    depth = 0
    for i in range(open_brace_index, len(text)):
        ch = text[i]
        if ch == "{":
            depth += 1
        elif ch == "}":
            depth -= 1
            if depth == 0:
                return i
    raise ValueError("Unbalanced braces while parsing SysML blocks.")


def _extract_elements(file_path: Path, text: str) -> list[ModelElement]:
    elements: list[ModelElement] = []
    for match in BLOCK_DECL_RE.finditer(text):
        kind = match.group("kind")
        name = _strip_quotes(match.group("name"))
        short_name = _strip_short_name(match.group("short"))
        open_brace_index = text.find("{", match.start())
        if open_brace_index < 0:
            continue
        close_brace_index = _find_matching_brace(text, open_brace_index)
        body = text[open_brace_index + 1 : close_brace_index]
        start_line = _line_no(text, match.start())
        end_line = _line_no(text, close_brace_index)

        doc_match = DOC_RE.search(body)
        doc = ""
        if doc_match:
            doc = " ".join(part.strip() for part in doc_match.group("doc").strip().splitlines()).strip()

        render_match = RENDER_RE.search(body)
        render_kind = render_match.group("kind") if render_match else None

        elements.append(
            ModelElement(
                kind=kind,
                name=name,
                short_name=short_name,
                file_path=file_path,
                start_index=match.start(),
                end_index=close_brace_index,
                start_line=start_line,
                end_line=end_line,
                body=body,
                doc=doc,
                expose_refs=[m.group("ref").strip() for m in EXPOSE_RE.finditer(body)],
                satisfy_refs=[m.group("ref").strip() for m in SATISFY_RE.finditer(body)],
                frame_refs=[m.group("ref").strip() for m in FRAME_RE.finditer(body)],
                render_kind=render_kind,
            )
        )
    return elements


def _resolve_qualified_names(elements: list[ModelElement]) -> None:
    packages = [e for e in elements if e.kind == "package"]
    for element in elements:
        container_packages = [
            pkg
            for pkg in packages
            if pkg.file_path == element.file_path
            and pkg.start_index < element.start_index < element.end_index < pkg.end_index
        ]
        container_packages.sort(key=lambda pkg: pkg.end_index - pkg.start_index, reverse=True)
        path = [pkg.name for pkg in container_packages]
        element.qualified_name = "::".join(path + [element.name]) if path else element.name


def parse_model_directory(model_dir: Path) -> ModelIndex:
    files = sorted(model_dir.glob("*.sysml"))
    if not files:
        raise ValueError(f"No .sysml files found in {model_dir}")

    all_elements: list[ModelElement] = []
    declared_ids: dict[str, list[Path]] = {}
    for file_path in files:
        text = file_path.read_text(encoding="utf-8")
        all_elements.extend(_extract_elements(file_path, text))
        for match in ID_DECL_RE.finditer(text):
            symbol = match.group("name")
            declared_ids.setdefault(symbol, []).append(file_path)

    _resolve_qualified_names(all_elements)
    all_elements.sort(key=lambda e: (str(e.file_path), e.start_index))

    by_qname: dict[str, ModelElement] = {}
    by_name: dict[str, list[ModelElement]] = {}
    by_short_name: dict[str, list[ModelElement]] = {}
    for element in all_elements:
        by_qname[element.qualified_name] = element
        by_name.setdefault(element.name, []).append(element)
        if element.short_name:
            by_short_name.setdefault(element.short_name, []).append(element)
            by_name.setdefault(element.short_name, []).append(element)

    return ModelIndex(
        files=files,
        elements=all_elements,
        by_qualified_name=by_qname,
        by_name=by_name,
        by_short_name=by_short_name,
        declared_ids=declared_ids,
    )
