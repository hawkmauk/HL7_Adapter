"""Trade study rendering for PSM Technology Selection."""
from __future__ import annotations

import re

from ...ir import ExposedElement, SectionIR
from .escape import _escape_latex


def _humanise_trade_study_name(name: str) -> str:
    """E.g. LanguageRuntimeTradeStudy -> Language Runtime."""
    if name.endswith("TradeStudy"):
        name = name[: -len("TradeStudy")].replace("_", " ")
        chars = []
        for i, c in enumerate(name):
            if i and c.isupper() and name[i - 1].islower():
                chars.append(" ")
            chars.append(c)
        return "".join(chars)
    return name


def _normalise_for_alt_match(s: str) -> str:
    """Lowercase, alphanumeric only, for matching scored part names to alternative names."""
    return re.sub(r"[^a-z0-9]", "", s.lower())


def _match_scored_to_alternative(scored: ExposedElement, alternatives: list[ExposedElement]) -> ExposedElement | None:
    """Return the alternative element that best matches this scored part (e.g. nodeScored -> Node.js Runtime), or None."""
    key = _normalise_for_alt_match(scored.name.replace("Scored", "").strip())
    if not key:
        return None
    for alt in alternatives:
        alt_key = _normalise_for_alt_match(alt.name.split()[0] if alt.name else "")
        if key == alt_key or key in alt_key or alt_key in key:
            return alt
    return None


def _compute_score(alt: ExposedElement, weights: list[float]) -> str:
    """Compute weighted score from alternative's value_assignments and criteria weights. Returns formatted number or '---'."""
    values = getattr(alt, "value_assignments", []) or []
    if not values or not weights or len(values) != len(weights):
        return "---"
    total = sum(v * w for v, w in zip(values, weights))
    return f"{total:.2f}"


def _render_technology_selection_table(section: SectionIR) -> str:
    """Render parametric trade studies for DOC_PSM_PlatformRealization: one subsubsection per study with intro, Alternative|Score table from Scored*Alternative instances, and selection."""
    prefix = "PSM_TechnologySelection::"
    trade_studies = [
        e
        for e in section.exposed_elements
        if e.kind == "package"
        and e.qualified_name.startswith(prefix)
        and e.qualified_name.count("::") == 1
        and e.name.endswith("TradeStudy")
    ]
    if not trade_studies:
        return ""
    order = ("LanguageRuntimeTradeStudy", "HL7ParserTradeStudy", "HTTPClientTradeStudy", "DeploymentModelTradeStudy")
    trade_studies.sort(key=lambda p: (order.index(p.name) if p.name in order else 99, p.name))
    by_qname = {e.qualified_name: e for e in section.exposed_elements}
    exclude_alternatives = ("context", "criteria", "criterion", "alternative", "scored", "assessment")
    lines: list[str] = []
    for study in trade_studies:
        study_prefix = study.qualified_name + "::"
        heading = _humanise_trade_study_name(study.name)
        lines.append(f"\\subsubsection{{{_escape_latex(heading)}}}")
        lines.append("")
        if study.doc:
            lines.append(_escape_latex(study.doc))
            lines.append("")
        scored_def = next(
            (
                e
                for e in section.exposed_elements
                if e.kind == "part"
                and e.qualified_name.startswith(study_prefix)
                and "Scored" in e.name
                and "Alternative" in e.name
            ),
            None,
        )
        scored_short = (
            re.sub(r"\s+", "", scored_def.qualified_name.split("::")[-1]) if scored_def else None
        )
        scored_parts = [
            e
            for e in section.exposed_elements
            if e.kind == "part"
            and e.qualified_name.startswith(study_prefix)
            and scored_short
            and scored_short in getattr(e, "supertypes", [])
        ]
        alternatives = [
            e
            for e in section.exposed_elements
            if e.kind == "part"
            and e.qualified_name.startswith(study_prefix)
            and e.qualified_name != study_prefix.rstrip(":")
            and not any(x in e.name.lower() for x in exclude_alternatives)
        ]
        alternatives.sort(key=lambda e: e.name)
        scored_parts.sort(key=lambda e: e.name)
        criteria_def = next(
            (
                e
                for e in section.exposed_elements
                if e.kind == "part"
                and e.qualified_name.startswith(study_prefix)
                and "Assessment" in e.name
                and "Criteria" in e.name
            ),
            None,
        )
        weights = list(getattr(criteria_def, "weight_assignments", [])) if criteria_def else []
        if scored_parts:
            lines.append("\\textbf{Alternatives and scores.}")
            lines.append("")
            lines.append("\\begin{longtable}{|p{3.5cm}|p{3cm}|}")
            lines.append("\\hline")
            lines.append("\\textbf{Alternative} & \\textbf{Score} \\\\")
            lines.append("\\hline")
            lines.append("\\endhead")
            for sp in scored_parts:
                alt_el = _match_scored_to_alternative(sp, alternatives)
                alt_name = _escape_latex(alt_el.name if alt_el else sp.name)
                score_val = _compute_score(alt_el, weights) if alt_el else "---"
                lines.append(f"{alt_name} & {score_val} \\\\")
                lines.append("\\hline")
            lines.append("\\end{longtable}")
            lines.append("")
        context_parts = [
            e
            for e in section.exposed_elements
            if e.kind == "part"
            and e.qualified_name.startswith(study_prefix)
            and "context" in e.name.lower()
        ]
        if context_parts:
            ctx = context_parts[0]
            if ctx.doc:
                lines.append("\\textbf{Selection.}")
                lines.append("")
                lines.append(_escape_latex(ctx.doc))
                lines.append("")
    return "\n".join(lines)
