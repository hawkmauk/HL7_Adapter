# Generators Framework

This package provides a model-driven generation framework that traverses SysML model views and emits target artifacts in a consistent way.

## Current target

- `latex`: generates `.tex` files from `DOC_CIM_*` views in `model/CIM_Views.sysml`.

## Architecture

Generation pipeline:

1. Parse model files (`model/*.sysml`) into a `ModelIndex`.
2. Extract document views (`DOC_CIM_*`) and coverage entries (`CM_*`) into `DocumentIR`.
3. Validate quality gates:
   - stable ID uniqueness
   - required document presence
   - reference resolution for `VP_*`, `VPT_*`, `CM_*`
   - missing purpose/doc text
4. Route to target generator and emit artifacts.

Core modules:

- `base.py`: target interface and generation options.
- `registry.py`: target registration and lookup.
- `parser.py`: lightweight SysML subset parser.
- `extractor.py`: document extraction to IR.
- `validation.py`: quality gates.
- `engine.py`: orchestration (parse -> extract -> validate -> generate).
- `latex.py`: LaTeX target implementation.
- `__main__.py`: CLI entrypoint.

## Usage

From repository root:

```bash
python3 -m generators --target latex --model-dir model --out out --version v0.1.0
```

Outputs:

- `out/cim-<doc-id>-<version>.tex` for each `DOC_CIM_*` view
- `out/coverage-report.json`

## Output naming convention

For `DOC_CIM_<X>`:

- filename: `cim-<x-lower>-<version>.tex`
- examples:
  - `DOC_CIM_SNRS` -> `cim-snrs-v0.1.0.tex`
  - `DOC_CIM_ConOps` -> `cim-conops-v0.1.0.tex`

## Supported render mappings

- `render asElementTable` -> LaTeX `tabular`
- `render asTreeDiagram` -> hierarchical `itemize` fallback
- `render asTextualNotation` -> `verbatim` block

## Adding a new target (future code generation)

1. Create a new module under `generators/` (for example, `python_code.py`).
2. Implement `GeneratorTarget`:
   - set `name`
   - set `supported_renders`
   - implement `generate(documents, options) -> list[GeneratedArtifact]`
3. Register it in `_build_registry()` in `generators/__main__.py`.
4. Reuse `DocumentIR` extraction and keep target-specific logic isolated in the new target module.

This keeps parser and extraction logic shared across documentation and source-code generators.
