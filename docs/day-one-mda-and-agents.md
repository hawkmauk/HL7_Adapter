# Day One: Going MDA and All-In on AI

*HL7 Adapter build log — 17 Feb 2026*

---

I’m building the [Lyrebird Technical Challenge](https://www.lyrebird.com/) integration: an HL7 message sender and receiver that listens on TCP (MLLP), parses messages into JSON, and POSTs them to a REST API. Straightforward on the surface—but I didn’t want to “just code it.” I wanted to treat it as a small systems project and see how far I could push a strict, model-first approach. So at the end of day one, I made two decisions that will shape the whole build.

## 1. Model-Driven Architecture, as Strict as I Can Make It

I’m building this using a classic **MDA** (Model-Driven Architecture) stack: **CIM → PIM → PSM**.

- **CIM** (Computation-Independent Model): *what* the system does and for whom—stakeholders, operational context, concepts of operations (ConOps). No solution structure yet.
- **PIM** (Platform-Independent Model): *logical* architecture—blocks, interfaces, behaviour, data—still no specific tech.
- **PSM** (Platform-Specific Model): the concrete stack (e.g. TCP, MLLP, HTTP, chosen language and frameworks).

The important part: **everything stays in SysML**. Requirements, structure, behaviour, and later the link to code and config—all in the model. One digital thread, one source of truth. I’m not aiming for a loose “we have some diagrams”; I want the project’s design and rationale to live in the model first, and code to be derived from there as much as possible.

That’s the plan. I’ll see how strict I can stay when deadlines bite.

## 2. All-In on AI-Assisted Development

I’m doing the actual implementation with **Cursor IDE and agent-style workflows**. Not as a gimmick—because it’s faster and it’s how I want to work. I’ve been using this setup for a while, so I’ve hit the usual pitfalls: agents that drift from the architecture, that invent APIs, or that optimize for “something that runs” instead of “something that matches the model.” I’m trying to mitigate that by being explicit about the architecture and the rules of the game—which is why the very first job was **writing an agent prompt**.

That first prompt was the **systems engineer** prompt (in `agent/system_engineer.txt`): it orients the agent on SysML v2, Model-Driven Architecture (CIM → PIM → PSM), and the project's model folder and guides so that generated models stay aligned with the architecture. Later I added a **blogger agent** (`agent/blogger.txt`) to turn rough notes into readable posts like this one—so the blog is part of the workflow too.

## Timeline (from the repo)

Here's what actually landed on day one, in commit order:

1. **Add GitHub Actions** — CI workflow to build docs on every push to `main`.
2. **Add initial document generator** — Python framework that parses SysML model files and extracts document views.
3. **Add tex4ht generation** — HTML output (via make4ht) alongside PDF, using a Lyrebird-style config.
4. **Created CIM_Views** — View library, project viewports, and document blueprints (see below).
5. **Created agent persona, modelling guides, examples and CIM** — Agent prompts, CIM/PIM guides, and the first CIM package (Domain, Stakeholders, Context, Operations, Mission, Assumptions).

So by end of day one we had a CIM, a view-based documentation model, and a pipeline that turns it into PDF and HTML. No manual Word docs—the artifacts are *generated from the model*.

## SysML Views: Stakeholder Documentation in the Digital Thread

Standard product-development and systems-engineering processes expect specific documents: Stakeholder Needs and Requirements, Concept of Operations, External Interface Context, Compliance Matrix, Gateway Signoff, and so on. The usual trap is maintaining those as separate files that drift from the design. To keep everything in the digital thread, we don't author those documents by hand—we define **what they are** and **what they contain** in the SysML model, then generate the documents from it.

We do that with three concepts:

- **Concerns** — *What* the views (and thus the documents) are *for*. Each concern is a named stakeholder need with traceability to the model (e.g. "reliably ingest HL7 events", "preserve clinical semantics", "clear interface boundaries"). Concerns live in the model and are referenced by viewpoints.

- **Viewpoints** — *What* a given document type *contains*: the set of concerns it addresses and the kind of evidence it frames. We have a small CIM viewpoint catalog (Stakeholder Needs, ConOps, Operational Scenarios, Interface Context, Compliance & Safety, CIM Gateway Readiness), each defined in terms of concerns. Viewpoints are reusable contracts; the project then instantiates them and *frames* the relevant concerns (e.g. `VP_001_StakeholderNeeds` frames ingestion reliability, clinical semantic preservation, and degraded-mode transparency).

- **Views / viewports** — The concrete "documents" as model objects. A **viewport** (e.g. `VPT_001_StakeholderNeedsMatrix`) *satisfies* a viewpoint and *exposes* specific model elements (stakeholders, concerns, mission, etc.) with a chosen render (element table, tree diagram, or textual notation). **Document blueprints** (e.g. `DOC_CIM_SNRS`, `DOC_CIM_ConOps`) then compose viewports and coverage entries so each standard artifact is a named view in the model. Traceability is explicit: coverage matrix entries link stakeholders → concerns → viewpoints → viewports → planned document sections.

So the stakeholder documentation isn't a separate deliverable—it's a set of views over the same CIM. Change the model; regenerate the docs. One thread.

## LaTeX Generator and CI/CD

To show that the digital thread is actionable, we added a **LaTeX generator** that consumes those views and produces real documents. The pipeline:

1. **Parse** — The generator reads `model/*.sysml` and builds a model index.
2. **Extract** — It finds all `DOC_CIM_*` views and their bound viewports, viewpoints, and coverage entries into a document IR (intermediate representation).
3. **Validate** — Quality gates: stable IDs, required docs present, references resolved, purpose text where needed.
4. **Generate** — For the `latex` target it emits one `.tex` file per document view (e.g. `cim-snrs-v0.1.0.tex`, `cim-conops-v0.1.0.tex`), plus shared style, logo, and a coverage report.

From there, the **CI/CD workflow** (on every push to `main`) runs the generator, then runs `pdflatex` and `make4ht` on each `.tex` to produce PDF and HTML. The outputs are uploaded as a single artifact (`generated-docs`) with `pdf/` and `html/` layout. The artifacts aren't published anywhere yet—they're available from the Actions run for now. We'll keep extending this: same pipeline, more targets. Once we have a PSM, we'll add generators that produce code (and maybe config) from the model, so implementation stays on the thread too.

## What I Actually Did Today

- **Decided** on MDA and a strict SysML-backed digital thread for the HL7 Adapter.
- **Decided** to rely heavily on Cursor and agents, with clear prompts and guardrails.
- **Created** the first agent prompt (the systems engineer prompt in `agent/system_engineer.txt`).
- **Added** GitHub Actions to build docs on push to `main`.
- **Implemented** a model-driven document generator (parse → extract → validate → generate LaTeX).
- **Added** tex4ht so we get HTML as well as PDF from the same views.
- **Defined** the CIM view library and project views: concerns, viewpoints, viewports, and document blueprints for standard CIM artifacts (SNRS, ConOps, Operational Scenarios, EICD, Compliance, Safety, Gateway Signoff).
- **Created** the initial CIM (Domain, Stakeholders, Context, Operations, Mission, Assumptions) plus agent persona and modelling guides.

So day one delivered the rules of the game, the CIM, the view-based documentation model, and a working pipeline from model views to PDF and HTML. Next is to deepen the CIM and the PIM, and to grow the generator set when we have a PSM to generate from.

## Next Up

- **Refine the CIM** — Flesh out domain, scenarios, and assumptions; keep concern and viewpoint coverage in sync.
- **Start the PIM** — Logical architecture, interfaces, and behaviour; same view pattern for PIM-level documents.
- **Extend the pipeline** — When we have a PSM, add code (and any config) generation from the model so the digital thread runs all the way to implementation.

If you're curious about MDA in the small, view-based documentation in SysML, or using AI assistance without letting it own the architecture, I'll be posting progress here as I go.
