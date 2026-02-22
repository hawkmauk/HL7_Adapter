"""Core element extraction and qualified-name resolution from SysML text."""
from __future__ import annotations

from pathlib import Path

from ..errors import ParsingError
from .model import ModelAttribute, ModelElement, _strip_quotes, _strip_short_name
from .regex import (
    ACTION_PARAM_RE,
    ALIAS_RE,
    ALLOCATION_SATISFY_RE,
    ATTR_VALUE_ASSIGN_RE,
    ATTR_WEIGHT_ASSIGN_RE,
    ATTRIBUTE_NO_SEMICOLON_RE,
    ATTRIBUTE_RE,
    BLOCK_DECL_RE,
    CONSTANT_RE,
    CONSTRAINT_PARAM_RE,
    DOC_RE,
    ENTRY_ACTION_RE,
    ENTRY_THEN_RE,
    DO_ACTION_RE,
    ENUM_LITERAL_RE,
    EXHIBIT_RE,
    EXPOSE_RE,
    FLOW_PROPERTY_RE,
    FRAME_RE,
    INTERFACE_END_RE,
    NAMED_REP_RE,
    PERFORM_ACTION_RE,
    REFINEMENT_DEPENDENCY_RE,
    RENDER_RE,
    SATISFY_RE,
    STATE_OR_ACCEPT_RE,
    STATE_PORT_RE,
    SUBJECT_RE,
    VERIFY_REF_RE,
)


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
            doc_lines = [line.strip() for line in raw_doc.splitlines()]
            doc = "\n".join(doc_lines).strip()

        render_match = RENDER_RE.search(body)
        render_kind = render_match.group("kind") if render_match else None

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

        supertypes: list[str] = []
        tail_clean = tail.strip()
        if tail_clean:
            for part in tail_clean.split(","):
                part_clean = part.strip()
                if not part_clean:
                    continue
                while part_clean.startswith(":") or part_clean.startswith(">"):
                    part_clean = part_clean[1:].lstrip()
                if not part_clean:
                    continue
                supertypes.append(_strip_quotes(part_clean))

        aliases: list[tuple[str, str]] = []
        if kind == "package":
            for alias_match in ALIAS_RE.finditer(body):
                aliases.append((alias_match.group("alias"), alias_match.group("target")))

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

        interface_ends: list[tuple[str, str]] = []
        if kind == "interface":
            for end_match in INTERFACE_END_RE.finditer(body):
                interface_ends.append((end_match.group("role"), end_match.group("port_type")))

        allocation_satisfy: list[tuple[str, str]] = []
        for sat_match in ALLOCATION_SATISFY_RE.finditer(body):
            allocation_satisfy.append(
                (sat_match.group(1).strip(), sat_match.group(2).strip())
            )

        refinement_dependencies: list[tuple[str, str]] = []
        for ref_match in REFINEMENT_DEPENDENCY_RE.finditer(body):
            refinement_dependencies.append(
                (ref_match.group(1).strip(), ref_match.group(2).strip())
            )

        constraint_params: list[tuple[str, str]] = []
        if kind == "constraint":
            for cp_match in CONSTRAINT_PARAM_RE.finditer(body):
                constraint_params.append(
                    (cp_match.group("name"), cp_match.group("type").strip())
                )

        value_assignments = [float(m.group(1)) for m in ATTR_VALUE_ASSIGN_RE.finditer(body)]
        weight_assignments = [float(m.group(1)) for m in ATTR_WEIGHT_ASSIGN_RE.finditer(body)]

        transitions: list[tuple[str, str, str, str | None]] = []
        entry_target: str | None = None
        entry_action: str | None = None
        do_action: str | None = None
        state_ports: list[tuple[str, str, str]] = []
        if kind == "state":
            current_state: str | None = None
            for sa_match in STATE_OR_ACCEPT_RE.finditer(body):
                if sa_match.group("state_name"):
                    current_state = sa_match.group("state_name")
                elif sa_match.group("signal") and current_state:
                    action = sa_match.group("transition_action")
                    transitions.append(
                        (current_state, sa_match.group("signal"), sa_match.group("target"), action if action else None)
                    )
            et_match = ENTRY_THEN_RE.search(body)
            if et_match:
                entry_target = et_match.group("target")
            ea_match = ENTRY_ACTION_RE.search(body)
            if ea_match:
                entry_action = ea_match.group("action")
            da_match = DO_ACTION_RE.search(body)
            if da_match:
                do_action = da_match.group("action")
            for sp_match in STATE_PORT_RE.finditer(body):
                state_ports.append(
                    (sp_match.group("dir"), _strip_quotes(sp_match.group("name")), sp_match.group("type").strip())
                )

        effective_kind = kind
        raw_text = text[match.start():open_brace_index]
        if kind == "attribute" and "def" in raw_text:
            effective_kind = "attribute def"
        if kind == "action" and "def" in raw_text:
            effective_kind = "action def"
        if kind == "verification" and "def" in raw_text:
            effective_kind = "verification def"
        if kind == "enum" and "def" in raw_text:
            effective_kind = "enum def"

        enum_literals: list[str] = []
        if effective_kind == "enum def":
            enum_literals = [m.group("name") for m in ENUM_LITERAL_RE.finditer(body)]

        perform_actions: list[tuple[str, str]] = []
        exhibit_refs: list[str] = []
        constants: list[tuple[str, str, str]] = []
        if kind == "part":
            for pa_match in PERFORM_ACTION_RE.finditer(body):
                perform_actions.append(
                    (pa_match.group("name"), pa_match.group("type").strip())
                )
            for ex_match in EXHIBIT_RE.finditer(body):
                exhibit_refs.append(ex_match.group("name"))
            for const_match in CONSTANT_RE.finditer(body):
                constants.append(
                    (
                        const_match.group("name"),
                        const_match.group("type").strip(),
                        const_match.group("value").strip(),
                    )
                )

        action_params: list[tuple[str, str, str | None]] = []
        if effective_kind == "action def":
            for ap_match in ACTION_PARAM_RE.finditer(body):
                action_params.append(
                    (ap_match.group("dir"), ap_match.group("name"), (ap_match.group("type") or "").strip() or None)
                )

        textual_representations: list[tuple[str, str, str]] = []
        for tr_match in NAMED_REP_RE.finditer(body):
            rep_name = tr_match.group(1)
            lang = tr_match.group(2).strip()
            rep_body = tr_match.group(3)
            if rep_body is not None:
                textual_representations.append((rep_name, lang, rep_body))

        verify_refs: list[str] = []
        subject_ref: tuple[str, str] | None = None
        if kind == "verification":
            verify_refs = [m.group(1).strip() for m in VERIFY_REF_RE.finditer(body)]
            sub_match = SUBJECT_RE.search(body)
            if sub_match:
                subject_ref = (sub_match.group(1).strip(), sub_match.group(2).strip())

        elements.append(
            ModelElement(
                kind=effective_kind,
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
                constants=constants,
                aliases=aliases,
                flow_properties=flow_properties,
                interface_ends=interface_ends,
                allocation_satisfy=allocation_satisfy,
                refinement_dependencies=refinement_dependencies,
                constraint_params=constraint_params,
                value_assignments=value_assignments,
                weight_assignments=weight_assignments,
                transitions=transitions,
                entry_target=entry_target,
                entry_action=entry_action,
                do_action=do_action,
                state_ports=state_ports,
                textual_representations=textual_representations,
                perform_actions=perform_actions,
                action_params=action_params,
                verify_refs=verify_refs,
                subject_ref=subject_ref,
                exhibit_refs=exhibit_refs,
                enum_literals=enum_literals,
            )
        )
    return elements


def _resolve_qualified_names(elements: list[ModelElement]) -> None:
    containers = [e for e in elements if e.kind in ("package", "state", "verification def")]
    for element in elements:
        enclosing = [
            c
            for c in containers
            if c is not element
            and c.file_path == element.file_path
            and c.start_index < element.start_index < element.end_index < c.end_index
        ]
        enclosing.sort(key=lambda c: c.end_index - c.start_index, reverse=True)
        path = [c.name for c in enclosing]
        element.qualified_name = "::".join(path + [element.name]) if path else element.name
