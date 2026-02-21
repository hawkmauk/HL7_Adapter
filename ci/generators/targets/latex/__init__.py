"""LaTeX generation target."""
from __future__ import annotations

from pathlib import Path

from ...base import GeneratedArtifact, GenerationOptions, GeneratorTarget
from ...errors import ValidationError
from ...ir import DocumentIR, ModelGraph
from ...registry import register_target
from ...templates import copy_asset
from .assets import STYLE_FILE_NAME, TEX4HT_CFG_NAME, _style_template_path, _template_dir, _try_convert_svg_to_pdf
from .document import _build_tex, _filename_for_document


class LatexGenerator(GeneratorTarget):
    name = "latex"
    supported_renders = {"ElementTable", "TreeDiagram", "TextualNotation"}
    supported_viewpoint_types = {"documentation"}

    def generate(
        self,
        graph: ModelGraph,
        options: GenerationOptions,
    ) -> list[GeneratedArtifact]:
        documents: list[DocumentIR] = options.extra.get("_documents", [])
        output_dir = Path(options.output_dir)
        output_dir.mkdir(parents=True, exist_ok=True)

        style_source = _style_template_path()
        if not style_source.exists():
            raise ValueError(f"Missing LaTeX style template: {style_source}")

        artifacts: list[GeneratedArtifact] = []

        style_artifact = copy_asset(style_source, output_dir, artifact_type="style")
        artifacts.append(style_artifact)

        template_dir = style_source.parent
        logo_svg = template_dir / "lyrebird-logo.svg"
        logo_pdf = template_dir / "lyrebird-logo.pdf"
        if logo_svg.exists():
            copy_asset(logo_svg, output_dir, artifact_type="logo-svg")
        if logo_pdf.exists():
            copy_asset(logo_pdf, output_dir, artifact_type="logo-pdf")
        else:
            _try_convert_svg_to_pdf(logo_svg, output_dir / "lyrebird-logo.pdf")

        tex4ht_cfg = _template_dir() / TEX4HT_CFG_NAME
        if tex4ht_cfg.exists():
            tex4ht_artifact = copy_asset(tex4ht_cfg, output_dir, artifact_type="tex4ht-config")
            artifacts.append(tex4ht_artifact)

        filename_map: dict[str, list[str]] = {}
        for document in documents:
            filename = _filename_for_document(document)
            filename_map.setdefault(filename, []).append(document.document_id)

        collisions = {name: ids for name, ids in filename_map.items() if len(ids) > 1}
        if collisions:
            lines = []
            for name, ids in sorted(collisions.items()):
                joined = ", ".join(sorted(ids))
                lines.append(f"{name}: {joined}")
            message = (
                "Multiple document views map to the same LaTeX filename.\n"
                "Please rename the affected view(s) in the SysML model so that each "
                "document has a unique name.\n"
                + "\n".join(lines)
            )
            raise ValidationError(message)

        for document in sorted(documents, key=lambda item: item.document_id):
            filename = _filename_for_document(document)
            output_path = output_dir / filename
            output_path.write_text(_build_tex(document, options.version), encoding="utf-8")
            artifacts.append(
                GeneratedArtifact(
                    path=output_path,
                    artifact_type="tex",
                    document_id=document.document_id,
                )
            )
        return artifacts


@register_target
def _make_latex_generator() -> GeneratorTarget:
    """Factory used to register the LaTeX target in the default registry."""
    return LatexGenerator()
