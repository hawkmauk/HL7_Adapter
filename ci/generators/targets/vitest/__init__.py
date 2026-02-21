"""Vitest test generation target.

Reads verification case definitions from the ModelGraph and emits
TypeScript test files (Vitest) under src/__tests__/.
"""
from __future__ import annotations

from pathlib import Path

from ...base import GeneratedArtifact, GenerationOptions, GeneratorTarget
from ...ir import ModelGraph
from ...registry import register_target
from ..typescript.queries import (
    _find_psm_node,
    _get_config_attributes,
    get_component_map,
)
from ..typescript.service import get_service_constructor_params
from .queries import get_verification_cases, group_cases_by_subject
from .test_module import build_test_file, build_service_test_file


class VitestGenerator(GeneratorTarget):
    name = "vitest"
    supported_renders: set[str] = {"TypeScript"}
    supported_viewpoint_types: set[str] = {"test"}

    def generate(
        self,
        graph: ModelGraph,
        options: GenerationOptions,
    ) -> list[GeneratedArtifact]:
        output_dir = Path(options.output_dir)
        src_dir = output_dir / "src"
        tests_dir = src_dir / "__tests__"
        tests_dir.mkdir(parents=True, exist_ok=True)

        documents = options.extra.get("_documents", [])
        document = documents[0] if len(documents) == 1 else None

        vcase_nodes = get_verification_cases(graph, document=document)
        if not vcase_nodes:
            return []

        by_module = group_cases_by_subject(graph, vcase_nodes, document=document)
        # Use full component map for config resolution so every module gets correct config_attrs
        # (matches service.ts constructor logic from get_component_map + _find_psm_node + _get_config_attributes).
        full_component_map = get_component_map(graph)
        artifacts: list[GeneratedArtifact] = []

        for module_file, descriptors in by_module.items():
            class_name = descriptors[0]["class_name"]
            if module_file == "service":
                # Use full component list so service test constructor matches service.ts
                service_params = get_service_constructor_params(graph, document=None)
                content = build_service_test_file(class_name, descriptors, service_params)
            else:
                config_attrs = _config_attrs_for_module(
                    graph, full_component_map, module_file, class_name
                )
                content = build_test_file(
                    module_file, class_name, descriptors, config_attrs=config_attrs
                )
            out_path = tests_dir / f"{module_file}.test.ts"
            out_path.write_text(content, encoding="utf-8")
            artifacts.append(
                GeneratedArtifact(
                    path=out_path,
                    artifact_type="test-module",
                    document_id=module_file,
                )
            )

        return artifacts


def _config_attrs_for_module(
    graph: ModelGraph,
    component_map: list[dict],
    module_file: str,
    class_name: str,
) -> list[dict[str, str]]:
    """Resolve PSM part for this module and return its config attributes for test defaults."""
    expected_output = f"{module_file}.ts"
    for comp in component_map:
        if comp.get("output_file") == expected_output:
            psm = _find_psm_node(
                graph, comp["psm_short"], comp.get("part_def_qname")
            )
            if psm:
                return _get_config_attributes(psm)
            break
    return []


@register_target
def _make_vitest_generator() -> GeneratorTarget:
    return VitestGenerator()
