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
- `ci/generators/`: Python framework that parses SysML and generates LaTeX/HTML documentation based on the view library.
- `docs/`: narrative documentation, build logs, design notes, and [CI/CD and generated documentation](docs/CI_CD.md).

### Documentation

- **Generated docs (HTML and PDF)** are published on **GitHub Pages**: [https://hawkmauk.github.io/HL7_Adapter/](https://hawkmauk.github.io/HL7_Adapter/).
- For details on generated artifacts, the build pipeline, and releases, see [CI/CD and generated documentation](docs/CI_CD.md).

At a high level, this repo is a **working example of MDA applied to an HL7 adapter**: CIM and PIM models, a reusable MDA library, and a doc/CI pipeline that turns those models into human‑readable artifacts for stakeholders and lifecycle governance.

