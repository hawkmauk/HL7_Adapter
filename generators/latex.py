from __future__ import annotations

from pathlib import Path
import re

import subprocess

from .base import GeneratedArtifact, GenerationOptions, GeneratorTarget
from .ir import DocumentIR, ExposedElement
from .registry import register_target
from .templates import get_template_dir, select_first_existing, copy_asset


LATEX_SPECIAL_RE = re.compile(r"([\\{}$&#_%~^])")
STYLE_FILE_NAME = "lyrebird-doc-style.sty"
TEX4HT_CFG_NAME = "lyrebird-html.cfg"
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


def _try_convert_svg_to_pdf(svg_path: Path, pdf_path: Path) -> None:
    """Convert SVG to PDF for pdflatex if rsvg-convert or similar is available."""
    if not svg_path.exists():
        return
    for cmd in (["rsvg-convert", "-f", "pdf", "-o", str(pdf_path), str(svg_path)],):
        try:
            subprocess.run(cmd, check=True, capture_output=True, timeout=10)
            if pdf_path.exists():
                return
        except (FileNotFoundError, subprocess.CalledProcessError, subprocess.TimeoutExpired):
            continue


def _template_dir() -> Path:
    """Return the template directory for the LaTeX target."""
    return get_template_dir("latex")


def _style_template_path() -> Path:
    """Locate the LaTeX style template, preferring the templates/ tree."""
    generator_dir = Path(__file__).resolve().parent
    repo_root = generator_dir.parent
    candidates = [
        _template_dir() / STYLE_FILE_NAME,
        repo_root / "lib" / STYLE_FILE_NAME,
        generator_dir / "lib" / STYLE_FILE_NAME,
    ]
    return select_first_existing(candidates)


def _render_element_table(document: DocumentIR) -> str:
    rows = [
        "\\begin{tabular}{|l|p{11cm}|}",
        "\\hline",
        "\\textbf{Field} & \\textbf{Value} \\\\",
        "\\hline",
        f"Document ID & {_escape_latex(document.document_id)} \\\\",
        "\\hline",
    ]
    for ref in sorted(document.binding.expose_refs):
        rows.append(f"Expose Ref & \\texttt{{{_escape_latex(ref)}}} \\\\")
        rows.append("\\hline")
    for ref in sorted(document.binding.satisfy_refs):
        rows.append(f"Satisfy Ref & \\texttt{{{_escape_latex(ref)}}} \\\\")
        rows.append("\\hline")
    rows.append("\\end{tabular}")
    return "\n".join(rows)


def _render_tree(document: DocumentIR) -> str:
    lines = ["\\begin{itemize}"]
    lines.append(f"\\item \\textbf{{Document}}: {_escape_latex(document.document_id)}")
    lines.append("\\item \\textbf{Bindings}")
    lines.append("\\begin{itemize}")
    for ref in sorted(document.binding.satisfy_refs):
        lines.append(f"\\item satisfy -> \\texttt{{{_escape_latex(ref)}}}")
    for ref in sorted(document.binding.expose_refs):
        lines.append(f"\\item expose -> \\texttt{{{_escape_latex(ref)}}}")
    lines.append("\\end{itemize}")
    lines.append("\\end{itemize}")
    return "\n".join(lines)


def _render_textual(document: DocumentIR) -> str:
    content = []
    content.append("\\begin{verbatim}")
    content.append(f"document_id: {document.document_id}")
    content.append(f"abstraction_level: {document.abstraction_level}")
    content.append(f"render: {document.binding.render_kind or 'unspecified'}")
    content.append("satisfy_refs:")
    for ref in sorted(document.binding.satisfy_refs):
        content.append(f"  - {ref}")
    content.append("expose_refs:")
    for ref in sorted(document.binding.expose_refs):
        content.append(f"  - {ref}")
    content.append("\\end{verbatim}")
    return "\n".join(content)


def _heading_for_depth(depth: int) -> str:
    if depth <= 0:
        return "\\section"
    if depth == 1:
        return "\\subsection"
    return "\\subsubsection"


def _qname(parts: tuple[str, ...]) -> str:
    return "::".join(parts)


