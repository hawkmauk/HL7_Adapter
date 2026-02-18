from __future__ import annotations

from pathlib import Path

from ci.generators.engine import run_generation
from ci.generators.registry import build_default_registry


def _project_root() -> Path:
    return Path(__file__).resolve().parents[1]


def test_latex_generation_smoke(tmp_path: Path) -> None:
    """
    Smoke test: run the LaTeX generator against the real model directory.

    This exercises the full parse -> extract -> validate -> generate pipeline
    and asserts that artifacts are written under the requested output
    directory.
    """
    model_dir = _project_root() / "model"
    output_dir = tmp_path

    # Import built-in targets so they can self-register with the registry.
    from ci.generators import latex as _latex  # noqa: F401

    registry = build_default_registry()
    result = run_generation(
        registry=registry,
        target_name="latex",
        model_dir=model_dir,
        output_dir=output_dir,
        version="v-test",
        extra={},
    )

    assert result.artifacts, "Expected at least one LaTeX artifact to be generated."

    conops_tex: str | None = None
    gateway_tex: str | None = None

    for artifact in result.artifacts:
        assert artifact.path.is_file()
        assert str(artifact.path).startswith(str(output_dir))

        if artifact.document_id == "DOC_CIM_ConOps" and artifact.path.suffix == ".tex":
            conops_tex = artifact.path.read_text(encoding="utf-8")
        if artifact.document_id == "DOC_CIM_GatewaySignoff" and artifact.path.suffix == ".tex":
            gateway_tex = artifact.path.read_text(encoding="utf-8")

    # ConOps document should render narrative sections with headings and content
    assert conops_tex is not None, "Expected a ConOps LaTeX artifact."
    assert "\\subsection{Domain}" in conops_tex
    assert "This section describes the problem domain in which the system-of-interest operates." in conops_tex

    # Gateway signoff document should include the Stakeholder Signoff section and signoff table
    assert gateway_tex is not None, "Expected a Gateway Signoff LaTeX artifact."
    assert "\\subsection{Stakeholder Signoff}" in gateway_tex
    assert "\\begin{tabular}{|l|p{5cm}|l|l|p{5cm}|}" in gateway_tex
    assert "\\textbf{Stakeholder} & \\textbf{Role / Responsibility} & \\textbf{Decision} & \\textbf{Date} & \\textbf{Notes}" in gateway_tex

