# Day Two: Blogger Agent, Standard Views Library, and Project Lifecycle

*HL7 Adapter build log — 18 Feb 2026*

---

Day one locked in the MDA approach, the systems engineer prompt, the CIM, and the LaTeX doc pipeline. Day two was about making the documentation and governance side of the digital thread reusable and explicit. First job: an agent that specializes in *writing* prompts.

## Prompt Writer Agent

We’d already written a few prompts—for CIM and PIM generation, plus agent prompts like the systems engineer and blogger—so it felt like time to have a **dedicated agent for prompts**. I created the **prompt writer** in `agent/prompt_writer.prompt`. Its role is to take goals and constraints (role, audience, task type, output format, examples) and produce clear, effective prompts that get consistent results from the target system (Cursor, ChatGPT, Claude, etc.). The prompt lays out principles: state role and inputs/outputs explicitly, put important instructions first, use bullets and sections, specify constraints and project structure, and match the style of existing agents in the repo. It also tells the writer to ask a few short questions if the request is vague, and to offer variants (e.g. short reminder vs. full prompt) when useful. Output is the final prompt text plus an optional usage note and any variants.

Once the prompt writer was in place, I set it to work **improving the first systems engineer prompt**. The result is the refined `agent/system_engineer.prompt`: clearer lifecycle target (CIM → PIM → PSM), explicit “be terse” and “prefer direct edits” behavior, SysML v2 and `model/` location rules, element documentation requirements, and a “definition of done” so the agent knows when a task is complete. So the systems engineer agent is now steered by a prompt that the prompt writer agent helped shape—meta, but it keeps the agent instructions consistent and maintainable.

## Blogger Agent

I wanted the build log to be part of the workflow, not a “write it up later” chore. So I created a dedicated **blogger agent** prompt in `agent/blogger.prompt`. The agent’s job is to take raw notes—bullets, rough paragraphs, references to code or diagrams—and turn them into blog-ready posts: first person, practitioner voice, short paragraphs and clear headings, with technical terms (CIM, PIM, SysML, HL7, ConOps) used correctly and no invented detail. The prompt also asks for a suggested title, optional subtitle options, and a sentence or two for social or newsletter teasers. When I have progress or a decision, I paste the prompt and my notes; the agent returns a draft I can drop into the `docs/` folder. This post is the first one produced that way for day two.

## Dedicated MDA Library and Loose Coupling

On day one we had project-specific viewports and document blueprints in `model/CIM/views.sysml`. To make the generated docs **reusable across projects**, we turned that into a **dedicated MDA Library** under `model/MDA_Library/`—a first-class template that any MDA-style project can reuse.

- **Root** — `MDA.sysml` aggregates the main namespaces: `MDA_Structure`, `MDA_View`, `MDA_Lifecycle`, and `MDA_CIM`, with short aliases (`Structure`, `Views`, `Lifecycle`, `CIM`) so imports stay readable.
- **Shared building blocks** — At the top level: `structure.sysml`, `view.sysml`, `viewpoint.sysml`, and `lifecycle.sysml` (cross-cutting structure contracts, abstract viewpoints, render profiles, lifecycle phases and gates).
- **CIM slice** — Under `CIM/`: CIM-specific structure (skeleton, package requirements), viewpoints (StakeholderNeeds, ConOps, OperationalScenarios, InterfaceContext, ComplianceAndSafety, LifecycleGatewayReadiness), and view definitions that become the document types (SNRS, ConOps, EICD, RSCM, SCHA, Gateway Signoff). Same pattern will extend to PIM and PSM.

The folder layout is **logically separated** and much easier to navigate than one big file—a lot of that organisation was manual, as it took some working through to decide what belonged where.

**Documentation** (ConOps, gateway signoffs, SNRS, EICD, etc.) is **generated from the MDA Library**. The library defines *what* documents exist and *what* structure a conforming CIM must have. The **project** (`model/CIM/views.sysml`, `model/CIM/CIM.sysml`) only provides stakeholders, concerns, the actual CIM content, and viewports that *satisfy* the library’s viewpoints and *expose* that content. So we get **loose coupling**: the template lives in the MDA Library; the HL7 Adapter only fills in *who*, *what*, and *how* for this system. ConOps and gateway signoffs are the same *kind* of document across projects; only the content is project-specific.