def _render_exposed_package_structure(document: DocumentIR) -> str:
    elements = document.exposed_elements
    if not elements:
        return "\\subsection{Exposed Model Elements}\nNo exposed elements resolved."

    package_doc_by_qname: dict[str, str] = {}
    package_nodes: set[tuple[str, ...]] = set()
    members_by_package: dict[tuple[str, ...], list[ExposedElement]] = {}

    for element in elements:
        for depth in range(1, len(element.package_path) + 1):
            package_nodes.add(element.package_path[:depth])

        if element.kind == "package":
            package_nodes.add(element.package_path + (element.name,))
            package_doc_by_qname[element.qualified_name] = element.doc
        else:
            members_by_package.setdefault(element.package_path, []).append(element)

    children_by_parent: dict[tuple[str, ...] | None, list[tuple[str, ...]]] = {}
    for package_path in package_nodes:
        parent = package_path[:-1] if len(package_path) > 1 else None
        children_by_parent.setdefault(parent, []).append(package_path)

    for parent in children_by_parent:
        children_by_parent[parent].sort(key=lambda item: _qname(item))
    for package_path in members_by_package:
        members_by_package[package_path].sort(key=lambda item: item.qualified_name)

    lines: list[str] = []

    def render_package(package_path: tuple[str, ...], depth: int) -> None:
        heading = _heading_for_depth(depth)
        package_name = package_path[-1]
        qname = _qname(package_path)

        lines.append(f"{heading}{{{_escape_latex(package_name)}}}")
        if qname in package_doc_by_qname and package_doc_by_qname[qname]:
            lines.append(_escape_latex(package_doc_by_qname[qname]))
            lines.append("")

        members = members_by_package.get(package_path, [])
        if members:
            lines.append("\\begin{itemize}")
            for member in members:
                member_line = f"\\item \\textbf{{{_escape_latex(member.name)}}}"
                lines.append(member_line)
                if member.doc:
                    lines.append(_escape_latex(member.doc))
            lines.append("\\end{itemize}")
            lines.append("")

        for child in children_by_parent.get(package_path, []):
            render_package(child, depth + 1)

    for root in children_by_parent.get(None, []):
        render_package(root, 0)

    return "\n".join(lines).strip()


def _render_stakeholder_signoff_table(document: DocumentIR) -> str:
    """
    Render a tabular layout for gateway stakeholder signoff participants.

    Rows are derived from governance stakeholders exposed via the document
    bindings (e.g. MDA_Structure::Customer, ProjectManager, SystemsEngineer,
    ComplianceOfficer, OperationsOwner).
    """
    stakeholders: list[ExposedElement] = [
        element
        for element in document.exposed_elements
        if element.package_path and element.package_path[0] == "MDA_Structure"
    ]
    if not stakeholders:
        return "No stakeholder signoff participants resolved."

    stakeholders.sort(key=lambda item: item.name)

    lines = [
        "\\begin{tabular}{|l|p{5cm}|l|l|p{5cm}|}",
        "\\hline",
        "\\textbf{Stakeholder} & \\textbf{Role / Responsibility} & \\textbf{Decision} & \\textbf{Date} & \\textbf{Notes} \\\\",
        "\\hline",
    ]

    for element in stakeholders:
        role = _escape_latex(element.doc) if element.doc else ""
        lines.append(
            f"{_escape_latex(element.name)} & {role} & & & \\\\"
        )
        lines.append("\\hline")

    lines.append("\\end{tabular}")
    return "\n".join(lines)


def _render_by_directive(document: DocumentIR) -> str:
    render_kind = (document.binding.render_kind or "").strip()
    if render_kind == "ElementTable":
        return _render_element_table(document)
    if render_kind == "TreeDiagram":
        return _render_tree(document)
    if render_kind == "TextualNotation":
        return _render_textual(document)
    return _render_textual(document)


