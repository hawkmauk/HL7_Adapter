# Trade Study Modeling in SysML (Textual Notation) — Guidance

This note summarizes **examples and patterns from the web** and suggests **concrete options** for recording PSM trade studies in SysML textual notation.

---

## 1. Web examples and common practice

### No Magic / Cameo (SysML v1 + tool profile)

- **Source:** [Trade study analysis – Magic Model Analyst](https://docs.nomagic.com/spaces/MSI2022xR1/pages/111216502/Trade+study+analysis)
- **Idea:** A trade study compares **alternatives** against **criteria** using **measures of effectiveness (MOEs)** and an **objective function** to pick a preferred solution.
- **Pattern:**
  - **Analysis block** inheriting from a “Trade Study Analysis Block”.
  - **Alternatives** = reference properties typed by a block (e.g. `C : Caliper`, `R : Rotor`, `P : Pad`); can be from instance tables, subtypes, Excel, or parameter sweep.
  - **Objective function** = a constraint block whose equation has **LHS = score** (bound to `TradeAnalysis::^score`) and **RHS = expression** over weighted parameters (MOEs). The tool compares scores to select a winner (max or min).
  - Binding: each alternative’s value properties (MOEs) feed the objective function; the result is the score used to compare alternatives.

### Literature (MBSE / SysML)

- **MOEs:** Each alternative is characterized by value properties that correspond to evaluation criteria.
- **Objective function:** Cost or utility function over those MOEs (e.g. weighted sum) to compare alternatives.
- **Constraint blocks:** Used to define the objective function and, where applicable, requirement constraints that alternatives must satisfy.
- **Decision frameworks:** Trade-off analysis can be modeled with “decision points” and constraint satisfaction; integration with MDAO/parametric tools is common for automated exploration.

### SysML v2

- **Constraint definitions** and **analysis cases** support design trade-offs and analysis.
- **Textual notation** uses the same semantics as the graphical form; trade studies can be expressed with `constraint def`, `part def`, value properties, and bindings (as in your PIM parametrics).

---

## 2. Options for recording trade studies in SysML textual notation

Below are **three patterns** that fit your existing style (packages, `constraint def`, `part def`, `requirement`).

### Option A — Package-based (current, with clearer structure)

Keep one **package per trade study**, with nested packages or elements for **Criteria**, **Candidates**, and **Selection**, and use **doc** to capture:

- Criteria (and, where relevant, “derived from” PIM requirements, e.g. SYS2.1–SYS2.5).
- List of candidates.
- Selection and rationale.

**Pros:** Simple, tool-neutral, good for narrative and doc generation.  
**Cons:** Criteria and candidates are not first-class (e.g. no direct `satisfy` from requirements).

---

### Option B — Traceable criteria (requirements / satisfy)

Keep the same package structure but make **criteria traceable** to PIM requirements:

- In the **Criteria** package (or a single “criteria” element), use **doc** to cite requirement short names (e.g. SYS2.1–SYS2.5), and/or add **satisfy** relationships from the trade study (or a “study context” part) to the relevant PIM requirements so the model explicitly links “this study’s criteria are covered by these requirements.”
- Candidates and selection can stay in **doc** or be split into separate packages/parts.

**Pros:** Clear traceability from trade study to requirements; supports compliance and impact analysis.  
**Cons:** Slightly more model elements and relationships.

---

### Option C — Parametric / analysis block (alternatives + objective function)

Model one (or more) trade studies in a way that mirrors the **No Magic / literature** pattern and your **PIM parametrics**:

1. **Alternatives** = **part defs** (or item defs) representing each option (e.g. `NodeRuntime`, `PythonRuntime`, `GoRuntime`), each with **value properties** for the MOEs (e.g. `hl7EcosystemScore : Real`, `asyncIOScore : Real`, `lyrebirdAlignmentScore : Real`).
2. **Objective function** = a **constraint def** with parameters for (weighted) MOEs and an output (e.g. `score`). Example: `score = w1 * hl7EcosystemScore + w2 * asyncIOScore + w3 * lyrebirdAlignmentScore`.
3. **Analysis context** = a **part def** that owns:
   - **Parts** for each alternative (with values or bindings to MOEs).
   - A **constraint** (instance of the objective function) bound so that each alternative’s MOEs feed the constraint and produce a score; the **selection** is the alternative with the best score (documented in **doc** or as a separate “winner” attribute/result).

**Pros:** Reuses your existing parametrics style; alternatives and criteria are first-class; analyzable (e.g. in a tool that evaluates constraints).  
**Cons:** More verbose; requires assigning MOE values or bindings; best when you want repeatable or tool-supported comparison.

---

## 3. Recommendation and current implementation

**Current implementation:** `model/PSM/technology_selection.sysml` uses **Option C** (parametric analysis block) for all four trade studies:

- **Shared:** `WeightedScore3` constraint def (score = w1·moe1 + w2·moe2 + w3·moe3).
- **Per study:** An alternative **part def** (with 3 MOE value properties), and a **part def** analysis context that owns parts for each candidate, weight and score attributes, and constraint bindings. Selection is documented in the context **doc** (winner = alternative with max score).

**Other options:**

- **Option A** remains available for quick, doc-only studies.
- **Option B** can be added for explicit **satisfy** from trade-study criteria to PIM requirements (e.g. SYS2.x, SYS3.x).

---

## 4. References

| Source | Content |
|--------|--------|
| [No Magic – Trade study analysis](https://docs.nomagic.com/spaces/MSI2022xR1/pages/111216502/Trade+study+analysis) | Analysis block, «alternatives», «objectiveFunction», binding to score, instance table / subtypes / Excel / parameter sweep. |
| MBSE / SysML trade studies (Academia, INCOSE) | MOEs, objective/cost functions, constraint blocks, decision frameworks, MDAO integration. |
| SysML v2 (OMG, SysML v2 Release) | Constraint definitions, analysis cases, textual notation; same semantics as graphical. |
