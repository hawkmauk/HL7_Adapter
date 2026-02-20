"""Table renderers: section elements, events, boundary ports/interfaces, PSM bindings."""
from __future__ import annotations

from ...ir import ExposedElement, SectionIR
from .escape import _escape_latex


def _parse_type_and_default(type_str: str | None) -> tuple[str, str]:
    """Split attribute type string into base type and default (e.g. 'Integer = 2575 { doc }' -> ('Integer', '2575'))."""
    if not type_str:
        return ("", "")
    s = type_str.strip()
    if "{" in s:
        s = s.split("{")[0].strip()
    if " = " in s:
        parts = s.split(" = ", 1)
        return (parts[0].strip(), parts[1].strip())
    return (s, "")


def _render_section_elements_table(section: SectionIR) -> str:
    """Render a section's exposed elements as a (potentially multi-page) table."""
    items = [e for e in section.exposed_elements if e.kind not in {"package", "port", "interface"}]
    if not items:
        return "No elements resolved."

    lines = [
        "\\begin{longtable}{|p{4cm}|p{2cm}|p{8.5cm}|}",
        "\\hline",
        "\\textbf{Name} & \\textbf{Kind} & \\textbf{Description} \\\\",
        "\\hline",
        "\\endhead",
    ]
    for element in items:
        cell_parts: list[str] = []
        if element.doc:
            cell_parts.append(_escape_latex(element.doc))

        if element.attributes:
            cell_parts.append("\\begin{itemize}")
            for attr in element.attributes:
                type_suffix = f": {attr.type}" if attr.type else ""
                cell_parts.append(
                    f"  \\item {_escape_latex(attr.name)}{_escape_latex(type_suffix)}"
                )
            cell_parts.append("\\end{itemize}")

        cell_text = " ".join(cell_parts)
        lines.append(
            f"{_escape_latex(element.name)} & {_escape_latex(element.kind)} & {cell_text} \\\\"
        )
        lines.append("\\hline")

    lines.append("\\end{longtable}")
    return "\n".join(lines)


def _render_events_table(events: list[ExposedElement]) -> str:
    """Render CIM Events occurrences as a table."""
    if not events:
        return "No events defined."

    lines = [
        "\\begin{longtable}{|p{4cm}|p{2cm}|p{8.5cm}|}",
        "\\hline",
        "\\textbf{Name} & \\textbf{Kind} & \\textbf{Description} \\\\",
        "\\hline",
        "\\endhead",
    ]
    for event in events:
        desc = _escape_latex(event.doc) if event.doc else ""
        lines.append(
            f"{_escape_latex(event.name)} & {_escape_latex(event.kind)} & {desc} \\\\"
        )
        lines.append("\\hline")

    lines.append("\\end{longtable}")
    return "\n".join(lines)