def _build_tex(document: DocumentIR, version: str) -> str:
    lines = [
        "% Auto-generated from SysML views",
        f"% Source: {document.source.file_path}",
        "% Build from the output directory so lyrebird-doc-style.sty is found, or run the generator first.",
        "\\documentclass[11pt]{article}",
        f"\\usepackage{{{STYLE_FILE_NAME.removesuffix('.sty')}}}",
        "",
        "\\begin{document}",
        (
            f"\\LyrebirdDocumentTitle{{{_escape_latex(document.title)}}}"
            f"{{{_escape_latex(document.document_id)}}}"
            f"{{{_escape_latex(version)}}}"
        ),
        "",
        f"\\section{{{_escape_latex(document.title)}}}",
        f"\\label{{sec:{_label_key(document.document_id)}}}",
        "",
        "\\subsection{Metadata}",
        "\\begin{itemize}",
        f"\\item Document ID: \\texttt{{{_escape_latex(document.document_id)}}}",
        f"\\item Abstraction Level: {_escape_latex(document.abstraction_level)}",
        f"\\item Source Lines: {document.source.start_line}--{document.source.end_line}",
        f"\\item Render Directive: \\texttt{{{_escape_latex(document.binding.render_kind or 'unspecified')}}}",
        "\\end{itemize}",
        "",
    ]
    if document.purpose:
        lines.append("\\subsection{Purpose}")
        lines.append(_escape_latex(document.purpose))
        lines.append("")

    if document.sections:
        # Section-aware rendering: each SectionIR becomes its own subsection.
        for section in document.sections:
            heading_cmd = _heading_for_depth(section.depth)
            lines.append(f"{heading_cmd}{{{_escape_latex(section.title)}}}")
            if section.intro:
                lines.append(_escape_latex(section.intro))
                lines.append("")

            # Special-case rendering for the CIM gateway stakeholder signoff table.
            if (
                document.document_id == "DOC_CIM_GatewaySignoff"
                and section.title.strip().lower() == "stakeholder signoff"
            ):
                lines.append(_render_stakeholder_signoff_table(document))
                lines.append("")
                continue

            # Filter out package-only entries so we don't create empty lists,
            # which cause "missing \\item" LaTeX errors.
            section_items = [e for e in section.exposed_elements if e.kind != "package"]
            if section_items:
                lines.append("\\begin{itemize}")
                for element in section_items:
                    item = f"\\item \\textbf{{{_escape_latex(element.name)}}}"
                    if element.doc:
                        item += f" {_escape_latex(element.doc)}"
                    lines.append(item)
                lines.append("\\end{itemize}")
                lines.append("")
    else:
        # Backwards-compatible flat rendering.
        lines.append("\\subsection{Model View Content}")
        lines.append(_render_exposed_package_structure(document))
        lines.append("")

    lines.append("\\subsection{Render Directive Snapshot}")
    lines.append(_render_by_directive(document))
    lines.append("")
    lines.append("\\end{document}")
    return "\n".join(lines)


class LatexGenerator(GeneratorTarget):
    name = "latex"
    supported_renders = {"ElementTable", "TreeDiagram", "TextualNotation"}

    def generate(
        self,
        documents: list[DocumentIR],
        options: GenerationOptions,
    ) -> list[GeneratedArtifact]:
        output_dir = Path(options.output_dir)
        output_dir.mkdir(parents=True, exist_ok=True)

        style_source = _style_template_path()
        if not style_source.exists():
            raise ValueError(f"Missing LaTeX style template: {style_source}")

        artifacts: list[GeneratedArtifact] = []

        # Style file
        style_artifact = copy_asset(style_source, output_dir, artifact_type="style")
        artifacts.append(style_artifact)

        # Logo assets (not currently tracked in coverage report)
        template_dir = style_source.parent
        logo_svg = template_dir / "lyrebird-logo.svg"
        logo_pdf = template_dir / "lyrebird-logo.pdf"
        if logo_svg.exists():
            copy_asset(logo_svg, output_dir, artifact_type="logo-svg")
        if logo_pdf.exists():
            copy_asset(logo_pdf, output_dir, artifact_type="logo-pdf")
        else:
            _try_convert_svg_to_pdf(logo_svg, output_dir / "lyrebird-logo.pdf")

        tex4ht_cfg = _template_dir() / TEX4HT_CFG_NAME
        if tex4ht_cfg.exists():
            tex4ht_artifact = copy_asset(tex4ht_cfg, output_dir, artifact_type="tex4ht-config")
            artifacts.append(tex4ht_artifact)

        for document in sorted(documents, key=lambda item: item.document_id):
            filename = f"cim-{_doc_slug(document.document_id)}-{options.version}.tex"
            output_path = output_dir / filename
            output_path.write_text(_build_tex(document, options.version), encoding="utf-8")
            artifacts.append(
                GeneratedArtifact(
                    path=output_path,
                    artifact_type="tex",
                    document_id=document.document_id,
                )
            )
        return artifacts


@register_target
def _make_latex_generator() -> GeneratorTarget:
    """Factory used to register the LaTeX target in the default registry."""
    return LatexGenerator()
