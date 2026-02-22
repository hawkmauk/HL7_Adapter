"""TypeScript code generation target.

Reads PSM component definitions and PIM state machines from the ModelGraph
and emits a Node.js/TypeScript application skeleton:

- One .ts module per PSM component (state enum, transition methods, config).
- A service.ts orchestrator wiring components per HL7AdapterService.
- package.json with dependencies from PSM technology bindings.
- tsconfig.json so the skeleton compiles.
"""
from __future__ import annotations

from pathlib import Path

from ...base import GeneratedArtifact, GenerationOptions, GeneratorTarget
from ...ir import ModelGraph
from ...registry import register_target
from ...templates import copy_asset, get_template_dir
from .service import _build_service_module
from .components import _build_component_module
from .config import (
    _build_config_json,
    _build_index,
    _build_main_module,
    _build_package_json,
    _build_tsconfig,
    generated_ts_header,
)
from .queries import get_component_map


class TypeScriptGenerator(GeneratorTarget):
    name = "typescript"
    supported_renders: set[str] = {"TypeScript"}
    supported_viewpoint_types: set[str] = {"executable"}

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

        documents = options.extra.get("_documents", [])
        document = documents[0] if len(documents) == 1 else None
        component_map = get_component_map(graph, document=document)
        header = generated_ts_header(options.version)
        for comp in component_map:
            source = _build_component_module(graph, comp)
            out_path = src_dir / comp["output_file"]
            out_path.write_text(header + source, encoding="utf-8")
            artifacts.append(GeneratedArtifact(
                path=out_path,
                artifact_type="ts-module",
                document_id=comp["psm_short"],
            ))

        service_source = _build_service_module(graph, document=document)
        if service_source:
            service_path = src_dir / "service.ts"
            service_path.write_text(header + service_source, encoding="utf-8")
            artifacts.append(GeneratedArtifact(path=service_path, artifact_type="ts-module", document_id="Service"))
            main_source = _build_main_module(graph, document=document)
            if main_source:
                main_path = src_dir / "main.ts"
                main_path.write_text(header + main_source, encoding="utf-8")
                artifacts.append(GeneratedArtifact(path=main_path, artifact_type="ts-module", document_id="main"))
                config_json = _build_config_json(graph, document=document)
                if config_json:
                    config_path = output_dir / "config.json"
                    config_path.write_text(config_json, encoding="utf-8")
                    artifacts.append(GeneratedArtifact(path=config_path, artifact_type="config-json"))

        index_source = _build_index(graph, document=document)
        index_path = src_dir / "index.ts"
        index_path.write_text(header + index_source, encoding="utf-8")
        artifacts.append(GeneratedArtifact(path=index_path, artifact_type="ts-module"))

        # Copy .ts template assets (e.g. scripts/init-db.ts) into output, preserving structure
        template_dir = get_template_dir("typescript")
        if template_dir.exists():
            for ts_file in template_dir.rglob("*.ts"):
                rel = ts_file.relative_to(template_dir)
                dest_dir = output_dir / rel.parent
                dest_dir.mkdir(parents=True, exist_ok=True)
                artifact = copy_asset(ts_file, dest_dir, artifact_type="ts-script")
                artifacts.append(artifact)

        return artifacts


@register_target
def _make_typescript_generator() -> GeneratorTarget:
    return TypeScriptGenerator()
