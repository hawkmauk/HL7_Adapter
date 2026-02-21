# Big News: Passing Unit Tests Generated from the Model

*HL7 Adapter build log — Feb 2026*

---

We have **passing blank unit tests that are generated from the model.** That’s the milestone: the verification pipeline is no longer just an idea—the generator produces test files (e.g. Vitest), they run, and they pass. The tests are “blank” in the sense that they’re stubs or minimal cases generated from the model structure (e.g. from verification cases or from the PSM actions/components), not yet full behavioural assertions. But the **chain is there**: model → generator → test code → green run. That’s the foundation.

It took **about four hours** to get a suitable implementation working. There was a fair amount of wiring: parsing the right bits of the model (verification cases, actions, or components), mapping them to test cases and describes, and emitting the target format (e.g. TypeScript/Vitest) in a way that fits the rest of the repo. Now that the path is clear, I’m hoping it will be **fairly straightforward to build on**—adding more verification cases or more coverage should mostly mean extending the model and the generator logic rather than reinventing the pipeline.

The **buzz from getting this implemented is massive.** It’s giving me the **confidence to continue** down the model-driven verification path. We’d talked about the tension between “verification cases in SysML” and “AI-generated tests in the target language.” Having real, runnable tests that come from the model tilts the balance: the method works, and the overhead of keeping verification in the thread feels worth it. Next step is to flesh out the tests with real expectations and keep the model as the single source of truth for what we’re verifying.

---

**Suggested title (alternatives)**  
- Big News: Passing Unit Tests Generated from the Model  
- Model → Generator → Green: Our First Generated Unit Tests  
- Four Hours In: Generated Unit Tests Are Passing  

**Teaser (social / newsletter)**  
We have passing unit tests generated from the SysML model. It took ~4 hours to get the pipeline right—and it’s a massive confidence boost for staying in the MBSE thread.
