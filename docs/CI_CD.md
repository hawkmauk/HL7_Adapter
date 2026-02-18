# CI/CD and generated documentation

This page describes how documentation is built and published in this repository: generated artifacts, the GitHub Actions pipeline, GitHub Pages, and releases.

## Generated artifacts

From the models and view definitions, the generator produces **document‑style outputs** (LaTeX ➝ PDF, plus HTML via tex4ht) for both CIM and PIM:

### CIM documents (examples)

- **SNRS** – Stakeholder Needs and Requirements (SoR‑like view at the concept level).
- **ConOps** – Concept of Operations (domain, context, mission, operations, assumptions).
- **Operational Scenarios** – nominal and degraded scenario narratives.
- **EICD** – External Interface Context (actors, boundaries, conceptual exchanges).
- **RSCM / SCHA** – Compliance matrix and safety case/hazard summaries.
- **CIM Gateway Signoff** – evidence and signoff for the CIM lifecycle gate.

### PIM documents (examples)

- **Logical Architecture Specification** – logical components, connectors, responsibilities, design rationale.
- **Interface Design Description** – logical interfaces, message contracts, error handling, versioning.
- **Behavior and Use Case Design** – PIM‑level flows and behavior refinements.
- **Requirements & Allocation Spec** – PIM requirements and their allocations to logical elements.
- **Verification Readiness & Test Intent** – verification objectives and test strategy at PIM.
- **PIM Gateway Readiness** – design‑review/gateway pack for entering PSM.

### How documents are defined

Each document is defined as a **SysML view** that:

- **Satisfies** one or more MDA viewpoints (e.g. Stakeholder Needs, ConOps, Logical Architecture, Gateway Readiness).
- **Exposes** relevant packages, elements, and viewports (CIM/PIM structure, requirements, lifecycle artifacts).
- Is rendered via standard profiles (tables, trees, textual snapshots).

## CI and document generation

The project uses **GitHub Actions** to keep documentation in sync with the models.

### Build and deploy (push to `main`)

On each push to `main`, the [Build docs](../.github/workflows/build-docs.yml) workflow:

1. Checks out the repo and installs LaTeX + tex4ht.
2. Runs the Python generator (`python -m generators`) against `model/` to build LaTeX sources for all `DOC_*` views.
3. Runs `pdflatex` and `make4ht` to produce **PDF** and **HTML** artifacts for each generated `.tex` file.
4. Uploads the outputs as a versioned `generated-docs` artifact (with `pdf/` and `html/` subfolders) from the Actions run.
5. Deploys the generated HTML and PDFs to **GitHub Pages**: [https://hawkmauk.github.io/HL7_Adapter/](https://hawkmauk.github.io/HL7_Adapter/).

This gives you:

- A **repeatable document build** driven entirely by the SysML models and MDA library.
- Published docs at a stable URL (GitHub Pages) plus downloadable PDFs under `/pdf/`.
- A single CI entry point where future generators (e.g. PIM/PSM‑based code, configuration, or tests) can be added alongside the doc pipeline.

### Releases (version tags)

When you push a version tag (e.g. `v0.1.0`), the [Release docs](../.github/workflows/release-docs.yml) workflow builds the docs at that version and creates a **GitHub Release** with all PDFs attached (and a zip of all PDFs). See the [Releases](https://github.com/hawkmauk/HL7_Adapter/releases) page for versioned downloads.
