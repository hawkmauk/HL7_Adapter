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

### Running the TypeScript adapter with config.json

The generated adapter reads configuration from a **`config.json`** file in the **current working directory** when you run it. The build script places a default `config.json` in `out/typescript/` and runs `npm run start` from there after tests.

**To run the adapter yourself:**

1. Build the TypeScript target (see above), then:
   ```bash
   cd out/typescript
   npm run start
   ```
   This runs `node dist/main.js`, which loads `config.json` from the current directory.

2. **Config file location:** The entry point resolves the path as `join(process.cwd(), 'config.json')`. So either run from `out/typescript/` (where the generator puts `config.json`), or place/copy a `config.json` in whatever directory you use as the working directory.

3. **Config shape:** `config.json` must be a JSON object with one key per component, each holding that component’s config object. Example (with RestApi listening on port 3000):

   ```json
   {
     "errorHandler": {
       "logLevel": "",
       "metricsPrefix": "",
       "deadLetterPath": "",
       "classificationTaxonomy": ""
     },
     "httpForwarder": {
       "baseUrl": "",
       "requestTimeoutMs": 0,
       "maxRetries": 0,
       "retryBackoffMs": 0,
       "tlsMinVersion": "",
       "tlsRejectUnauthorized": 0
     },
     "mllpReceiver": {
       "bindHost": "",
       "bindPort": 0,
       "maxPayloadSize": 0,
       "connectionIdleTimeoutMs": 0
     },
     "operationalStore": {
       "dialect": "sqlite",
       "path": "",
       "connectionString": ""
     },
     "parser": {
       "encodingFallback": "",
       "strictValidation": 0,
       "segmentWhitelist": ""
     },
     "restApi": {
       "listenPort": 3000
     },
     "transformer": {
       "mappingConfigPath": "",
       "jsonPrettyPrint": 0,
       "schemaValidateOutput": 0
     }
   }
   ```

   Set **`restApi.listenPort`** (e.g. `3000`) for the health and metrics HTTP server. If omitted or `0`, the server may bind to an ephemeral port. Fill in other fields (e.g. `mllpReceiver.bindPort`, `httpForwarder.baseUrl`) for your environment.

4. **Health and metrics:** Once the adapter is running, GET **`/health`** and **`/metrics`** on the configured host/port (e.g. `http://localhost:3000/health`). See **`docs/RestApi_Dashboard_Contract.md`** for the response shapes.

### Operational store and database

The adapter includes an **operational data store** for message audit (lifecycle, delivery attempts, errors). Technology choice is documented in **`model/PSM/technology_selection.sysml`** (trade study: SQLite for local dev, PostgreSQL for production).

- **SQLite (local):** Set `operationalStore.dialect` to `"sqlite"` and optionally `operationalStore.path` (e.g. `"./data/store.db"`). If `path` is omitted or empty, the store uses an in-memory database. Tables are created automatically on first run.
- **Initialize schema only (SQLite):** The TypeScript generator copies `scripts/init-db.ts` from `ci/generators/templates/typescript/` into the TypeScript output (e.g. `out/typescript/scripts/init-db.ts`). From that output directory, run:
  ```bash
  cd out/typescript && npx ts-node scripts/init-db.ts [path]
  ```
  Default path is `./data/store.db` or `STORE_PATH` env. For PostgreSQL, use your migration tool or run the adapter once (schema creation is dialect-aware in the component).

### Documentation

- **Generated docs (HTML and PDF)** are published on **GitHub Pages**: [https://hawkmauk.github.io/HL7_Adapter/](https://hawkmauk.github.io/HL7_Adapter/).
- For details on generated artifacts, the build pipeline, and releases, see [CI/CD and generated documentation](docs/CI_CD.md).

At a high level, this repo is a **working example of MDA applied to an HL7 adapter**: CIM and PIM models, a reusable MDA library, and a doc/CI pipeline that turns those models into human‑readable artifacts for stakeholders and lifecycle governance.

