"""Asset and template path helpers for the LaTeX target."""
from __future__ import annotations

import subprocess
from pathlib import Path

from ...templates import get_template_dir, select_first_existing

STYLE_FILE_NAME = "lyrebird-doc-style.sty"
TEX4HT_CFG_NAME = "lyrebird-html.cfg"


def _template_dir() -> Path:
    """Return the template directory for the LaTeX target."""
    return get_template_dir("latex")


def _style_template_path() -> Path:
    """Locate the LaTeX style template, preferring the templates/ tree."""
    generator_dir = Path(__file__).resolve().parent.parent.parent
    repo_root = generator_dir.parent
    candidates = [
        _template_dir() / STYLE_FILE_NAME,
        repo_root / "lib" / STYLE_FILE_NAME,
        generator_dir / "lib" / STYLE_FILE_NAME,
    ]
    return select_first_existing(candidates)


def _try_convert_svg_to_pdf(svg_path: Path, pdf_path: Path) -> None:
    """Convert SVG to PDF for pdflatex if rsvg-convert or similar is available."""
    if not svg_path.exists():
        return
    for cmd in (["rsvg-convert", "-f", "pdf", "-o", str(pdf_path), str(svg_path)],):
        try:
            subprocess.run(cmd, check=True, capture_output=True, timeout=10)
            if pdf_path.exists():
                return
        except (FileNotFoundError, subprocess.CalledProcessError, subprocess.TimeoutExpired):
            continue
