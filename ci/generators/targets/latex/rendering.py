"""Rendering helpers: heading, qname, directive-based views, package structure."""
from __future__ import annotations

from ...ir import DocumentIR, ExposedElement
from .escape import _escape_latex


def _heading_for_depth(depth: int) -> str:
    if depth <= 0:
        return "\\section"
    if depth == 1:
        return "\\subsection"
    return "\\subsubsection"


def _qname(parts: tuple[str, ...]) -> str:
    return "::".join(parts)


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


def _render_by_directive(document: DocumentIR) -> str:
    render_kind = (document.binding.render_kind or "").strip()
    if render_kind == "ElementTable":
        return _render_element_table(document)
    if render_kind == "TreeDiagram":
        return _render_tree(document)
    if render_kind == "TextualNotation":
        return _render_textual(document)
    return _render_textual(document)


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
        qname_str = _qname(package_path)

        lines.append(f"{heading}{{{_escape_latex(package_name)}}}")
        if qname_str in package_doc_by_qname and package_doc_by_qname[qname_str]:
            lines.append(_escape_latex(package_doc_by_qname[qname_str]))
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
