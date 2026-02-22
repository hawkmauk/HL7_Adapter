## HL7 Adapter – Model-Driven Architecture Workspace

[![Release docs](https://github.com/hawkmauk/HL7_Adapter/actions/workflows/release-docs.yml/badge.svg)](https://github.com/hawkmauk/HL7_Adapter/actions/workflows/release-docs.yml)
[![Build docs](https://github.com/hawkmauk/HL7_Adapter/actions/workflows/build-docs.yml/badge.svg)](https://github.com/hawkmauk/HL7_Adapter/actions/workflows/build-docs.yml)

### A proof of concept for the Digital Thread

This project is a **proof of concept** for a **Digital Thread**: all project information is captured in a **model**, and the model is our **single source of truth**. We do not maintain separate docs, code, and specs that drift apart. We define **views** into the model, and we generate everything from it.

The **PDF documents** we produce (ConOps, requirements, interface design, gateway signoff, and so on) are **snapshots from the model at a point in time**. So is the **executable program** we run: the TypeScript adapter is a view of the model at a point in time. Documentation and software are both **generated from the model**. That is the core idea: one model, many views, full traceability.

### How we develop

We add **domain data** to the model first, in the **CIM** (Computation‑Independent Model): stakeholders, mission, operational context, scenarios, and assumptions. We then capture the **behaviours** the system should exhibit and the **requirements** it must satisfy. These are **explicitly linked** to the domain data—requirements to use cases, use cases to domain concepts—creating the thread from problem space to solution space.

We run **case studies** to choose technology and design decisions (e.g. SQLite vs PostgreSQL, Node.js/TypeScript for the adapter), and we **record those decisions in the model**. Only after that do we build the **structure of our system** in the **PSM** (Platform‑Specific Model): components, interfaces, state machines. At that stage we add **snippets of code** into the model for our target language. The **generator** builds the software from the model; the snippets are **inserted to fill out function bodies**. We do not hand‑write the architecture in code—we express it in the model and generate the rest.

We can add snippets for **different languages** and extend the generator to produce **Python, C, Rust**, or any other target. The **system is unchanged** in the model; we simply **express the model in different ways**. That is the real power of **model‑based systems engineering (MBSE)**: separating **architecture** (what the system is and how it behaves) from **implementation** (how it is expressed in a given language or platform)—in the same way that **HTML** (structure) is separated from **CSS** (presentation).

### MDA levels in this repo

The model is organised using **Model‑Driven Architecture (MDA)** abstraction levels:

- **CIM (Computation‑Independent Model)**: business and domain—stakeholders, mission, operational context, scenarios, assumptions.
- **PIM (Platform‑Independent Model)**: logical solution—logical architecture, interfaces, behaviour, requirements, allocations.
- **PSM (Platform‑Specific Model)**: technology‑bound design and code snippets—components, bindings, and the executable view.
- **MDA Library**: reusable, project‑agnostic patterns for structure, viewpoints, lifecycles, and document templates shared across projects.

Requirements, design, lifecycle gates, generated docs, and generated code are all **traceable to model elements**.

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

For editing SysML (`.sysml`) files we use the **SysIDE** editor plugin with **VS Code** for SysML syntax highlighting.

### How to run locally

The adapter is **generated from the model** (TypeScript/Node.js). To run it locally:

1. **Prerequisites:** Python 3 (for the generator), Node.js and npm, and optionally TeX Live + tex4ht if you want to build PDF docs.
2. **Generate and run the adapter:**
   ```bash
   ./scripts/build.sh typescript
   ```
   This generates the TypeScript app from the model into `out/typescript/`, runs `npm install`, `npm run build`, `npm run test`, and `npm run start`. The adapter listens for HL7 on MLLP (default port 2575) and posts transformed JSON to the URL in `config.json` (see [Running the TypeScript adapter](#running-the-typescript-adapter-with-configjson) below).
3. **Optional — full demo:** Start the [demo HTTPS endpoint](tests/demo-https-endpoint/README.md) (e.g. `https://localhost:8080/api/v1/messages`), set `httpForwarder.baseUrl` and `tlsRejectUnauthorized: 0` in `out/typescript/config.json`, then run the [MLLP Emitter](tests/mllpemitter/README.md) to send HL7 messages to the adapter. JSON will be POSTed to the demo endpoint.

We do not use Docker for the core adapter; the build script uses Node.js and npm. A **Docker image** of the generated demo is built by CI and pushed to GHCR (see [CI and GitHub Pages](#ci-and-github-pages) below).

### How it works

1. **HL7 publisher** — A sender (e.g. the [MLLP Emitter](tests/mllpemitter/README.md)) publishes HL7 messages over TCP using MLLP framing (start 0x0B, end 0x1C 0x0D).
2. **Receiver** — The adapter’s MLLP receiver listens on a configurable port (e.g. 2575), accepts MLLP-framed messages, and returns ACK/NAK per HL7.
3. **Parse and transform** — The adapter parses the HL7 message (MSH, PID, etc.), maps key fields (patient ID, name, DOB, message type), and produces a structured JSON payload.
4. **POST to REST API** — The adapter sends that JSON via POST to a configurable HTTPS endpoint (e.g. `https://localhost:8080/api/v1/messages`).
5. **Error handling** — Parse failures, validation errors, and delivery failures are classified, logged, and reflected in metrics and health; the operational store records message lifecycle and errors for audit.

All of this (structure, behaviour, requirements) is defined in the **model**; the executable is **generated** from the model, so the architecture and the implementation stay in sync.

### CI and GitHub Pages

We use **CI** to keep artifacts in sync with the model:

- **On push to `main`** (e.g. when a pull request is merged), the [Build docs](.github/workflows/build-docs.yml) workflow:
  - Generates **project documents** (ConOps, requirements, interface design, gateway signoff, etc.) from the model and builds **PDF** and **HTML**.
  - **Deploys them to GitHub Pages** so stakeholders always have the latest docs: **[https://hawkmauk.github.io/HL7_Adapter/](https://hawkmauk.github.io/HL7_Adapter/)**.
  - **Builds the demo from the model**: generates the TypeScript adapter from the SysML model, runs tests, and builds a **Docker image** of the adapter (pushed to GitHub Container Registry). So both the project documents and the runnable demo are produced **automatically from the model** on every merge to `main`.
  - **Generated source code** is uploaded as a **GitHub Actions artifact** (`generated-adapter-source`): a tarball of the TypeScript adapter (without `node_modules`). You can download it from the [Actions](https://github.com/hawkmauk/HL7_Adapter/actions) tab for the latest run of “Build docs”.

No hand-written docs or code are deployed; the **model** is the source of truth, and CI turns it into published docs and a containerised demo.

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
       "baseUrl": "https://localhost:8080/api/v1/messages",
       "requestTimeoutMs": 5000,
       "maxRetries": 3,
       "retryBackoffMs": 1000,
       "tlsMinVersion": "TLSv1.2",
       "tlsRejectUnauthorized": 1
     },
     "mllpReceiver": {
       "bindHost": "127.0.0.1",
       "bindPort": 2575,
       "maxPayloadSize": 1048576,
       "connectionIdleTimeoutMs": 30000
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

   Set **`restApi.listenPort`** (e.g. `3000`) for the health and metrics HTTP server. If omitted or `0`, the server may bind to an ephemeral port. **`httpForwarder.baseUrl`** must be set to the downstream URL the adapter will POST JSON to (e.g. `https://localhost:8080/api/v1/messages` for the [demo HTTPS endpoint](tests/demo-https-endpoint/README.md)); if empty, the adapter will not post and will log "Failed to parse URL". Fill in other fields (e.g. `mllpReceiver.bindPort`) for your environment. **`httpForwarder.tlsRejectUnauthorized`** defaults to `1` (verify server certificates). Set to `0` only for demo/local use with self-signed certs; must not be used in production.

4. **Health and metrics:** Once the adapter is running, GET **`/health`** and **`/metrics`** on the configured host/port (e.g. `http://localhost:3000/health`). See **`docs/RestApi_Dashboard_Contract.md`** for the response shapes.

### Operational store and database

The adapter includes an **operational data store** for message audit (lifecycle, delivery attempts, errors). Technology choice is documented in **`model/PSM/technology_selection.sysml`** (trade study: SQLite for local dev, PostgreSQL for production).

- **SQLite (local):** Set `operationalStore.dialect` to `"sqlite"` and optionally `operationalStore.path` (e.g. `"./data/store.db"`). If `path` is omitted or empty, the store uses an in-memory database. Tables are created automatically on first run.
- **Initialize schema only (SQLite):** The TypeScript generator copies `scripts/init-db.ts` from `ci/generators/templates/typescript/` into the TypeScript output (e.g. `out/typescript/scripts/init-db.ts`). From that output directory, run:
  ```bash
  cd out/typescript && npx ts-node scripts/init-db.ts [path]
  ```
  Default path is `./data/store.db` or `STORE_PATH` env. For PostgreSQL, use your migration tool or run the adapter once (schema creation is dialect-aware in the component).

### Demo and testing tools

- **MLLP Emitter** (`tests/mllpemitter/`) sends HL7 messages over MLLP to the adapter on a configurable interval, with randomised content and a small fraction of invalid messages to exercise error handling. See [tests/mllpemitter/README.md](tests/mllpemitter/README.md).
- **Demo HTTPS endpoint** (`tests/demo-https-endpoint/`) is a simple HTTPS server that receives the JSON payloads the adapter’s HTTPForwarder posts. Use it with a self-signed cert to run the full path: HL7 (MLLP) → adapter → transform → HTTPS POST. See [tests/demo-https-endpoint/README.md](tests/demo-https-endpoint/README.md) for cert generation, how to start the server, and the full demo flow (endpoint, adapter config with `tlsRejectUnauthorized: 0` for demo, adapter, MLLP emitter).

### Trade-offs

We chose **maintainability and flexibility over speed**. A lot of effort went into demonstrating a **repeatable delivery model** (model as single source of truth, generated docs, generated code, traceability) rather than delivering a one-off integration. As a result, some important production-oriented features are **not yet implemented**:

- **REST API authentication** — The health and metrics endpoints are unauthenticated. For production, they should be protected (e.g. API keys, mTLS, or integration with an IdP).
- **Encryption of data at rest** — The operational store (SQLite/PostgreSQL) does not currently encrypt persisted data. Sensitive payloads and audit data should be encrypted at rest in a production deployment.
- **GDPR-style capabilities** — Subject access requests (information requests) and right to erasure (“right to be forgotten”) are not implemented. The **requirements are still recorded in the model** (e.g. CIM/PIM requirements for data subject rights and retention); they would show as **not yet satisfied** in SysML analytics or traceability views, and can be implemented in a later phase without changing the architecture.

These gaps are intentional for this proof of concept: the **model** carries the full set of requirements and design, so we can see what is missing and prioritise it when moving toward production.

### Ideas for improving reliability in production

- **Authentication and authorisation** on the RestApi (health, metrics, message/error queries) and optionally on the downstream HTTPS endpoint side.
- **Encryption at rest** for the operational store and any stored message content or PII.
- **Implement GDPR-related behaviour** (subject access, erasure, retention policies) as specified in the model.
- **Stricter TLS and certificate validation** in production (no disabling verification); consider mTLS for adapter-to-downstream and for RestApi.
- **Rate limiting and backpressure** on the MLLP listener and on outbound POST to avoid overwhelming the downstream API.
- **Structured logging and correlation IDs** across the pipeline for debugging and audit.
- **Automated tests** (including integration tests with real MLLP and HTTPS) run in CI on every pull request; the model already drives unit tests via verification cases.

### Example HL7 message and sample API output

**Sample HL7 message (ADT^A01):**

```
MSH|^~\&|SENDING_APP|SENDING_FAC|RECEIVING_APP|RECEIVING_FAC|20260218120000||ADT^A01|MSG_001|P|2.5
EVN|A01|20260218120000
PID|1||PAT_12345^^^HOSP^MR||Doe^Jane^^^Ms||19850315|F|||123 Main St^^Anytown^CA^90210^^M||(555)123-4567|(555)987-6543||S||123456789
```

**Sample JSON payload** (as sent by the adapter via POST to the downstream API, e.g. `https://localhost:8080/api/v1/messages`):

```json
{
  "messageType": "ADT^A01",
  "messageControlId": "MSG_001",
  "patientId": "PAT_12345^^^HOSP^MR",
  "patientName": "Doe^Jane^^^Ms",
  "dateOfBirth": "19850315"
}
```

The operational store and internal flows use a richer **metadata** and **demographics** view (sending/receiving app/facility, given/family name, gender); the current PSM transformer sends this flat JSON to the downstream API. The model defines both the logical shape and the mapping from HL7 segments.

### Documentation

- **Generated docs (HTML and PDF)** are published on **GitHub Pages**: [https://hawkmauk.github.io/HL7_Adapter/](https://hawkmauk.github.io/HL7_Adapter/).
- For details on generated artifacts, the build pipeline, and releases, see [CI/CD and generated documentation](docs/CI_CD.md).

In short: one model, many views—documentation and executable—all generated, all traceable.

