from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path

from .base import GeneratedArtifact, GenerationOptions
from .errors import GenerationError
from .extraction import ExtractionResult, extract_documents
from .graph import build_model_graph
from .ir import ModelGraph
from .parsing import ModelIndex, parse_model_directory
from .registry import TargetRegistry
from .validation import validate_extraction_graph, validate_model_index


@dataclass(slots=True)
class RunResult:
    model_index: ModelIndex
    extraction: ExtractionResult
    artifacts: list[GeneratedArtifact]
    graph: ModelGraph | None = None


def run_generation(
    *,
    registry: TargetRegistry,
    target_name: str,
    model_dir: Path,
    output_dir: Path,
    version: str,
    extra: dict | None = None,
) -> RunResult:
    try:
        model_index = parse_model_directory(model_dir)
        validate_model_index(model_index)

        extraction = extract_documents(model_index)
        validate_extraction_graph(extraction, model_index)

        graph = build_model_graph(model_index)
    except GenerationError:
        raise
    except Exception as exc:  # pragma: no cover - defensive coding
        raise GenerationError(
            f"Failed to prepare generation for target '{target_name}' "
            f"from model_dir={model_dir} to output_dir={output_dir}"
        ) from exc

    effective_extra = dict(extra or {})
    effective_extra["_documents"] = extraction.documents

    target = registry.get(target_name)
    options = GenerationOptions(
        version=version,
        model_dir=model_dir,
        output_dir=output_dir,
        extra=effective_extra,
    )
    try:
        artifacts = target.generate(graph, options)
    except GenerationError:
        raise
    except Exception as exc:  # pragma: no cover - defensive coding
        raise GenerationError(
            f"Target '{target_name}' failed while generating artifacts into {output_dir}"
        ) from exc

    return RunResult(
        model_index=model_index,
        extraction=extraction,
        artifacts=artifacts,
        graph=graph,
    )
