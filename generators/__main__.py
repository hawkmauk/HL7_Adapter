from __future__ import annotations

import argparse
import json
from pathlib import Path
import sys

from .engine import run_generation
from .errors import GenerationError
from .registry import TargetRegistry, build_default_registry


def _build_registry() -> TargetRegistry:
    """
    Build the default registry and ensure built-in targets are imported.

    Target modules register themselves via registry.register_target() at
    import time; we import them here so they are available on the CLI.
    """
    # Import built-in targets for side-effect registration.
    from . import latex as _latex  # noqa: F401

    return build_default_registry()


def _parse_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        prog="python -m generators",
        description="Generate artifacts from SysML model views.",
    )
    parser.add_argument("--target", required=False, help="Generation target (e.g. latex).")
    parser.add_argument("--model-dir", help="Directory containing .sysml model files.")
    parser.add_argument("--out", help="Output directory for generated artifacts.")
    parser.add_argument("--version", default="v0.1.0", help="Artifact version suffix.")
    parser.add_argument(
        "--coverage-report",
        default="coverage-report.json",
        help="Coverage report file name (written under --out).",
    )
    parser.add_argument(
        "--list-targets",
        action="store_true",
        help="List available generation targets and exit.",
    )
    parser.add_argument(
        "--config",
        help="Optional JSON config file providing target-specific options.",
    )
    parser.add_argument(
        "--option",
        action="append",
        default=[],
        metavar="KEY=VALUE",
        help="Override or add a single target option (may be repeated).",
    )
    return parser.parse_args(argv)


def _parse_extra_options(config_path: str | None, options: list[str]) -> dict:
    extra: dict[str, object] = {}

    if config_path:
        config_file = Path(config_path)
        payload = json.loads(config_file.read_text(encoding="utf-8"))
        if isinstance(payload, dict):
            extra.update(payload)
        else:
            raise ValueError(f"Config file {config_file} must contain a JSON object.")

    for item in options or []:
        if "=" not in item:
            raise ValueError(f"Invalid --option value '{item}'. Expected KEY=VALUE.")
        key, raw_value = item.split("=", 1)
        key = key.strip()
        raw_value = raw_value.strip()
        if not key:
            raise ValueError(f"Invalid --option value '{item}': empty key.")

        # Best-effort type coercion: bool -> int -> float -> str.
        lowered = raw_value.lower()
        if lowered in {"true", "false"}:
            value: object = lowered == "true"
        else:
            try:
                value = int(raw_value)
            except ValueError:
                try:
                    value = float(raw_value)
                except ValueError:
                    value = raw_value
        extra[key] = value

    return extra


def main(argv: list[str] | None = None) -> int:
    args = _parse_args(argv if argv is not None else sys.argv[1:])
    registry = _build_registry()

    if args.list_targets:
        names = registry.names()
        if names:
            print("Available targets:")
            for name in names:
                print(f"  - {name}")
        else:
            print("No targets are currently registered.")
        return 0

    if not args.target:
        raise SystemExit("Error: --target is required unless --list-targets is used.")
    if not args.model_dir or not args.out:
        raise SystemExit("Error: --model-dir and --out are required for generation.")

    extra = _parse_extra_options(args.config, args.option)

    try:
        result = run_generation(
            registry=registry,
            target_name=args.target,
            model_dir=Path(args.model_dir),
            output_dir=Path(args.out),
            version=args.version,
            extra=extra,
        )
    except GenerationError as exc:
        print(f"Generation failed: {exc}", file=sys.stderr)
        return 1

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
