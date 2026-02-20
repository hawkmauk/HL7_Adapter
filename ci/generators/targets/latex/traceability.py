"""Parametric constraints and allocation traceability matrix renderers."""
from __future__ import annotations

from ...ir import DocumentIR, SectionIR
from .escape import _escape_latex


def _render_parametric_constraints_table(section: SectionIR) -> str:
    """Render constraint defs by name with intent (doc) and parameter summary for Parametric Validation section."""
    constraints = [
        e for e in section.exposed_elements
        if getattr(e, "kind", None) == "constraint"
    ]
    if not constraints:
        return ""
    constraints.sort(key=lambda c: c.name)
    lines = [
        "\\subsubsection{Constraint definitions}",
        "",
        "\\begin{longtable}{|p{2.8cm}|p{6.5cm}|p{4.2cm}|}",
        "\\hline",
        "\\textbf{Constraint} & \\textbf{Intent} & \\textbf{Parameters} \\\\",
        "\\hline",
        "\\endhead",
    ]
    for c in constraints:
        intent = _escape_latex(c.doc) if c.doc else "---"
        params = getattr(c, "constraint_params", None) or []
        param_str = ", ".join(
            f"{_escape_latex(name)}: {_escape_latex(typ)}"
            for name, typ in params
        ) if params else "---"
        lines.append(f"{_escape_latex(c.name)} & {intent} & {param_str} \\\\")
        lines.append("\\hline")
    lines.append("\\end{longtable}")
    return "\n".join(lines)


def _render_allocation_traceability_matrix(document: DocumentIR) -> str:
    """Render the allocation traceability matrix (Requirement, Logical block, CIM derive)."""
    rows = getattr(document, "allocation_matrix", None) or []
    if not rows:
        return ""

    lines = [
        "\\begin{longtable}{|p{5cm}|p{4cm}|p{5cm}|}",
        "\\hline",
        "\\textbf{Requirement} & \\textbf{Logical block} & \\textbf{CIM derive} \\\\",
        "\\hline",
        "\\endhead",
    ]
    for row in rows:
        req = _escape_latex(row.requirement)
        block = _escape_latex(row.logical_block)
        cim = _escape_latex(row.cim_derive) if row.cim_derive else "---"
        lines.append(f"{req} & {block} & {cim} \\\\")
        lines.append("\\hline")
    lines.append("\\end{longtable}")
    return "\n".join(lines)
