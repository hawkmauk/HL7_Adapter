from __future__ import annotations

from dataclasses import dataclass, field
from pathlib import Path
import re

from .errors import ParsingError


BLOCK_DECL_RE = re.compile(
    r"(?m)^(?P<indent>\s*)(?P<kind>package|view|viewpoint|concern|requirement|part|port|interface|constraint|use\s+case|occurrence|action)\s+"
    r"(?:(?:def)\s+)?"
    r"(?:(?:<(?P<short>[^>]+)>)\s+)?"
    r"(?P<name>'[^']+'|[A-Za-z_][A-Za-z0-9_]*)"
    r"(?P<tail>[^{;\n]*)\{"
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
ATTRIBUTE_RE = re.compile(
    r"(?m)^\s*attribute\s+"
    r"(?P<name>[A-Za-z_][A-Za-z0-9_]*)"
    r"\s*:\s*(?P<type>[^;{]+);"
)
# Attribute with doc block and no semicolon (SysML v2 style): "attribute name : type { doc /* ... */ }"
ATTRIBUTE_NO_SEMICOLON_RE = re.compile(
    r"(?m)^\s*attribute\s+"
    r"(?P<name>[A-Za-z_][A-Za-z0-9_]*)"
    r"\s*:\s*(?P<type>[^{]+)\s*\{\s*doc\s*/\*.*?\*/\s*\}",
)  # no trailing \s* so next match starts at line start (^)
ALIAS_RE = re.compile(r"(?m)^\s*alias\s+(?P<alias>[A-Za-z_][A-Za-z0-9_]*)\s+for\s+(?P<target>[A-Za-z_][A-Za-z0-9_]*)\s*;")
FLOW_PROPERTY_RE = re.compile(
    r"(?m)^\s*(?P<dir>in|out)\s+(?P<kind>item|attribute)\s+"
    r"(?P<name>[A-Za-z_][A-Za-z0-9_']*)\s*:\s*(?P<type>[^;]+);"
)
INTERFACE_END_RE = re.compile(
    r"(?m)^\s*end\s+(?P<role>[A-Za-z_][A-Za-z0-9_]*)\s*:\s*(?P<port_type>[A-Za-z_][A-Za-z0-9_]*)\s*;"
)
ALLOCATION_SATISFY_RE = re.compile(
    r"(?m)^\s*satisfy\s+requirement\s+'([^']+)'\s+by\s+([^;]+);"
)
REFINEMENT_DEPENDENCY_RE = re.compile(
    r"(?m)#refinement\s+dependency\s+'([^']+)'\s+to\s+'([^']+)';"
)
# Nested part declarations (no body): "part name : Type;" or "part <short> 'name' : Type;"
PART_INLINE_RE = re.compile(
    r"(?m)^\s*part\s+(?:<(?P<short>[^>]+)>)?\s*"
    r"(?P<name>'[^']+'|[A-Za-z_][A-Za-z0-9_]*)\s*:\s*(?P<types>[^;]+);"
)
# Constraint def parameters: "in name : Type;" (not "in item|attribute ...")
CONSTRAINT_PARAM_RE = re.compile(
    r"(?m)^\s*in\s+(?P<name>[A-Za-z_][A-Za-z0-9_]*)\s*:\s*(?P<type>[^;]+);"
)
# Attribute value/weight assignments in body (for trade-study score: value = N, weight = N)
ATTR_VALUE_ASSIGN_RE = re.compile(r"attribute\s+::>\s+value\s*=\s*([\d.]+)")
ATTR_WEIGHT_ASSIGN_RE = re.compile(r"attribute\s+::>\s+weight\s*=\s*([\d.]+)")


@dataclass(slots=True)
class ModelAttribute:
    name: str
    type: str | None


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
    supertypes: list[str] = field(default_factory=list)
    attributes: list[ModelAttribute] = field(default_factory=list)
    aliases: list[tuple[str, str]] = field(default_factory=list)  # (alias_name, target_name)
    flow_properties: list[tuple[str, str, str, str]] = field(default_factory=list)  # (direction, kind, name, type)
    interface_ends: list[tuple[str, str]] = field(default_factory=list)  # (role, port_type) for interface def
    allocation_satisfy: list[tuple[str, str]] = field(default_factory=list)  # (requirement_name, logical_block_path)
    refinement_dependencies: list[tuple[str, str]] = field(default_factory=list)  # (pim_req, cim_req)
    constraint_params: list[tuple[str, str]] = field(default_factory=list)  # (name, type) for constraint def
    value_assignments: list[float] = field(default_factory=list)  # attribute ::> value = N (order preserved)
    weight_assignments: list[float] = field(default_factory=list)  # attribute ::> weight = N (order preserved)


@dataclass(slots=True)
class ModelIndex:
    files: list[Path]
    elements: list[ModelElement]
    by_qualified_name: dict[str, ModelElement]
    by_name: dict[str, list[ModelElement]]
    by_short_name: dict[str, list[ModelElement]]
    declared_ids: dict[str, list[Path]]
    alias_map: dict[str, str] = field(default_factory=dict)  # logical path -> actual qualified name

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
    raise ParsingError("Unbalanced braces while parsing SysML blocks.")


def _extract_elements(file_path: Path, text: str) -> list[ModelElement]:
    elements: list[ModelElement] = []
    for match in BLOCK_DECL_RE.finditer(text):
        kind = match.group("kind")
        name = _strip_quotes(match.group("name"))
        short_name = _strip_short_name(match.group("short"))
        tail = match.group("tail") or ""
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
            raw_doc = doc_match.group("doc")
            # Preserve line breaks but strip leading/trailing whitespace on each line
            # so rendered text is left-aligned and free of indentation noise.
            doc_lines = [line.strip() for line in raw_doc.splitlines()]
            doc = "\n".join(doc_lines).strip()

        render_match = RENDER_RE.search(body)
        render_kind = render_match.group("kind") if render_match else None

        # Field-level attributes declared inside the block.
        attributes: list[ModelAttribute] = []
        for attr_match in ATTRIBUTE_RE.finditer(body):
            attr_name = attr_match.group("name")
            raw_type = (attr_match.group("type") or "").strip()
            attr_type = raw_type or None
            attributes.append(ModelAttribute(name=attr_name, type=attr_type))
        seen_attr_names = {a.name for a in attributes}
        for attr_match in ATTRIBUTE_NO_SEMICOLON_RE.finditer(body):
            attr_name = attr_match.group("name")
            if attr_name in seen_attr_names:
                continue
            seen_attr_names.add(attr_name)
            raw_type = (attr_match.group("type") or "").strip()
            attributes.append(ModelAttribute(name=attr_name, type=raw_type or None))

        # Optional supertypes (e.g. \"view X : Y\" or \"view X :> Y\")
        supertypes: list[str] = []
        tail_clean = tail.strip()
        if tail_clean:
            for part in tail_clean.split(","):
                part_clean = part.strip()
                if not part_clean:
                    continue
                # Strip leading ':' or ':>' tokens
                while part_clean.startswith(":") or part_clean.startswith(">"):
                    part_clean = part_clean[1:].lstrip()
                if not part_clean:
                    continue
                supertypes.append(_strip_quotes(part_clean))

        # Aliases (e.g. \"alias Domain for CIM_Domain;\") in packages
        aliases: list[tuple[str, str]] = []
        if kind == "package":
            for alias_match in ALIAS_RE.finditer(body):
                aliases.append((alias_match.group("alias"), alias_match.group("target")))

        # Flow properties (port def): in/out item|attribute name : type;
        flow_properties: list[tuple[str, str, str, str]] = []
        if kind == "port":
            for fp_match in FLOW_PROPERTY_RE.finditer(body):
                flow_properties.append(
                    (
                        fp_match.group("dir"),
                        fp_match.group("kind"),
                        fp_match.group("name").strip("'"),
                        fp_match.group("type").strip(),
                    )
                )

        # Interface ends: end roleName : PortType;
        interface_ends: list[tuple[str, str]] = []
        if kind == "interface":
            for end_match in INTERFACE_END_RE.finditer(body):
                interface_ends.append((end_match.group("role"), end_match.group("port_type")))

        # Allocation satisfy: satisfy requirement 'Req' by logicalBlock;
        allocation_satisfy: list[tuple[str, str]] = []
        for sat_match in ALLOCATION_SATISFY_RE.finditer(body):
            allocation_satisfy.append(
                (sat_match.group(1).strip(), sat_match.group(2).strip())
            )

        # Refinement: #refinement dependency 'PIM_Req' to 'CIM_Req';
        refinement_dependencies: list[tuple[str, str]] = []
        for ref_match in REFINEMENT_DEPENDENCY_RE.finditer(body):
            refinement_dependencies.append(
                (ref_match.group(1).strip(), ref_match.group(2).strip())
            )

        # Constraint def parameters: in name : Type;
        constraint_params: list[tuple[str, str]] = []
        if kind == "constraint":
            for cp_match in CONSTRAINT_PARAM_RE.finditer(body):
                constraint_params.append(
                    (cp_match.group("name"), cp_match.group("type").strip())
                )

        # Attribute value/weight assignments (for trade-study score: sum value*weight)
        value_assignments = [float(m.group(1)) for m in ATTR_VALUE_ASSIGN_RE.finditer(body)]
        weight_assignments = [float(m.group(1)) for m in ATTR_WEIGHT_ASSIGN_RE.finditer(body)]

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
                supertypes=supertypes,
                attributes=attributes,
                aliases=aliases,
                flow_properties=flow_properties,
                interface_ends=interface_ends,
                allocation_satisfy=allocation_satisfy,
                refinement_dependencies=refinement_dependencies,
                constraint_params=constraint_params,
                value_assignments=value_assignments,
                weight_assignments=weight_assignments,
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


def _extract_nested_parts(parent: ModelElement) -> list[ModelElement]:
    """Extract nested part declarations from a part block body (e.g. 'part nodeScored : ScoredX;'). Only part blocks are scanned so package bodies are not traversed (avoiding wrong qualified_name)."""
    children: list[ModelElement] = []
    if not parent.body or parent.kind != "part":
        return children
    for match in PART_INLINE_RE.finditer(parent.body):
        name = _strip_quotes(match.group("name"))
        short = _strip_short_name(match.group("short"))
        types_str = (match.group("types") or "").strip()
        supertypes = [t.strip() for t in types_str.split(",") if t.strip()]
        child = ModelElement(
            kind="part",
            name=name,
            short_name=short,
            file_path=parent.file_path,
            start_index=parent.start_index,
            end_index=parent.end_index,
            start_line=parent.start_line,
            end_line=parent.end_line,
            body="",
            qualified_name=parent.qualified_name + "::" + name if parent.qualified_name else name,
            doc="",
            supertypes=supertypes,
        )
        children.append(child)
    return children


def parse_model_directory(model_dir: Path) -> ModelIndex:
    # Recursively include all .sysml files so that library packages under
    # subdirectories (e.g. MDA_Library) are part of the model index.
    files = sorted(model_dir.rglob("*.sysml"))
    if not files:
        raise ParsingError(f"No .sysml files found in {model_dir}")

    all_elements: list[ModelElement] = []
    declared_ids: dict[str, list[Path]] = {}
    for file_path in files:
        text = file_path.read_text(encoding="utf-8")
        all_elements.extend(_extract_elements(file_path, text))
        for match in ID_DECL_RE.finditer(text):
            symbol = match.group("name")
            declared_ids.setdefault(symbol, []).append(file_path)

    _resolve_qualified_names(all_elements)
    # Extract nested part declarations (e.g. part nodeScored : ScoredX;) so they appear as elements.
    nested: list[ModelElement] = []
    for element in all_elements:
        nested.extend(_extract_nested_parts(element))
    all_elements.extend(nested)
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

    # Build alias map so view refs like CIM::Domain::** resolve to CIM_Domain::**
    alias_map: dict[str, str] = {}
    for element in all_elements:
        if element.kind == "package" and element.aliases:
            for alias_name, target_name in element.aliases:
                logical = f"{element.qualified_name}::{alias_name}"
                alias_map[logical] = target_name

    return ModelIndex(
        files=files,
        elements=all_elements,
        by_qualified_name=by_qname,
        by_name=by_name,
        by_short_name=by_short_name,
        declared_ids=declared_ids,
        alias_map=alias_map,
    )