def _render_boundary_ports_and_interfaces(section: SectionIR) -> str:
    """Render boundary port and interface definitions (port name, interface name, flow properties, types) for PIM Interface Design."""
    ports = [e for e in section.exposed_elements if e.kind == "port"]
    interfaces = [e for e in section.exposed_elements if e.kind == "interface"]
    if not ports and not interfaces:
        return ""

    lines: list[str] = []

    if ports:
        lines.append("\\subsubsection{Boundary Ports}")
        lines.append(
            "\\begin{longtable}{|p{2.2cm}|p{1.8cm}|p{4cm}|p{5.5cm}|}",
        )
        lines.append("\\hline")
        lines.append(
            "\\textbf{Port} & \\textbf{Direction} & \\textbf{Item flows} & \\textbf{Signal flows} \\\\"
        )
        lines.append("\\hline")
        lines.append("\\endhead")
        for port in ports:
            items = [fp for fp in port.flow_properties if fp.kind == "item"]
            signals = [fp for fp in port.flow_properties if fp.kind == "attribute"]
            item_str = ", ".join(
                f"{_escape_latex(fp.name)}: {_escape_latex(fp.type or '')}"
                for fp in items
            ) or "---"
            signal_str = ", ".join(
                f"{_escape_latex(fp.name)}: {_escape_latex(fp.type or '')}"
                for fp in signals
            ) or "---"
            dirs = {fp.direction for fp in port.flow_properties}
            dir_str = ", ".join(sorted(dirs)) if dirs else "---"
            lines.append(
                f"{_escape_latex(port.name)} & {_escape_latex(dir_str)} & {_escape_latex(item_str)} & {_escape_latex(signal_str)} \\\\"
            )
            lines.append("\\hline")
        lines.append("\\end{longtable}")
        lines.append("")

    if interfaces:
        lines.append("\\subsubsection{Interfaces}")
        lines.append(
            "\\begin{longtable}{|p{2.5cm}|p{3cm}|p{3cm}|p{4cm}|}",
        )
        lines.append("\\hline")
        lines.append(
            "\\textbf{Interface} & \\textbf{Supplier port} & \\textbf{Consumer port} & \\textbf{Description} \\\\"
        )
        lines.append("\\hline")
        lines.append("\\endhead")
        for iface in interfaces:
            supplier = ""
            consumer = ""
            for e in iface.interface_ends:
                if "supplier" in e.role.lower():
                    supplier = e.port_type
                elif "consumer" in e.role.lower():
                    consumer = e.port_type
            if not supplier and iface.interface_ends:
                supplier = iface.interface_ends[0].port_type
            if not consumer and len(iface.interface_ends) > 1:
                consumer = iface.interface_ends[1].port_type
            desc = _escape_latex(iface.doc) if iface.doc else "---"
            lines.append(
                f"{_escape_latex(iface.name)} & {_escape_latex(supplier)} & {_escape_latex(consumer)} & {desc} \\\\"
            )
            lines.append("\\hline")
        lines.append("\\end{longtable}")

    return "\n".join(lines)


def _render_psm_interface_bindings(section: SectionIR) -> str:
    """Render PSM interface bindings: binding part defs with parameter tables (name, type, default), ports/interfaces table, error mappings."""
    prefix = "PSM_Interfaces::"
    binding_names = ("MLLP Ingress Binding", "HTTP Egress Binding", "Runtime Config Binding")
    bindings = [
        e
        for e in section.exposed_elements
        if e.kind == "part"
        and e.qualified_name.startswith(prefix)
        and e.name in binding_names
    ]
    bindings.sort(key=lambda x: (binding_names.index(x.name) if x.name in binding_names else 99, x.qualified_name))
    error_mappings = [
        e
        for e in section.exposed_elements
        if e.kind == "part"
        and e.qualified_name.startswith(prefix)
        and e.name in ("MLLP Error Mapping", "HTTP Response Mapping")
    ]
    ports = [e for e in section.exposed_elements if e.kind == "port" and e.qualified_name.startswith(prefix)]
    interfaces = [e for e in section.exposed_elements if e.kind == "interface" and e.qualified_name.startswith(prefix)]

    lines: list[str] = []

    for binding in bindings:
        lines.append(f"\\subsubsection{{{_escape_latex(binding.name)}}}")
        lines.append("")
        if binding.doc:
            lines.append(_escape_latex(binding.doc))
            lines.append("")
        if binding.attributes:
            lines.append("\\begin{longtable}{|p{3.5cm}|p{2.5cm}|p{4cm}|}")
            lines.append("\\hline")
            lines.append("\\textbf{Parameter} & \\textbf{Type} & \\textbf{Default} \\\\")
            lines.append("\\hline")
            lines.append("\\endhead")
            for attr in binding.attributes:
                base_type, default = _parse_type_and_default(attr.type)
                default_tex = _escape_latex(default) if default else "---"
                lines.append(f"{_escape_latex(attr.name)} & {_escape_latex(base_type)} & {default_tex} \\\\")
                lines.append("\\hline")
            lines.append("\\end{longtable}")
            lines.append("")

    if ports or interfaces:
        lines.append("\\subsubsection{PSM Ports and Interfaces}")
        lines.append("")
        port_interface_tex = _render_boundary_ports_and_interfaces(section)
        if port_interface_tex:
            lines.append(port_interface_tex)

    for em in error_mappings:
        lines.append(f"\\subsubsection{{{_escape_latex(em.name)}}}")
        lines.append("")
        if em.doc:
            lines.append(_escape_latex(em.doc))
            lines.append("")

    return "\n".join(lines)
