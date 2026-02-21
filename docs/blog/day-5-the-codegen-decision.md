# Day Five: The Codegen Decision

*HL7 Adapter build log — 21 Feb 2026*

---

It’s the **last day—day five**—and there’s a decision to make about how to finish. We’re partway through generating methods from the model; the generator can produce structure and we’ve defined the self/method vs. helper rule and the `rep textualRepresentation` pattern. But we’re not going to get a fully generated, production-ready solution in one day. So: what’s the plan?

**First bit of day five:** I spent time getting a **helper script** up and running to manage the generation tasks. **LaTeX output is now a lot cleaner**—generated docs go into **`pdf/` and `html/`** directories instead of cluttering a single folder. The **TypeScript output** is **run and build** as part of the same flow. **All from one command:** `./scripts/build.sh`. So we have a single entry point for “generate docs, generate code, build the app”—which makes the last-day push much easier.

I had a **realization**: when we generate the **executable application**, the **model should still be the single source of truth**. The **software realization is just a view of that model at a point in time**—exactly like our PDF and HTML documents. They're all **views** over the same model; the only difference is the target format. That prompted me to **get the generator to use the view** as it does for LaTeX generation—so the codegen is driven by the same view/viewpoint machinery that produces the docs. That **standardizes things nicely**: one model, one view layer, multiple targets (docs and code). The executable isn't a second-class citizen; it's another artifact of the digital thread.

**Option 1: Continue with a purely generated solution.**  
This has **high risk**. A more robust approach would be to generate code from the **SysML abstract syntax**, so we’d have an **additional translation** step (model → AS → code). We’d be looking at **replacing the generator’s graph with a database** that can be queried to build the structures we want before codegen—a **great solution** long term, but we’re **not going to get it done in a day**.

**Option 2: Continue with the generation as is, knowing it won’t be the long-term solution.**  
The codegen would **only get more complex and messy** as the project progresses. This also **carries risk**—we’d be building on a foundation we don’t intend to keep.

**Option 3: Get to a point where the majority is built by the codegen, then continue to manually build the solution.**  
We’d **show the main development workflow** (model → generator → structure, then fill in the rest by hand) while **derisking the ability to deliver on time**.

**Option 4: Manually build the solution from the model as it is.**  
Use the model as the spec and reference, but write the code by hand. No further investment in the generator for this sprint.

I’m going to choose **option 3**. Get the codegen to a point where it produces the **majority** of the structure and wiring, then **manually complete the solution**. That way we still demonstrate the **model-driven workflow** and the value of the generator, without betting the final delivery on a fully automated pipeline we can’t finish and harden in one day. We derisk delivery while keeping the story intact: the model drives the design, the generator does a lot of the heavy lifting, and we close the gap by hand where we have to. Day five is about getting to that handover point and then shipping.

---

The **framework has matured well this morning**—the view structure, concerns, and document/code blueprints are in a good place. So we’ve started looking at the next piece: **how to generate unit tests**.

I’d like to do this **via verification case elements in SysML**. That would keep tests inside the digital thread: verification cases in the model, then generated test code (or at least test structure) from those elements, so we have **traceability from requirement → verification case → test**. The downside is **overhead**: we’d need to introduce verification cases, wire them to the right actions or blocks, and extend the generator (or add a new target) to emit test code from those cases. It’s the **methodologically clean** option, but it’s more work and more model surface to maintain.

We’ve been using **“AI Assisted MBSE with SysML”** as a guide. In there they take a **different path**: they use an **AI prompt** to generate unit tests **directly in the target language** (e.g. TypeScript or Python) from the model or from natural-language descriptions. No verification case elements—just “here’s the model / here’s the behavior, now write tests.” That’s **fast and low-friction**: one prompt, get a test file, drop it in. But it **deviates from the method**. The tests live outside the model; they’re not first-class SysML elements, and we lose the single-source-of-truth story for verification. If we go that route, we’re effectively saying “the model drives design and code, but tests are an AI-generated artifact” rather than “the model drives design, code, *and* verification.”

So there’s a real **tension**: **verification cases in SysML** = consistent with MDA and the digital thread, more upfront and ongoing cost. **AI-generated tests in the target language** = quick and aligned with the book, but a step away from the strict “everything in the model” approach. I’m **leaning toward the pragmatic route** for now—using the AI to generate tests from the model or from behavior descriptions—but I’m **not overly happy** with it. It feels like a compromise on the method. The ideal would be to have verification cases in the model and generate tests from them; the question is whether we can afford that step now or whether we treat it as a later refinement once the rest of the pipeline is stable.

**Next up:** Either commit to the AI-generated-test approach for this phase and document the deviation, or spike on a minimal verification-case → test stub in the generator to see how much overhead it really adds. I’d rather not let the perfect be the enemy of the good—but I also don’t want to bake in a pattern that makes it harder to bring verification back into the thread later.