## Project Lifecycle in the Model

The **project lifecycle** is no longer implied—it’s modeled. `ProjectLifecycle.sysml` gives us:

- **LifecyclePhase** — Concept (CIM), LogicalDesign (PIM), PlatformRealization (PSM), ValidationAndRelease. So we can tag milestones and gate readiness by phase.
- **SignoffStatus** — Draft, InReview, Approved, Rejected. Useful for gateway check views and “have we got consensus?” reporting.
- **LifecycleMilestone**, **GatewayCheck**, **SignoffRecord** — The concepts we need to represent “we’re at the CIM gate,” “here’s the checklist,” “here’s who signed off and with what status.”
- **CIMConsensusGateway**, **PIMConsensusGateway**, **PSMReleaseGateway** — The three gates we care about for MDA. The CIM views file already has a view (e.g. `VPT_006_CIMGatewayReadiness`, `DOC_CIM_GatewaySignoff`) that exposes gateway and signoff evidence; that view is backed by this lifecycle model.

So governance is on the digital thread too: gates, phases, and signoff are first-class model elements. As we add PIM and PSM, we’ll hook their view libraries and project views into the same lifecycle and reuse the same stakeholder and viewpoint patterns.

## Python Agent for the Generator

Extending the LaTeX/document generator (and eventually adding code generation from PIM/PSM) needed someone with a clear remit in the codebase. So I added a **dedicated Python agent** for the generator: `agent/python_engineer.prompt`. That agent is a senior Python engineer focused on **parsing models and generating code**—designing and implementing generators that consume our SysML v2 models and the MDA Library and produce artifacts (today mainly docs, tomorrow services, DTOs, config, or tests). The prompt gives it project context (MDA, CIM/PIM/PSM, `MDA_Library`), clear inputs and outputs, and rules: deterministic and regeneration-friendly generation, don’t overwrite hand-maintained files, make mapping rules explicit and traceable. When I need a new generator or a pipeline change, I point it at the relevant model files and describe the desired artifacts; it proposes and implements the Python and templates.

## What I Did Today

- **Created the prompt writer agent** — `agent/prompt_writer.prompt`: dedicated agent for writing and refining prompts; used it to improve the systems engineer prompt (`agent/system_engineer.prompt`) with clearer structure, terse output behavior, and definition of done.
- **Created the blogger agent** — `agent/blogger.prompt`: prompt that turns notes into structured blog posts (title, body, optional teaser), with voice and technical-accuracy rules.
- **Structured the standard views library and project lifecycle** — Lifecycle phases, signoff status, gate types; abstract viewpoints and render profiles; CIM structure, viewpoint catalog, and document portfolio.
- **Created a dedicated MDA Library** — `model/MDA_Library/`: root `MDA.sysml` plus `structure.sysml`, `view.sysml`, `viewpoint.sysml`, `lifecycle.sysml`, and CIM slice; logically separated and easier to navigate (organisation was manual as we worked through the best structure).
- **Loose coupling** — Documentation (ConOps, gateway signoffs, etc.) is generated from the library; the project only supplies stakeholders, concerns, CIM content, and viewports that satisfy the library’s viewpoints.
- **Created the Python generator agent** — `agent/python_engineer.prompt`: dedicated agent for parsing SysML models and implementing generators (docs now, code later).

## Next Up

- **Refine CIM content** — Deeper domain, scenarios, and assumptions; keep concerns and viewpoint coverage aligned.
- **PIM slice in MDA Library** — Same pattern as CIM: PIM structure, viewpoints, and document portfolio.
- **Use the Python agent** — Evolve the doc generator and, later, add PIM/PSM-based code generation.

If you’re curious about view libraries in SysML, lifecycle-in-the-model, or keeping a build log with an agent, I’ll keep posting as we go.
