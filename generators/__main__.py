from __future__ import annotations

import argparse
import json
from pathlib import Path
import sys

from .engine import run_generation
from .latex import LatexGenerator
from .registry import TargetRegistry


def _build_registry() -> TargetRegistry:
    registry = TargetRegistry()
    registry.register(LatexGenerator())
    return registry


def _parse_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        prog="python -m generators",
        description="Generate artifacts from SysML model views.",
    )
    parser.add_argument("--target", required=True, help="Generation target (e.g. latex).")
    parser.add_argument("--model-dir", required=True, help="Directory containing .sysml model files.")
    parser.add_argument("--out", required=True, help="Output directory for generated artifacts.")
    parser.add_argument("--version", default="v0.1.0", help="Artifact version suffix.")
    parser.add_argument(
        "--coverage-report",
        default="coverage-report.json",
        help="Coverage report file name (written under --out).",
    )
    return parser.parse_args(argv)


def main(argv: list[str] | None = None) -> int:
    args = _parse_args(argv if argv is not None else sys.argv[1:])
    registry = _build_registry()

    result = run_generation(
        registry=registry,
        target_name=args.target,
        model_dir=Path(args.model_dir),
        output_dir=Path(args.out),
        version=args.version,
    )

    report_path = Path(args.out) / args.coverage_report
    report_payload = {
        "documents_generated": [doc.document_id for doc in result.extraction.documents],
        "coverage_entries": [
            {
                "coverage_id": entry.coverage_id,
                "stakeholders": entry.stakeholder_ids,
                "concerns": entry.concern_ids,
                "viewpoints": entry.viewpoint_ids,
                "viewports": entry.viewport_ids,
                "document_codes": entry.document_codes,
            }
            for entry in result.extraction.coverage_entries
        ],
        "artifacts": [str(artifact.path) for artifact in result.artifacts],
    }
    report_path.write_text(json.dumps(report_payload, indent=2), encoding="utf-8")

    print(f"Generated {len(result.artifacts)} artifact(s) to {Path(args.out)}")
    print(f"Wrote coverage report: {report_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
