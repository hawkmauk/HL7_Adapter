## HL7 Adapter – Model-Driven Architecture Workspace

[![Release docs](https://github.com/hawkmauk/HL7_Adapter/actions/workflows/release-docs.yml/badge.svg)](https://github.com/hawkmauk/HL7_Adapter/actions/workflows/release-docs.yml)
[![Build docs](https://github.com/hawkmauk/HL7_Adapter/actions/workflows/build-docs.yml/badge.svg)](https://github.com/hawkmauk/HL7_Adapter/actions/workflows/build-docs.yml)

This repository hosts an **HL7-to-HTTP adapter** developed using a **Model‑Driven Architecture (MDA)** approach. Instead of starting from code, we start from **SysML v2 models** and use those models to generate **documentation artifacts** (and later, code) across abstraction levels:

- **CIM (Computation‑Independent Model)**: business/domain view – stakeholders, mission, operational context, scenarios, assumptions.
- **PIM (Platform‑Independent Model)**: logical solution view – logical architecture, interfaces, behavior, requirements, allocations.
- **MDA Library**: reusable, project‑agnostic patterns for structure, viewpoints, lifecycles, and document templates shared across projects.

The aim is to make the **digital thread** explicit: requirements, design, lifecycle gates, and generated docs are all traceable to model elements.

### Repository structure (high level)

- `model/`
  - `CIM.sysml`: project‑specific CIM for the HL7 Adapter.
  - `PIM.sysml`: project‑specific PIM (logical architecture, interfaces, behavior, requirements, allocations).
  - `model/CIM/views.sysml`: project CIM viewports, concern mappings, and `DOC_CIM_*` document bindings onto the MDA CIM library.
  - `model/PIM/views.sysml`: project PIM viewports and `DOC_PIM_*` document bindings onto the MDA PIM library.
  - `MDA_Library/`: reusable MDA assets:
    - `structure.sysml`, `view.sysml`, `viewpoint.sysml`, `lifecycle.sysml` – cross‑cutting MDA structure, abstract viewpoints, render profiles, and lifecycle concepts.
    - `CIM/`: CIM‑specific structure, viewpoints, and document templates (SNRS, ConOps, EICD, RSCM, SCHA, Gateway Signoff).
    - `PIM/`: PIM‑specific structure, viewpoints, and document templates (Logical Architecture, Interface Design, Behavior Design, Allocation, Verification, PIM Gateway Signoff).
- `ci/generators/`: Python framework that parses SysML and generates LaTeX/HTML documentation based on the view library.
- `docs/`: narrative documentation, build logs, design notes, and [CI/CD and generated documentation](docs/CI_CD.md).
- `scripts/`: helper scripts for building and running generated artifacts.

### Building

The script **`scripts/build.sh`** runs the code generators and then builds the resulting artifacts. It can be run from anywhere; it switches to the project root automatically.

**Usage:**

```bash
./scripts/build.sh <target>
```

**Targets:**

| Target       | What it does |
|-------------|----------------|
| `latex`     | Runs the LaTeX generator (`model/` → `out/latex/`), then builds PDFs and HTML with `pdflatex` and `make4ht`. Outputs go to `out/pdf/` and `out/html/`. Build intermediates (`.aux`, `.4ct`, etc.) are removed. |
| `typescript`| Runs the TypeScript generator (`model/` → `out/typescript/`), then runs `npm install`, `npm run build`, `npm run test`, and `npm run start` in the generated output directory. |

**Prerequisites:**

- **All targets:** Python 3 and the project’s generator dependencies (see `ci/generators/`).
- **`latex`:** `pdflatex` and `make4ht` (e.g. TeX Live and tex4ht).
- **`typescript`:** Node.js and npm (for install, build, test, and start in `out/typescript/`).

**Examples:**

```bash
./scripts/build.sh latex       # generate docs and build PDFs/HTML
./scripts/build.sh typescript  # generate TypeScript app, install, build, test, and start
```

### Documentation

- **Generated docs (HTML and PDF)** are published on **GitHub Pages**: [https://hawkmauk.github.io/HL7_Adapter/](https://hawkmauk.github.io/HL7_Adapter/).
- For details on generated artifacts, the build pipeline, and releases, see [CI/CD and generated documentation](docs/CI_CD.md).

At a high level, this repo is a **working example of MDA applied to an HL7 adapter**: CIM and PIM models, a reusable MDA library, and a doc/CI pipeline that turns those models into human‑readable artifacts for stakeholders and lifecycle governance.

