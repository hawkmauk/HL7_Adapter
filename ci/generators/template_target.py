from __future__ import annotations

"""
Example GeneratorTarget implementation.

This module is not wired into the default registry; it exists purely as
documentation and a starting point for new targets.
"""

from pathlib import Path

from .base import GeneratedArtifact, GenerationOptions, GeneratorTarget
from .ir import DocumentIR


class ExampleGenerator(GeneratorTarget):
    """Minimal example target that writes one file per document."""

    name = "example"
    supported_renders: set[str] = set()

    def generate(
        self,
        documents: list[DocumentIR],
        options: GenerationOptions,
    ) -> list[GeneratedArtifact]:
        output_dir = Path(options.output_dir)
        output_dir.mkdir(parents=True, exist_ok=True)

        artifacts: list[GeneratedArtifact] = []
        for document in documents:
            filename = f"{document.document_id}.txt"
            path = output_dir / filename
            path.write_text(
                f"Document: {document.document_id}\nTitle: {document.title}\n",
                encoding="utf-8",
            )
            artifacts.append(
                GeneratedArtifact(
                    path=path,
                    artifact_type="example",
                    document_id=document.document_id,
                )
            )
        return artifacts

