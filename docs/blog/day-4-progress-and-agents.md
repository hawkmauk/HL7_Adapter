# Day Four: Progress Picking Up, Product Owner in the Loop, and Agent-Led Dev Reviews

*HL7 Adapter build log — 20 Feb 2026*

---

Day four has started and **progress through the issues is picking up**. That’s as expected: there’s more context and more examples in the model now, so the agents have more to work with. It’s **really pleasing** to see—and it matches what we hoped when we said that as the project grows, the LLM would get better at SysML v2 because the codebase itself becomes the reference.

I **queried my first GitHub issue content with the Product Owner agent**. I pasted in the issue and asked it to revise the acceptance criteria. It did—and I do love challenging product owners! Having an agent in that role means I can push back on scope or wording without the same friction as with a human PO; the agent just revises. So we’re now using the Product Owner not only to plan the backlog but to **refine individual issues** when something’s unclear or needs tightening. That’s a concrete step toward “Product Owner → GitHub” being a real workflow.

I’ve also found it **really useful having an agent do the dev reviews**. The reviewer agent is **stricter than I would be** at this point with deadlines looming. I’m tempted to wave things through; the agent doesn’t feel the pressure and **keeps professional**. It checks that changes are scoped to the issue, that conventions are followed, and that the diff makes sense—and it doesn’t relax the bar just because we’re in a rush. So the dev review step is no longer just me glancing at my own PR; the agent holds me to a consistent standard. That’s exactly what we wanted when we added it.

I’ve been giving the **Python engineer agent a loose rein** when it comes to the generator—letting it design and implement the pipeline with minimal micromanagement. It’ll be **interesting to see at the end what the implementation looks like**: the agent has the spec (parse models, emit LaTeX and eventually code), the project context, and the freedom to structure things its way. We’ll see what we get.

We also seem to **get better results when we plan the implementation of the issue with Cursor**—sketching the approach or breaking down the steps in conversation before (or while) coding. So the loop that works is: issue → plan with Cursor → implement → agent dev review. Planning in Cursor keeps the change aligned with the model and the backlog.

I’ve also been **providing examples from the SysML Release Training and examples folder** to the system engineer agent when I ask it to create or refine model elements. That has **helped**—the agent can match patterns and syntax from those reference models instead of guessing. So the guides under `agent/guides/sysml` aren’t just for humans; feeding them to the system engineer improves the quality of what it produces.

So day four so far: **cadence improving**, **Product Owner revising acceptance criteria on real issues**, and **agent-led dev reviews** proving their value. **Planning implementation with Cursor** and **feeding SysML training/examples** to the system engineer agent both help. The generator is in the Python agent’s hands. More to come as we push through the architecture focus and toward deployment.

---

## Later in day four: mixed bag

It’s been a **mixed bag** so far today. **Lots of progress early on**—we **completed the PIM**, which was a clear milestone. The **PSM has started well** too, but **creating and displaying the trade studies** has been a challenge. The initial AI-generated design had **a lot of duplication** and was **quite simple**; I **restructured it** and learned about **evaluations in SysML** along the way. So the PSM trade-study / technology-selection side is in better shape now, but it cost time.

**Once again the documentation side of things has distracted**—generating and refining the docs (ConOps, PSM platform realization, etc.) pulls focus. I’ll need to **try and focus more on delivering an actual application**: the model and the docs are valuable, but the challenge is to get a runnable adapter over the line. So the reminder for the rest of the day (and the deployment phase): keep the model and docs in sync, but **prioritise getting something that runs**.

I’ve also had a **couple of git branching and merging issues** today—minor annoyances, but they could have eaten time. The **GitHub CI agent** has been able to **help me resolve them quickly**: understanding the conflict, suggesting the right commands, or clarifying the branch state. So the agent we brought in for workflows and CI is paying off for day-to-day git friction too.

We’ve come to a **bit of a crux moment** now in day four: we’re **starting to look at code generation**. I wondered whether I’d just **give an agent the model and let it build**—hand over the PIM/PSM and say “implement this.” That would be one path. Instead we’re **progressing with the path chosen by the Product Owner**: the backlog, the issues, the order of work. We’ll see how it turns out. If the structured approach gets us there, great; if we end up needing a more “model-first, agent builds” push later, we can try that too. For now, **trust the PO and follow the plan**.

We’ve hit an **interesting problem** with the code generation: we need to **automatically generate as much of the code as possible** but still **provide hooks to inject code where needed**—so that the generated structure stays the source of truth while we can plug in hand-written logic, config, or overrides without breaking regeneration. I’ve **pulled out the big guns** and am **working closely with Opus 4.6** to try and get a process that works **without sacrificing the core purpose of our MDA**: model-driven, traceable, regenerable, but with clear extension points for the bits that have to be custom. It’s the classic “generate vs. hand-maintain” tension; we’re trying to land on a pattern that keeps both.

We’re **slowly teasing the code generation out**—trying to make **as much of it as possible generated from the SysML structure** and **minimising the bespoke language-specific code**. So the generator should drive structure, interfaces, and wiring from the model; the hand-written parts should be the narrow “fill in this hook” slices. Every time we can move a bit more from “hand-written in TypeScript” to “derived from this PSM element,” we do. It’s incremental, but that’s the direction.

I’ve been able to **work with the agent to define a rule**: if an action includes a **`self` input**, it’s a **method of a class**; otherwise it’s a **helper function** and can appear **outside the class** in the module. That seems to **fit nicely in all the scenarios** we’ve looked at—we’ll see how the implementation turns out. The upshot should be that we can **keep the method signatures generated** and only the **method body** implemented in **`rep textualRepresentation`** (or equivalent) SysML elements. So the model drives the shape and the wiring; the rep holds the actual implementation text. That’s the target pattern.

**By end of day four** we had made **good progress** and were **in the middle of getting the methods generated from the model**. Day five—the last day—would start with a decision about how far to take the codegen.
