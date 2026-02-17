## HL7 Adapter – Model-Driven Architecture Workspace

This repository hosts an **HL7-to-HTTP adapter** developed using a **Model‑Driven Architecture (MDA)** approach. Instead of starting from code, we start from **SysML v2 models** and use those models to generate **documentation artifacts** (and later, code) across abstraction levels:

- **CIM (Computation‑Independent Model)**: business/domain view – stakeholders, mission, operational context, scenarios, assumptions.
- **PIM (Platform‑Independent Model)**: logical solution view – logical architecture, interfaces, behavior, requirements, allocations.
- **MDA Library**: reusable, project‑agnostic patterns for structure, viewpoints, lifecycles, and document templates shared across projects.

The aim is to make the **digital thread** explicit: requirements, design, lifecycle gates, and generated docs are all traceable to model elements.

### Repository structure (high level)

- `model/`
  - `CIM.sysml`: project‑specific CIM for the HL7 Adapter.
  - `PIM.sysml`: project‑specific PIM (logical architecture, interfaces, behavior, requirements, allocations).
  - `CIM_ProjectViews.sysml`: project CIM viewports, concern mappings, and `DOC_CIM_*` document bindings onto the MDA CIM library.
  - `PIM_ProjectViews.sysml`: project PIM viewports and `DOC_PIM_*` document bindings onto the MDA PIM library.
  - `MDA_Library/`: reusable MDA assets:
    - `structure.sysml`, `view.sysml`, `viewpoint.sysml`, `lifecycle.sysml` – cross‑cutting MDA structure, abstract viewpoints, render profiles, and lifecycle concepts.
    - `CIM/`: CIM‑specific structure, viewpoints, and document templates (SNRS, ConOps, EICD, RSCM, SCHA, Gateway Signoff).
    - `PIM/`: PIM‑specific structure, viewpoints, and document templates (Logical Architecture, Interface Design, Behavior Design, Allocation, Verification, PIM Gateway Signoff).
- `generators/`: Python framework that parses SysML and generates LaTeX/HTML documentation based on the view library.
- `docs/`: narrative documentation such as day‑by‑day build logs and design notes.

### Generated artifacts (high level)

From the models and view definitions, the generator produces **document‑style outputs** (LaTeX ➝ PDF, plus HTML via tex4ht) for both CIM and PIM:

- **CIM documents (examples)**:
  - **SNRS** – Stakeholder Needs and Requirements (SoR‑like view at the concept level).
  - **ConOps** – Concept of Operations (domain, context, mission, operations, assumptions).
  - **Operational Scenarios** – nominal and degraded scenario narratives.
  - **EICD** – External Interface Context (actors, boundaries, conceptual exchanges).
  - **RSCM / SCHA** – Compliance matrix and safety case/hazard summaries.
  - **CIM Gateway Signoff** – evidence and signoff for the CIM lifecycle gate.

- **PIM documents (examples)**:
  - **Logical Architecture Specification** – logical components, connectors, responsibilities, design rationale.
  - **Interface Design Description** – logical interfaces, message contracts, error handling, versioning.
  - **Behavior and Use Case Design** – PIM‑level flows and behavior refinements.
  - **Requirements & Allocation Spec** – PIM requirements and their allocations to logical elements.
  - **Verification Readiness & Test Intent** – verification objectives and test strategy at PIM.
  - **PIM Gateway Readiness** – design‑review/gateway pack for entering PSM.

Each document is defined as a **SysML view** that:

- **Satisfies** one or more MDA viewpoints (e.g. Stakeholder Needs, ConOps, Logical Architecture, Gateway Readiness).
- **Exposes** relevant packages, elements, and viewports (CIM/PIM structure, requirements, lifecycle artifacts).
- Is rendered via standard profiles (tables, trees, textual snapshots).

### CI and document generation

The project uses **GitHub Actions** to keep documentation in sync with the models:

- On each push to `main`, the CI workflow:
  - Checks out the repo and installs LaTeX + tex4ht.
  - Runs the Python generator (`python -m generators`) against `model/` to build LaTeX sources for all `DOC_*` views.
  - Runs `pdflatex` and `make4ht` to produce **PDF** and **HTML** artifacts for each generated `.tex` file.
  - Uploads the outputs as a versioned `generated-docs` artifact (with `pdf/` and `html/` subfolders).

This gives you:

- A **repeatable document build** driven entirely by the SysML models and MDA library.
- A single CI entry point where future generators (e.g. PIM/PSM‑based code, configuration, or tests) can be added alongside the doc pipeline.

At a high level, you can think of this repo as a **working example of MDA applied to an HL7 adapter**: CIM and PIM models, a reusable MDA library, and a doc/CI pipeline that turns those models into human‑readable artifacts for stakeholders and lifecycle governance.

