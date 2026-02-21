# Day Five: The Codegen Decision

*HL7 Adapter build log — 21 Feb 2026*

---

It’s the **last day—day five**—and there’s a decision to make about how to finish. We’re partway through generating methods from the model; the generator can produce structure and we’ve defined the self/method vs. helper rule and the `rep textualRepresentation` pattern. But we’re not going to get a fully generated, production-ready solution in one day. So: what’s the plan?

**First bit of day five:** I spent time getting a **helper script** up and running to manage the generation tasks. **LaTeX output is now a lot cleaner**—generated docs go into **`pdf/` and `html/`** directories instead of cluttering a single folder. The **TypeScript output** is **run and build** as part of the same flow. **All from one command:** `./scripts/build.sh`. So we have a single entry point for “generate docs, generate code, build the app”—which makes the last-day push much easier.

**Option 1: Continue with a purely generated solution.**  
This has **high risk**. A more robust approach would be to generate code from the **SysML abstract syntax**, so we’d have an **additional translation** step (model → AS → code). We’d be looking at **replacing the generator’s graph with a database** that can be queried to build the structures we want before codegen—a **great solution** long term, but we’re **not going to get it done in a day**.

**Option 2: Continue with the generation as is, knowing it won’t be the long-term solution.**  
The codegen would **only get more complex and messy** as the project progresses. This also **carries risk**—we’d be building on a foundation we don’t intend to keep.

**Option 3: Get to a point where the majority is built by the codegen, then continue to manually build the solution.**  
We’d **show the main development workflow** (model → generator → structure, then fill in the rest by hand) while **derisking the ability to deliver on time**.

**Option 4: Manually build the solution from the model as it is.**  
Use the model as the spec and reference, but write the code by hand. No further investment in the generator for this sprint.

I’m going to choose **option 3**. Get the codegen to a point where it produces the **majority** of the structure and wiring, then **manually complete the solution**. That way we still demonstrate the **model-driven workflow** and the value of the generator, without betting the final delivery on a fully automated pipeline we can’t finish and harden in one day. We derisk delivery while keeping the story intact: the model drives the design, the generator does a lot of the heavy lifting, and we close the gap by hand where we have to. Day five is about getting to that handover point and then shipping.
