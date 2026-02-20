"""TypeScript code generation target.

Reads PSM component definitions and PIM state machines from the ModelGraph
and emits a Node.js/TypeScript application skeleton:

- One .ts module per PSM component (state enum, transition methods, config).
- An adapter.ts orchestrator wiring components per HL7AdapterService.
- package.json with dependencies from PSM technology bindings.
- tsconfig.json so the skeleton compiles.
"""
from __future__ import annotations

from pathlib import Path

from ...base import GeneratedArtifact, GenerationOptions, GeneratorTarget
from ...ir import ModelGraph
from ...registry import register_target
from .adapter import _build_adapter_module
from .components import _build_component_module
from .config import _build_index, _build_package_json, _build_tsconfig
from .queries import COMPONENT_MAP


class TypeScriptGenerator(GeneratorTarget):
    name = "typescript"
    supported_renders: set[str] = set()

    def generate(
        self,
        graph: ModelGraph,
        options: GenerationOptions,
    ) -> list[GeneratedArtifact]:
        output_dir = Path(options.output_dir)
        src_dir = output_dir / "src"
        src_dir.mkdir(parents=True, exist_ok=True)

        artifacts: list[GeneratedArtifact] = []

        pkg_path = output_dir / "package.json"
        pkg_path.write_text(_build_package_json(), encoding="utf-8")
        artifacts.append(GeneratedArtifact(path=pkg_path, artifact_type="package-json"))

        tsc_path = output_dir / "tsconfig.json"
        tsc_path.write_text(_build_tsconfig(), encoding="utf-8")
        artifacts.append(GeneratedArtifact(path=tsc_path, artifact_type="tsconfig"))

        for comp in COMPONENT_MAP:
            source = _build_component_module(graph, comp)
            out_path = src_dir / comp["output_file"]
            out_path.write_text(source, encoding="utf-8")
            artifacts.append(GeneratedArtifact(
                path=out_path,
                artifact_type="ts-module",
                document_id=comp["psm_short"],
            ))

        adapter_source = _build_adapter_module(graph)
        adapter_path = src_dir / "adapter.ts"
        adapter_path.write_text(adapter_source, encoding="utf-8")
        artifacts.append(GeneratedArtifact(path=adapter_path, artifact_type="ts-module", document_id="HL7Adapter"))

        index_source = _build_index(graph)
        index_path = src_dir / "index.ts"
        index_path.write_text(index_source, encoding="utf-8")
        artifacts.append(GeneratedArtifact(path=index_path, artifact_type="ts-module"))

        return artifacts


@register_target
def _make_typescript_generator() -> GeneratorTarget:
    return TypeScriptGenerator()
