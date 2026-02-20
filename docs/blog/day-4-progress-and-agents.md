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
