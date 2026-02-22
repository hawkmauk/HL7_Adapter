# Digital Thread and MDA

## A proof of concept for the Digital Thread

This project is a **proof of concept** for a **Digital Thread**: all project information is captured in a **model**, and the model is our **single source of truth**. We do not maintain separate docs, code, and specs that drift apart. We define **views** into the model, and we generate everything from it.

The **PDF documents** we produce (ConOps, requirements, interface design, gateway signoff, and so on) are **snapshots from the model at a point in time**. So is the **executable program** we run: the TypeScript adapter is a view of the model at a point in time. Documentation and software are both **generated from the model**. That is the core idea: one model, many views, full traceability.

## How we develop

We add **domain data** to the model first, in the **CIM** (Computation‑Independent Model): stakeholders, mission, operational context, scenarios, and assumptions. We then capture the **behaviours** the system should exhibit and the **requirements** it must satisfy. These are **explicitly linked** to the domain data—requirements to use cases, use cases to domain concepts—creating the thread from problem space to solution space.

We run **case studies** to choose technology and design decisions (e.g. SQLite vs PostgreSQL, Node.js/TypeScript for the adapter), and we **record those decisions in the model**. Only after that do we build the **structure of our system** in the **PSM** (Platform‑Specific Model): components, interfaces, state machines. At that stage we add **snippets of code** into the model for our target language. The **generator** builds the software from the model; the snippets are **inserted to fill out function bodies**. We do not hand‑write the architecture in code—we express it in the model and generate the rest.

We can add snippets for **different languages** and extend the generator to produce **Python, C, Rust**, or any other target. The **system is unchanged** in the model; we simply **express the model in different ways**. That is the real power of **model‑based systems engineering (MBSE)**: separating **architecture** (what the system is and how it behaves) from **implementation** (how it is expressed in a given language or platform)—in the same way that **HTML** (structure) is separated from **CSS** (presentation).

## MDA levels in this repo

The model is organised using **Model‑Driven Architecture (MDA)** abstraction levels:

- **CIM (Computation‑Independent Model)**: business and domain—stakeholders, mission, operational context, scenarios, assumptions.
- **PIM (Platform‑Independent Model)**: logical solution—logical architecture, interfaces, behaviour, requirements, allocations.
- **PSM (Platform‑Specific Model)**: technology‑bound design and code snippets—components, bindings, and the executable view.
- **MDA Library**: reusable, project‑agnostic patterns for structure, viewpoints, lifecycles, and document templates shared across projects.

Requirements, design, lifecycle gates, generated docs, and generated code are all **traceable to model elements**.

## Repository structure (high level)

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
- `docs/`: narrative documentation, build logs, design notes, and [CI/CD and generated documentation](CI_CD.md).
- `scripts/`: helper scripts for building and running generated artifacts.

For editing SysML (`.sysml`) files we use the **SysIDE** editor plugin with **VS Code** for SysML syntax highlighting.
