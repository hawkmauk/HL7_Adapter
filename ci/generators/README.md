# Generators Framework

This package provides a model-driven generation framework that traverses SysML model views and emits target artifacts in a consistent way.

## Current targets

- **`latex`**: generates `.tex` files from document views in `model/CIM/views.sysml`, `model/PIM/views.sysml`, and `model/PSM/views.sysml` (e.g. `DOC_CIM_*`, `DOC_PIM_*`, `DOC_PSM_*`).
- **`typescript`**: generates a Node.js/TypeScript application skeleton from PSM component state machines (one module per component, adapter orchestrator, `package.json`, `tsconfig.json`). See **docs/Code_Generation.md** for the code-generation architecture and usage.

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
- `parsing/`: SysML subset parser (`driver.py` entry point, `model.py`, `regex.py`, `elements.py`, `nested.py`).
- `ir/`: document IR (`document.py`) and graph IR (`graph.py`: `GraphNode`, `GraphEdge`, `ModelGraph`).
- `extraction/`: document extraction to `DocumentIR` (`extractor.py`).
- `graph/`: model graph builder (`builder.py`: `build_model_graph`).
- `validation.py`: quality gates.
- `engine.py`: orchestration (parse → extract → validate → build graph → generate).
- `targets/latex/`: LaTeX target implementation.
- `targets/typescript/`: TypeScript code-generation target.
- `__main__.py`: CLI entrypoint.

Targets register themselves with the default registry via `@register_target` in
`registry.py`. The CLI imports built-in targets (`targets.latex`, `targets.typescript`)
for side-effect registration and then calls `build_default_registry()`.

## Usage

From repository root:

```bash
python3 -m ci.generators --target latex --model-dir model --out out --version v0.1.0
```

Outputs:

- `out/<document-id>.tex` for each document view (CIM/PIM/PSM)
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

- filename: `<document-id>.tex`
- examples:
  - `DOC_CIM_SNRS` -> `DOC_CIM_SNRS-v0.1.0.tex`
  - `DOC_PIM_LogicalArchitecture` -> `DOC_PIM_LogicalArchitecture-v0.1.0.tex`

## Supported render mappings

- `render asElementTable` -> LaTeX `tabular`
- `render asTreeDiagram` -> hierarchical `itemize` fallback
- `render asTextualNotation` -> `verbatim` block

## Adding a new target

For **code generation** (e.g. TypeScript, or a future Python skeleton), see **docs/Code_Generation.md** for the graph-based pipeline and how to add a target that consumes `ModelGraph`.

Summary:

1. Create a subpackage under `ci/generators/targets/` (e.g. `targets/python/`) with an `__init__.py` that defines your `GeneratorTarget` subclass.
2. Implement `GeneratorTarget`:
   - set `name` and `supported_renders`
   - implement `generate(graph: ModelGraph, options: GenerationOptions) -> list[GeneratedArtifact]`
3. Register with `@register_target` and a factory that returns the target instance.
4. Import the target package from `__main__.py` inside `_build_registry()` so it registers when the CLI runs.

The LaTeX target still uses the document-centric IR (via `options.extra["_documents"]`); code-generation targets use the `ModelGraph` directly. Both share the same parse → extract → validate → build graph pipeline.

## Templates and assets

Templates and static assets for targets live under:

- `ci/generators/templates/<target-name>/...`

Use helpers in `ci/generators/templates.py`:

- `get_template_dir(target_name)` — locate the base template directory.
- `select_first_existing(candidates)` — pick the first available template.
- `copy_asset(src, dest_dir, artifact_type=...)` — copy an asset and get a `GeneratedArtifact` back.
