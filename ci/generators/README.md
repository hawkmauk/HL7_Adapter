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

Targets register themselves with the default registry via helpers in
`registry.py`. The CLI imports built-in targets (currently `latex`) for
side-effect registration and then calls `build_default_registry()`.

## Usage

From repository root:

```bash
python3 -m ci.generators --target latex --model-dir model --out out --version v0.1.0
```

Outputs:

- `out/<document-id>-<version>.tex` for each document view (CIM/PIM/PSM)
- `out/lyrebird-doc-style.sty`, `out/lyrebird-html.cfg`, and logo assets
- `out/coverage-report.json`

**Building PDFs:** Run the generator first so `out/` contains the `.sty` and logo. Then run `pdflatex` from inside `out/`, e.g.:

```bash
python3 -m ci.generators --target latex --model-dir model --out out --version v0.1.0
cd out && pdflatex DOC_CIM_EICD-v0.1.0.tex
```

If you see `File 'lyrebird-doc-style.sty' not found`, run the generator again from the repo root with `--out out`, then build from `out/`.

**Building HTML (tex4ht):** With [tex4ht](https://www.tug.org/tex4ht/) / [make4ht](https://www.kodymirus.cz/make4ht/) installed, generate as above, then from `out/` run:

```bash
cd out && make4ht -c lyrebird-html.cfg DOC_CIM_EICD-v0.1.0.tex
```

For HTML5 output:

```bash
make4ht -c lyrebird-html.cfg DOC_CIM_EICD-v0.1.0.tex "html5"
```

This produces `DOC_CIM_EICD-v0.1.0.html` (and assets) using the Lyrebird styling defined in `lyrebird-html.cfg`.

### Target configuration

Targets can declare additional, target-specific options. The CLI supports:

- `--config path/to/config.json` — JSON object merged into `GenerationOptions.extra`.
- `--option key=value` — may be repeated; best-effort coercion to `bool`/`int`/`float` is applied.

Inside a target, read `options.extra` and map it into a small dataclass if you
need stronger typing.

## CI

On every push to `main` (including merges from pull requests), the [Build docs](.github/workflows/build-docs.yml) workflow runs the generator, builds PDF and HTML for each generated `.tex` file, and uploads the results as a single artifact named **generated-docs**. Download it from the run’s **Summary** in the Actions tab (Artifacts section). The artifact contains `pdf/` (all PDFs) and `html/` (all HTML plus CSS, SVG, and any make4ht assets). You can add a second artifact (e.g. generated code) or a job that builds and pushes a Docker image to GHCR in the same workflow so docs and code/images are produced together.

## Output naming convention

Filenames use the document view's stable ID plus the version suffix (no CIM/PIM/PSM prefix):

- filename: `<document-id>-<version>.tex`
- examples:
  - `DOC_CIM_SNRS` -> `DOC_CIM_SNRS-v0.1.0.tex`
  - `DOC_PIM_LogicalArchitecture` -> `DOC_PIM_LogicalArchitecture-v0.1.0.tex`

## Supported render mappings

- `render asElementTable` -> LaTeX `tabular`
- `render asTreeDiagram` -> hierarchical `itemize` fallback
- `render asTextualNotation` -> `verbatim` block

## Adding a new target (future code generation)

1. Create a new module under `ci/generators/` (for example, `python_code.py`).
2. Implement `GeneratorTarget`:
   - set `name`
   - set `supported_renders`
   - implement `generate(documents, options) -> list[GeneratedArtifact]`
3. Register it with the default registry using the helper in `registry.py`, e.g.:

   ```python
   from ci.generators.registry import register_target

   @register_target
   def _make_python_generator() -> GeneratorTarget:
       return PythonGenerator()
   ```

4. Import the module from the CLI entrypoint (or another always-imported module)
   so it is available when `build_default_registry()` is called.
5. Reuse `DocumentIR` extraction and keep target-specific logic isolated in the new target module.

This keeps parser and extraction logic shared across documentation and source-code generators.

## Templates and assets

Templates and static assets for targets live under:

- `ci/generators/templates/<target-name>/...`

Use helpers in `ci/generators/templates.py`:

- `get_template_dir(target_name)` — locate the base template directory.
- `select_first_existing(candidates)` — pick the first available template.
- `copy_asset(src, dest_dir, artifact_type=...)` — copy an asset and get a `GeneratedArtifact` back.
