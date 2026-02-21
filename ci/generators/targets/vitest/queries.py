"""Graph query helpers for Vitest test generation from verification cases."""
from __future__ import annotations

from ...ir import GraphNode, ModelGraph
from ..typescript.naming import _display_name_to_class_name
from ..typescript.queries import get_component_map, _resolve_part_def_qname


def get_verification_cases(
    graph: ModelGraph,
    document: object | None = None,
) -> list[GraphNode]:
    """Return verification def nodes to generate tests for.

    If document has exposed_elements, only verification defs in that set are included.
    Otherwise all verification def nodes under VER_* packages are included.
    """
    exposed_qnames: set[str] | None = None
    if document is not None and getattr(document, "exposed_elements", None):
        exposed_qnames = {
            e.qualified_name
            for e in document.exposed_elements
            if getattr(e, "kind", "") == "verification def"
        }
        if not exposed_qnames:
            exposed_qnames = None

    result: list[GraphNode] = []
    for node in graph.nodes.values():
        if node.kind != "verification def":
            continue
        if exposed_qnames is not None and node.qname not in exposed_qnames:
            continue
        if "::" in node.qname and node.qname.split("::")[0].startswith("VER_"):
            result.append(node)
    result.sort(key=lambda n: n.qname)
    return result


def _build_subject_lookup(
    graph: ModelGraph,
) -> dict[str, tuple[str, str]]:
    """Build a mapping from component short_name to (module_file, class_name).

    Reuses the TypeScript generator's component map (without document
    filtering) so that test imports align exactly with the generated
    source modules regardless of which view the test document exposes.
    Also registers services from the PSM package's direct part usages
    (e.g. part hl7AdapterService : PhysicalArchitecture::HL7AdapterService).
    """
    lookup: dict[str, tuple[str, str]] = {}
    for comp in get_component_map(graph):
        short = comp["psm_short"]
        module_file = comp["output_file"].removesuffix(".ts")
        class_name = comp["class_name"]
        lookup[short] = (module_file, class_name)

    _register_service_in_lookup(graph, lookup)
    return lookup


def _find_psm_root_package(graph: ModelGraph) -> str | None:
    """Return the qname of the root PSM package (package named PSM containing service part usages).

    Prefers the top-level package named PSM; if multiple exist, returns the one with shortest qname.
    """
    candidates = [
        n for n in graph.nodes.values()
        if n.kind == "package" and n.name == "PSM"
    ]
    if not candidates:
        return None
    return min(candidates, key=lambda n: (len(n.qname.split("::")), n.qname)).qname


def _register_service_in_lookup(
    graph: ModelGraph,
    lookup: dict[str, tuple[str, str]],
) -> None:
    """Register services from the PSM package's direct part usages.

    Services are identified as the direct part usages of the PSM package
    (e.g. part hl7AdapterService : PhysicalArchitecture::HL7AdapterService in PSM.sysml).
    For each such part, the type is resolved to the part def; the part def's
    display name yields the class name, and the module is 'service' (single
    service module). Supports multiple services: each part usage is registered
    with its part def's short_name / name as the lookup key.
    """
    psm_qname = _find_psm_root_package(graph)
    if not psm_qname:
        return
    for part_usage in graph.children(psm_qname, kind="part") or []:
        for edge in graph.outgoing(part_usage.qname, "supertype"):
            type_ref = (edge.target or "").strip()
            if not type_ref:
                continue
            part_def_qname = _resolve_part_def_qname(graph, type_ref, prefer_prefix="PSM")
            if not part_def_qname:
                continue
            part_def = graph.get(part_def_qname)
            if not part_def or part_def.kind not in ("part", "part def"):
                continue
            short = (part_def.short_name or part_def.name or "").replace(" ", "")
            if not short or short in lookup:
                continue
            display = (part_def.name or part_def.short_name or "").strip()
            class_name = _display_name_to_class_name(display)
            lookup[short] = ("service", class_name)
            break


