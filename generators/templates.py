from __future__ import annotations

from pathlib import Path
from typing import Iterable

from .base import GeneratedArtifact


def get_template_dir(target_name: str) -> Path:
    """
    Return the base template directory for a given target.

    By convention, target templates live under:
        generators/templates/<target_name>/
    """
    generator_dir = Path(__file__).resolve().parent
    return generator_dir / "templates" / target_name


def select_first_existing(candidates: Iterable[Path]) -> Path:
    """
    Return the first existing path from a sequence of candidates.

    If none of the candidates exist, the first candidate is returned so callers
    can still surface a useful error message including the preferred path.
    """
    iterator = iter(candidates)
    first: Path | None = None
    for candidate in iterator:
        if first is None:
            first = candidate
        if candidate.exists():
            return candidate
    if first is None:
        raise ValueError("No candidate paths provided.")
    return first


def copy_asset(src: Path, dest_dir: Path, *, artifact_type: str = "asset") -> GeneratedArtifact:
    """
    Copy a template or static asset into the destination directory.

    Returns a GeneratedArtifact pointing at the copied file so callers may
    include it in coverage or reporting.
    """
    if not src.exists():
        raise FileNotFoundError(f"Asset not found: {src}")
    dest_dir.mkdir(parents=True, exist_ok=True)
    dest = dest_dir / src.name
    dest.write_bytes(src.read_bytes())
    return GeneratedArtifact(path=dest, artifact_type=artifact_type)

