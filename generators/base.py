from __future__ import annotations

from abc import ABC, abstractmethod
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any

from .ir import DocumentIR


@dataclass(slots=True)
class GenerationOptions:
    version: str
    model_dir: Path
    output_dir: Path
    extra: dict[str, Any] = field(default_factory=dict)


@dataclass(slots=True)
class GeneratedArtifact:
    path: Path
    artifact_type: str
    document_id: str | None = None


class GeneratorTarget(ABC):
    """Base contract for target generators (latex, code, etc.)."""

    name: str
    supported_renders: set[str]

    @abstractmethod
    def generate(
        self,
        documents: list[DocumentIR],
        options: GenerationOptions,
    ) -> list[GeneratedArtifact]:
        """Generate output artifacts for an extracted document set."""
