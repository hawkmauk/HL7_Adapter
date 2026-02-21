"""Main document assembly: _build_tex and _filename_for_document."""
from __future__ import annotations

from ...ir import DocumentIR
from .assets import STYLE_FILE_NAME
from .escape import _escape_latex, _label_key
from .rendering import (
    _heading_for_depth,
    _render_element_table,
    _render_exposed_package_structure,
    _render_stakeholder_signoff_table,
)
from .tables import (
    _render_boundary_ports_and_interfaces,
    _render_events_table,
    _render_psm_interface_bindings,
    _render_section_elements_table,
)
from .trade_study import _render_technology_selection_table
from .traceability import (
    _render_allocation_traceability_matrix,
    _render_parametric_constraints_table,
)


def _build_tex(document: DocumentIR, version: str) -> str:
    lines = [
        "% Auto-generated from SysML views",
        f"% Source: {document.source.file_path}",
        "% Build from the output directory so lyrebird-doc-style.sty is found, or run the generator first.",
        "\\documentclass[11pt]{article}",
        "\\usepackage{longtable}",
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

    if document.document_id == "DOC_PIM_Allocation":
        matrix_tex = _render_allocation_traceability_matrix(document)
        if matrix_tex:
            lines.append("\\subsection{Traceability Matrix}")
            lines.append("")
            lines.append(matrix_tex)
            lines.append("")

    if document.sections:
        for section in document.sections:
            heading_cmd = _heading_for_depth(section.depth)
            is_signoff_section = (
                section.title.strip().lower() == "stakeholder signoff"
                or getattr(section, "id", "") == "SignoffSection"
            )
            is_gateway_signoff_doc = document.document_id in (
                "DOC_CIM_GatewaySignoff",
                "DOC_PIM_GatewaySignoff",
            )
            heading_text = (
                "Stakeholder Signoff"
                if (is_signoff_section and is_gateway_signoff_doc)
                else section.title
            )
            lines.append(f"{heading_cmd}{{{_escape_latex(heading_text)}}}")
            if section.intro:
                lines.append(_escape_latex(section.intro))
                lines.append("")

            if is_signoff_section and is_gateway_signoff_doc:
                lines.append(_render_stakeholder_signoff_table(document))
                lines.append("")
                continue

            if document.document_id == "DOC_PIM_InterfaceDesign":
                boundary_tex = _render_boundary_ports_and_interfaces(section)
                if boundary_tex:
                    lines.append(boundary_tex)
                    lines.append("")

            if document.document_id == "DOC_PIM_Verification":
                param_tex = _render_parametric_constraints_table(section)
                if param_tex:
                    lines.append(param_tex)
                    lines.append("")

            if document.document_id == "DOC_PSM_PlatformRealization":
                tech_tex = _render_technology_selection_table(section)
                if tech_tex:
                    lines.append(tech_tex)
                    lines.append("")

            is_interface_bindings_section = (
                section.title.strip() == "Interface Bindings"
                or getattr(section, "id", "") == "InterfaceBindingsSection"
            )
            if document.document_id == "DOC_PSM_PlatformRealization" and is_interface_bindings_section:
                psm_if_tex = _render_psm_interface_bindings(section)
                if psm_if_tex:
                    lines.append(psm_if_tex)
                    lines.append("")
                continue

            exclude_kinds = {"package", "use case", "port", "interface"}
            if document.document_id == "DOC_PIM_Verification":
                exclude_kinds = exclude_kinds | {"constraint"}
            section_items = [
                e for e in section.exposed_elements if e.kind not in exclude_kinds
            ]
            if section_items:
                lines.append(_render_section_elements_table(section))
                lines.append("")
    else:
        lines.append("\\subsection{Model View Content}")
        lines.append(_render_exposed_package_structure(document))
        lines.append("")

    events = [
        e
        for e in document.exposed_elements
        if e.kind == "occurrence" and e.qualified_name.startswith("CIM::Events::")
    ]
    if events:
        lines.append("\\subsection{Events}")
        lines.append(_render_events_table(events))
        lines.append("")

    use_cases = [e for e in document.exposed_elements if e.kind == "use case"]
    if use_cases:
        for use_case in sorted(use_cases, key=lambda item: item.name):
            lines.append(f"\\begin{{usecase}}{{{_escape_latex(use_case.name)}}}")
            if use_case.doc:
                for raw_line in use_case.doc.splitlines():
                    clean = raw_line.strip()
                    if clean:
                        lines.append(f"{_escape_latex(clean)}\\\\")
                    else:
                        lines.append("")
            lines.append("\\end{usecase}")
            lines.append("")

    lines.append("\\subsection{Render Directive Snapshot}")
    lines.append(_render_element_table(document))
    lines.append("")
    lines.append("\\end{document}")
    return "\n".join(lines)


def _filename_for_document(document: DocumentIR) -> str:
    """
    Derive the LaTeX filename for a document.

    We use the view's stable ID directly so that CIM/PIM/PSM documents can
    coexist without a hard-coded prefix.
    """
    return f"{document.document_id}.tex"