def _resolve_subject_module(
    graph: ModelGraph,
    vcase_node: GraphNode,
    lookup: dict[str, tuple[str, str]],
) -> tuple[str, str, str]:
    """Derive (subject_type, module_file, class_name) from the graph.

    Follows the "subject" edge to the target node and matches it against
    the component lookup built from the TypeScript generator's component map.
    Falls back to deriving names from the node's display name.
    """
    subject_ref = vcase_node.properties.get("subject_ref") or {}
    subject_name_raw = subject_ref.get("type", "")
    subject_type = subject_name_raw.split("::")[-1].strip()

    for edge in graph.outgoing(vcase_node.qname, "subject"):
        target_node = graph.get(edge.target)
        if target_node and target_node.kind in ("part def", "part"):
            short = (target_node.short_name or target_node.name or "").replace(" ", "")
            if short in lookup:
                module_file, class_name = lookup[short]
                return subject_type or short, module_file, class_name
            display = (target_node.name or target_node.short_name or "").strip()
            return (
                subject_type or display,
                display.replace(" ", "_").lower(),
                display.replace(" ", ""),
            )

    if subject_type:
        return subject_type, subject_type.replace(" ", "_").lower(), subject_type
    return "subject", "subject", "Subject"


def get_test_descriptor(
    graph: ModelGraph,
    vcase_node: GraphNode,
    lookup: dict[str, tuple[str, str]],
) -> dict:
    """Extract subject, verify refs, doc, and action steps for a verification case."""
    subject_ref = vcase_node.properties.get("subject_ref") or {}
    subject_name = subject_ref.get("name", "subject")
    subject_type, module_file, class_name = _resolve_subject_module(graph, vcase_node, lookup)
    verify_refs = vcase_node.properties.get("verify_refs") or []
    requirement_ids = [r.split("::")[-1] for r in verify_refs]

    action_steps: list[dict] = []
    for child in graph.children(vcase_node.qname):
        if child.kind in ("action def", "action"):
            action_steps.append({
                "name": child.name,
                "doc": (child.doc or "").strip(),
                "ts_body": _get_ts_rep(child),
            })
    action_steps.sort(key=lambda a: (a["name"] != "collectData", a["name"] != "processData", a["name"]))

    config_var: str | None = None
    for r in (vcase_node.properties.get("textual_representations") or []):
        if (r.get("name") or "").strip() == "configVar":
            body = (r.get("body") or "").strip()
            if body:
                config_var = body
            break

    return {
        "qname": vcase_node.qname,
        "name": vcase_node.name,
        "doc": (vcase_node.doc or "").strip(),
        "subject_name": subject_name,
        "subject_type": subject_type,
        "module_file": module_file,
        "class_name": class_name,
        "requirement_ids": requirement_ids,
        "action_steps": action_steps,
        "config_var": config_var,
    }


def _get_ts_rep(node: GraphNode) -> str | None:
    """Return rep body if present (language 'vitest' or 'typescript'); prefer vitest."""
    reps = node.properties.get("textual_representations") or []
    vitest_body: str | None = None
    ts_body: str | None = None
    for r in reps:
        lang = (r.get("language") or "").lower()
        body = (r.get("body") or "").strip()
        if not body:
            continue
        if lang == "vitest":
            vitest_body = body
        elif lang == "typescript":
            ts_body = body
    if vitest_body:
        return vitest_body
    if ts_body:
        return ts_body
    return None


def get_preamble_for_module(
    graph: ModelGraph,
    descriptors: list[dict],
) -> str | None:
    """Return preamble (e.g. test constants, strictConfig) from the verification package rep.

    If the first descriptor's package (e.g. VER_Parser) has a rep with language
    'vitest' or 'typescript', return its body; otherwise None.
    """
    if not descriptors:
        return None
    qname = descriptors[0].get("qname", "")
    if "::" not in qname:
        return None
    package_qname = qname.split("::")[0]
    node = graph.get(package_qname)
    if not node:
        return None
    reps = node.properties.get("textual_representations") or []
    for r in reps:
        lang = (r.get("language") or "").lower()
        body = (r.get("body") or "").strip()
        if body and lang in ("vitest", "typescript"):
            return body
    return None


def group_cases_by_subject(
    graph: ModelGraph,
    vcase_nodes: list[GraphNode],
    document: object | None = None,
) -> dict[str, list[dict]]:
    """Group verification case descriptors by subject module file (one test file per component)."""
    lookup = _build_subject_lookup(graph)
    by_module: dict[str, list[dict]] = {}
    for node in vcase_nodes:
        desc = get_test_descriptor(graph, node, lookup)
        key = desc["module_file"]
        by_module.setdefault(key, []).append(desc)
    for key in by_module:
        by_module[key].sort(key=lambda d: d["name"])
    return by_module
