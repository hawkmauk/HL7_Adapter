"""Vitest test generation target.

Reads verification case definitions from the ModelGraph and emits
TypeScript test files (Vitest) under src/__tests__/.
"""
from __future__ import annotations

from pathlib import Path

from ...base import GeneratedArtifact, GenerationOptions, GeneratorTarget
from ...ir import ModelGraph
from ...registry import register_target
from .queries import get_verification_cases, group_cases_by_subject
from .test_module import build_test_file


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
        artifacts: list[GeneratedArtifact] = []

        for module_file, descriptors in by_module.items():
            class_name = descriptors[0]["class_name"]
            content = build_test_file(module_file, class_name, descriptors)
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


@register_target
def _make_vitest_generator() -> GeneratorTarget:
    return VitestGenerator()
