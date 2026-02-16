from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path

from .base import GeneratedArtifact, GenerationOptions
from .extractor import ExtractionResult, extract_documents
from .parser import ModelIndex, parse_model_directory
from .registry import TargetRegistry
from .validation import validate_extraction_graph, validate_model_index


@dataclass(slots=True)
class RunResult:
    model_index: ModelIndex
    extraction: ExtractionResult
    artifacts: list[GeneratedArtifact]


def run_generation(
    *,
    registry: TargetRegistry,
    target_name: str,
    model_dir: Path,
    output_dir: Path,
    version: str,
) -> RunResult:
    model_index = parse_model_directory(model_dir)
    validate_model_index(model_index)

    extraction = extract_documents(model_index)
    validate_extraction_graph(extraction, model_index)

    target = registry.get(target_name)
    options = GenerationOptions(version=version, model_dir=model_dir, output_dir=output_dir)
    artifacts = target.generate(extraction.documents, options)
    return RunResult(model_index=model_index, extraction=extraction, artifacts=artifacts)
