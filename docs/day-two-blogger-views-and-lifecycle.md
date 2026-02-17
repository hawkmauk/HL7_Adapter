# Day Two: Blogger Agent, Standard Views Library, and Project Lifecycle

*HL7 Adapter build log — 18 Feb 2026*

---

Day one locked in the MDA approach, the systems engineer prompt, the CIM, and the LaTeX doc pipeline. Day two was about making the documentation and governance side of the digital thread reusable and explicit. First job: an agent that specializes in *writing* prompts.

## Prompt Writer Agent

We’d already written a few prompts—for CIM and PIM generation, plus agent prompts like the systems engineer and blogger—so it felt like time to have a **dedicated agent for prompts**. I created the **prompt writer** in `agent/prompt_writer.prompt`. Its role is to take goals and constraints (role, audience, task type, output format, examples) and produce clear, effective prompts that get consistent results from the target system (Cursor, ChatGPT, Claude, etc.). The prompt lays out principles: state role and inputs/outputs explicitly, put important instructions first, use bullets and sections, specify constraints and project structure, and match the style of existing agents in the repo. It also tells the writer to ask a few short questions if the request is vague, and to offer variants (e.g. short reminder vs. full prompt) when useful. Output is the final prompt text plus an optional usage note and any variants.

Once the prompt writer was in place, I set it to work **improving the first systems engineer prompt**. The result is the refined `agent/system_engineer.prompt`: clearer lifecycle target (CIM → PIM → PSM), explicit “be terse” and “prefer direct edits” behavior, SysML v2 and `model/` location rules, element documentation requirements, and a “definition of done” so the agent knows when a task is complete. So the systems engineer agent is now steered by a prompt that the prompt writer agent helped shape—meta, but it keeps the agent instructions consistent and maintainable.

## Blogger Agent

I wanted the build log to be part of the workflow, not a “write it up later” chore. So I created a dedicated **blogger agent** prompt in `agent/blogger.prompt`. The agent’s job is to take raw notes—bullets, rough paragraphs, references to code or diagrams—and turn them into blog-ready posts: first person, practitioner voice, short paragraphs and clear headings, with technical terms (CIM, PIM, SysML, HL7, ConOps) used correctly and no invented detail. The prompt also asks for a suggested title, optional subtitle options, and a sentence or two for social or newsletter teasers. When I have progress or a decision, I paste the prompt and my notes; the agent returns a draft I can drop into the `docs/` folder. This post is the first one produced that way for day two.

## Standard Views Library and MDA Library

On day one we had project-specific viewports and document blueprints in `CIM_ProjectViews.sysml`. That worked, but it tied the documentation pattern tightly to this one project. To make the generated docs **reusable across projects**, I introduced an explicit **MDA view library** and a project-agnostic CIM skeleton.

At the core is a new `ViewLibrary` package in `model/ViewLibrary/ViewLibrary.sysml`:

- **StandardViewpointCatalog** — abstract viewpoints (StakeholderConcernsViewpoint, LifecycleGateReadinessViewpoint, ArchitectureAndBehaviorViewpoint, VerificationAndComplianceViewpoint) that CIM, PIM, and PSM catalogs specialize.
- **StandardRenderProfiles** — shared render profiles (element table, tree diagram, textual notation) so any view library can rely on the same generation contract.

On top of that sits the **CIM view library** in `model/ViewLibrary/CIM_ViewLibrary.sysml`:

- **CIMStandardStructure** — a project-agnostic CIM skeleton (`CIMSkeleton` package) with empty `Domain`, `Stakeholders`, `Context`, `Operations`, `Mission`, and `Assumptions` packages, plus requirements that a conforming CIM must provide each of them. This decouples the *shape* of a CIM from any one project.
- **CIMStandardViewpointCatalog** — concrete CIM viewpoints (StakeholderNeeds, ConOps, OperationalScenarios, InterfaceContext, ComplianceAndSafety, LifecycleGatewayReadiness) that specialize the abstract ones from `ViewLibrary`.
- **CIMStandardDocumentPortfolio** — generic document views (SNRS, ConOps, Operational Scenarios, EICD, RSCM, SCHA, Gateway Signoff) bound to those viewpoints and render profiles.

With this in place, a project-specific package like `CIM_ProjectViews` just binds its concerns and viewports to the standard viewpoints and documents from the MDA library. The **document definitions and CIM structure are now shared assets**, not hard-wired to this HL7 Adapter, which will also help when we add other generators (for example, code) that need to understand viewpoints and structure.

## Project Lifecycle in the Model

The **project lifecycle** is no longer implied—it’s modeled. `ProjectLifecycle.sysml` gives us:

- **LifecyclePhase** — Concept (CIM), LogicalDesign (PIM), PlatformRealization (PSM), ValidationAndRelease. So we can tag milestones and gate readiness by phase.
- **SignoffStatus** — Draft, InReview, Approved, Rejected. Useful for gateway check views and “have we got consensus?” reporting.
- **LifecycleMilestone**, **GatewayCheck**, **SignoffRecord** — The concepts we need to represent “we’re at the CIM gate,” “here’s the checklist,” “here’s who signed off and with what status.”
- **CIMConsensusGateway**, **PIMConsensusGateway**, **PSMReleaseGateway** — The three gates we care about for MDA. CIM_ProjectViews already has a view (e.g. `VPT_006_CIMGatewayReadiness`, `DOC_CIM_GatewaySignoff`) that exposes gateway and signoff evidence; that view is backed by this lifecycle model.

So governance is on the digital thread too: gates, phases, and signoff are first-class model elements. As we add PIM and PSM, we’ll hook their view libraries and project views into the same lifecycle and reuse the same stakeholder and viewpoint patterns.

## What I Did Today

- **Created the prompt writer agent** — `agent/prompt_writer.prompt`: dedicated agent for writing and refining prompts; used it to improve the systems engineer prompt (`agent/system_engineer.prompt`) with clearer structure, terse output behavior, and definition of done.
- **Created the blogger agent** — `agent/blogger.prompt`: prompt that turns notes into structured blog posts (title, body, optional teaser), with voice and technical-accuracy rules.
- **Structured the standard views library** — ProjectLifecycle (StandardDocumentationFramework with abstract viewpoints, standard stakeholders, render profiles; LifecycleGovernance with phases, status, and gate types) and CIM_ViewLibrary (CIM standard structure requirements and CIM viewpoint catalog specializing the standard).
- **Added the project lifecycle** — Lifecycle phases, signoff status, milestones, gateway checks, signoff records, and the three MDA gate types (CIM, PIM, PSM) as part of the shared model.

## Next Up

- **Refine CIM content** — Deeper domain, scenarios, and assumptions; keep concerns and viewpoint coverage aligned.
- **PIM view library** — Same idea as CIM: PIM standard structure and PIM viewpoint catalog, reusing ProjectLifecycle and the same documentation framework.
- **Use the blogger agent** — Feed it progress as we go so the build log stays current without becoming a bottleneck.

If you’re curious about view libraries in SysML, lifecycle-in-the-model, or keeping a build log with an agent, I’ll keep posting as we go.
