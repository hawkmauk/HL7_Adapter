# Code Generation from SysML Model

## Overview

The `ci/generators` framework provides a unified pipeline for transforming
SysML model files into multiple output formats. The architecture follows a
pandoc-style approach: one parser, one generic intermediate representation
(the model graph), and pluggable output targets.

```
.sysml files ─→ parsing/ (ModelIndex) ─→ graph/builder.py (ModelGraph) ─→ target
                                                                         ├── targets/latex
                                                                         └── targets/typescript
```

## Architecture

### Parser (`parsing/`)

The parsing package (entry point `parsing/driver.py`: `parse_model_directory`) reads
`.sysml` files and produces a flat `ModelIndex` of `ModelElement`
objects. Recognises: `package`, `part`, `port`, `interface`, `view`,
`constraint`, `use case`, `occurrence`, `action`, `action def`, `state`,
`attribute def`, `item`, signal declarations, and `perform action` usages.

**State machines:** The parser extracts inline state declarations (`state Idle;`),
state bodies with `entry`/`do` actions, transitions (`accept Signal then Target`),
and `entry; then State` for the initial state. Each transition is stored as
`(from_state_name, signal_name, target_state_name)`.

**Part definitions:** For `part`/`part def` the parser extracts:
- **Attributes** — `attribute name : Type;` or `attribute name : Type { doc ... }` (name and type; type string may include `= default`).
- **Constants** — `constant name : Type = value;` (name, type, value string) for use in generated preamble.
- **Perform actions** — `perform action usageName : ActionDefType;` (links the part to PSM action defs).
- **Exhibit refs** — `exhibit stateMachineName;` (links part to the state machine it exhibits).
- **Textual representations** — `rep repName language "TypeScript" /* ... */` (name, language, body).

**Action definitions:** For `action def` the parser extracts **action_params**: each `in name : Type;` or `out name : Type;` (direction, name, type). Optional parameters use `[0..1]` in the type; the generator maps these to TypeScript optional params (`param?`). Presence of `in self;` marks the action as a class method rather than a free function.

### Graph Builder (`graph/builder.py`)

`build_model_graph` in `graph/builder.py` walks `ModelIndex` and constructs a
`ModelGraph`: a directed labelled graph where nodes are model elements and edges
represent typed relationships. Node **properties** are populated from the parser:
e.g. `attributes`, `constants`, `action_params`, `textual_representations`,
`perform_actions`, `transitions`, `entry_target`, `entry_action`, `do_action`.

**Edge labels:**

| Label              | Meaning                                        |
|--------------------|------------------------------------------------|
| `contains`         | Parent-child containment                       |
| `supertype`        | `:>` / `:` inheritance                         |
| `transition`       | State → state (carries `signal`, `signal_name`, `machine`) |
| `initial_transition` | State machine → initial state (`entry; then State`) |
| `entry_action`     | State → action (entry)                          |
| `do_action`        | State → action (do)                             |
| `performs`         | Part → action def (`perform action`; edge has `usage_name`) |
| `exhibit`          | Part def → state machine (part exhibits that state usage) |
| `satisfy`          | Requirement satisfaction                       |
| `expose`           | View → exposed element                         |
| `state_port`       | State → port type                              |

**Query helpers on `ModelGraph`:**

- `children(qname, kind=)` — direct children by containment
- `outgoing(qname, label=)` / `incoming(qname, label=)` — edge queries
- `descendants(qname, kind=)` — recursive containment
- `nodes_of_kind(kind)` — all nodes of a given kind
- `get(qname)` — lookup by qualified name

### Targets

Each target is a `GeneratorTarget` subclass registered via `@register_target`
in the `ci/generators/registry.py` module. Targets receive the `ModelGraph`
and `GenerationOptions`, and produce output artifacts.

## TypeScript Target

### Purpose

Generate a Node.js/TypeScript application skeleton from the PSM component
definitions and PIM state machines. The generated code mirrors the SysML
model structure: one module per PSM component, each implementing its state
machine with typed enums and signal-driven transitions.

### Component mapping

| PSM Part           | State Machine                          | Output File           |
|--------------------|----------------------------------------|-----------------------|
| MLLPReceiver       | mllpReceiver : MLLPReceiverStates      | `src/mllp_receiver.ts`|
| Parser             | hl7Handler : HL7HandlerStates          | `src/parser.ts`       |
| Transformer        | hl7Transformer : HL7TransformerStates  | `src/transformer.ts`  |
| HTTPForwarder      | httpForwarder : HTTPForwarderStates    | `src/http_forwarder.ts`|
| ErrorHandler       | errorHandler : ErrorHandlerStates      | `src/error_handler.ts`|
| HL7AdapterService  | hl7AdapterController                   | `src/adapter.ts`      |

### Generated structure

```
out/
  package.json         # Dependencies: hl7-standard, undici, pino
  tsconfig.json        # ES2022, Node16 modules, strict mode
  src/
    mllp_receiver.ts   # MllpReceiverState enum, MllpReceiver class
    parser.ts          # Hl7ParserState enum, Hl7Parser class
    transformer.ts     # Hl7TransformerState enum, Hl7Transformer class
    http_forwarder.ts  # HttpForwarderState enum, HttpForwarder class
    error_handler.ts   # ErrorHandlerState enum, ErrorHandler class
    adapter.ts         # AdapterState enum, HL7Adapter orchestrator
    index.ts           # Re-exports
```

### Assembly pipeline (named rep hooks + PSM action defs)

The TypeScript generator **always** produces an auto-generated skeleton from the
PIM state machine (enum, signals, config, class with dispatch). PSM part
definitions can carry **multiple named `rep` blocks** whose content is injected at
specific hook points during assembly, and **`perform action` usages** that pull
in implementations from PSM action defs. All TypeScript code resides exclusively
in the PSM; CIM and PIM remain technology-agnostic.

Performed actions are partitioned by the `in self;` convention:

- **No `in self`** -- emitted as module-level free functions (step 2)
- **Has `in self`** -- emitted as class methods inside the component class (step 10)

Assembly order:

1. Emit `textualRepresentation` rep body (module preamble: imports, constants, interfaces)
2. Emit performed action implementations **without** `in self` as free functions (in `perform` declaration order)
3. Emit skeleton standard imports (`EventEmitter`, `pino`) and logger
4. Emit auto-generated enum, signal type, config interface
5. Open class extending `EventEmitter`
6. Emit skeleton fields (`_state`, `_config`)
7. Inject `classMembers` rep body (extra field declarations)
8. Emit constructor, state getter
9. Emit `_dispatch()` (private) + `dispatch()` (public wrapper) -- or plain `dispatch()` when no method actions or method reps exist
10. Emit performed action implementations **with** `in self` as class methods, then any remaining named reps
11. Close class

PSM action defs live in `model/PSM/actions.sysml`. Each carries either a
`rep textualRepresentation` (full implementation, emitted verbatim) or a
`rep functionBody` (body-only): when `functionBody` is present, the generator
builds the function signature from the action's `in`/`out` parameters and wraps
the body (so the model defines the contract). CIM-mapped actions specialise
their CIM counterpart (e.g. `action def ParseMllpFrame :> ReceiveMLLPFrame`);
PSM-only helpers stand alone. Method actions declare `in self;` and use
`textualRepresentation` with the full method body.

When a PSM part has **no** reps and **no** performed actions, the generator
produces the skeleton only.
See [Embedded_Code_Syntax.md](Embedded_Code_Syntax.md) for the SysML rep syntax
and hook categories.

### How the state machine is automatically created

The TypeScript target **derives** the state machine from the model graph; no hardcoded state lists.

1. **Component → state machine binding**  
   The generator finds which state machine each component exhibits via **exhibit** edges. Part defs (and their supertype chain) are queried for `outgoing(qname, "exhibit")`; the target must be a state node. The adapter’s child parts are resolved to their part defs, then the exhibited state machine **usage name** (e.g. `mllpReceiver`, `hl7Handler`) is read from that state node. The component map is built entirely from the model (see `queries.get_component_map`, `_get_exhibited_state`).

2. **States**  
   For a state machine node (e.g. `PIM_Behavior::mllpReceiver`), **states** are the direct children of kind `state`: `graph.children(machine_qname, kind="state")`. State names are sorted and emitted as the enum members (e.g. `IDLE`, `LISTENING`, `RECEIVING`, `FRAME_COMPLETE`, `ERROR`). The **initial state** comes from the state machine node’s `entry_target` property (from `entry; then State` in the model).

3. **Transitions**  
   For each state child, the graph is queried for **transition** edges: `graph.outgoing(state_qname, "transition")`, plus transitions whose source is the state machine node itself. Each edge has `signal_name`, `from_state` (from edge source), and `to_state` (from edge target). These are collected, deduplicated by `(signal, from_state, to_state)`, and sorted. The result drives the nested `switch` in `dispatch()`: outer switch on current state, inner switch on signal, then assignment `this._state = ...` and break.

4. **Signal type**  
   The **signal type** is the union of all `signal_name` values that appear in those transitions (e.g. `'ListenerStartSignal' | 'MLLPFrameReceivedSignal' | ...`).

5. **Dispatch method**  
   The generator emits a `switch (this._state)` with one `case` per state; inside each case, a `switch (signal)` with one `case` per signal that triggers a transition from that state, setting `this._state` to the target state. After the state switch, it logs and emits `'transition'` when the state changed. If the component has method actions or extra named reps, a **private** `_dispatch` is emitted and a thin public `dispatch()` calls it so method code can call `this._dispatch(signal)`.

### How functions are built from actions

**Perform action** links a PSM part def to PSM **action defs**. Each action def may have:

- **action_params** — `in`/`out` parameters (dir, name, type), including optional `[0..1]`. The parameter named `self` is used only to decide placement (method vs free function).
- **Textual representations** — `rep textualRepresentation language "TypeScript"` (full body) or `rep functionBody language "TypeScript"` (body only).

**Placement:**

- **No `in self`** — The action is emitted as a **module-level free function** (step 2 of assembly). Used for helpers (e.g. `parseMllpFrame`, `buildAck`).
- **Has `in self`** — The action is emitted as a **class method** on the component class (step 10), after the constructor and `dispatch()`.

**Signature generation:**

- **Free function with `functionBody` rep:** The generator builds the signature from `action_params`: `in` params (except `self`) become function parameters; a single `out` param becomes the return type (otherwise `void`). Types are mapped via `_sysml_type_to_ts` (String→string, Integer→number, etc.; unknown types pass through when `pass_through_unknown=True`). Optional `[0..1]` becomes `param?`. The rep body is indented and placed inside the generated function.
- **Free function with only `textualRepresentation`:** The rep body is emitted verbatim (no generated signature).
- **Method:** Same as free function for params: `_build_method_params` builds the parameter list from `in` params (excluding `self`). The body is taken from `functionBody` or `textualRepresentation`; if it looks like a full method (e.g. `methodName(...): returnType { ... }`), the generator may strip the outer signature to avoid double-wrapping. `async` is inferred from `await` in the body; return type is `Promise<void>` or `void`.

**Body source:** For each performed action, the generator uses the action def’s TypeScript reps: it prefers `functionBody`, then falls back to `textualRepresentation`. If neither exists, the action is skipped.

### Constants, attributes, and config

- **Constants**  
  Part defs can declare **constants** in the model (`constant name : Type = value;`). The parser stores `(name, type, value)`; the graph node has `properties["constants"]`. The TypeScript target emits these in the **preamble** (before imports) as `export const NAME = value;`. The value string is normalized: numeric types keep the literal (or hex); quoted strings are kept; otherwise it is passed through. Names are converted to SCREAMING_SNAKE_CASE.

- **Attributes (config)**  
  Part def **attributes** (`attribute name : Type;` or with `doc`) are stored on the node as `properties["attributes"]` with `name` and `type`. The type string may include `= default` (e.g. `Integer = 2575`). For the TypeScript target:
  - **Config interface** — Each component’s part def attributes are collected by `_get_config_attributes`: the type is mapped with `_sysml_type_to_ts` (String→string, Integer→number, Boolean→boolean, etc.; unknown→string). The generator emits `export interface ComponentNameConfig { name: type; ... }`.
  - **Class fields** — The component class gets `private readonly _config: ComponentNameConfig` and the constructor assigns it. Config is not currently parsed for default values in the interface; defaults can be supplied in generated `config.json` (see `config.py`).

- **Preamble types (interfaces from the model)**  
  Part defs **referenced** by this component’s performed actions (via parameter types and type names in action rep bodies) are collected in dependency order. For each such part def the generator emits:
  - An **interface** if the part has attributes (each attribute → TS property; optional when type has `[0..1]` or `[*]`; type resolved to another preamble type or scalar).
  - A **type alias** if the part has a TypeScript rep body and no attributes (rep body used as the RHS).
  - A **union type** if the part has no attributes and multiple supertypes in the preamble set (`type X = A | B`).
  Part defs with both attributes and a TypeScript rep can supply the exact interface body from the rep. Types only referenced in rep bodies (e.g. `ParsedHL7`) are discovered by scanning the body for known part def short names.

### What each module contains (skeleton mode)

- **State enum** — One member per child state of the PIM state machine (from the graph), in sorted order; values are the state names (e.g. `IDLE = 'Idle'`).
- **Signal type** — Union of all signal names that appear on transition edges for that machine.
- **Config interface** — Typed configuration from the PSM part def’s attributes (name and mapped type only).
- **Component class** — Extends `EventEmitter`, holds `_state` and `_config`, constructor sets initial state from the state machine’s `entry_target`, implements `dispatch(signal)` (or `_dispatch` + `dispatch`) with the generated state machine switch.

### How transitions are mapped

The SysML pattern:

```
state Idle;
accept ListenerStartSignal
    then Listening;
```

is parsed into a transition `(Idle, ListenerStartSignal, Listening)`. The graph has an edge labelled `transition` from the Idle state node to the Listening state node, with properties `signal_name`, `signal`, `machine`. The generator collects all such edges and emits:

```typescript
case MllpReceiverState.IDLE:
  switch (signal) {
    case 'ListenerStartSignal':
      this._state = MllpReceiverState.LISTENING;
      break;
  }
```

## Running

### LaTeX target (existing)

```bash
python -m ci.generators --target latex --model-dir model --out out
```

### TypeScript target

```bash
python -m ci.generators --target typescript --model-dir model --out out/app
cd out/app && npm install && npx tsc
```

### List available targets

```bash
python -m ci.generators --list-targets
```

## Adding a new target

1. Create a subpackage under `ci/generators/targets/`, e.g. `targets/<target_name>/`, with an `__init__.py` that defines the `GeneratorTarget` subclass and a `@register_target` factory.
2. Implement `GeneratorTarget` with `generate(graph: ModelGraph, options: GenerationOptions) -> list[GeneratedArtifact]`.
3. Register with `@register_target` (from `ci.generators.registry`).
4. Import the target package in `ci/generators/__main__.py` inside `_build_registry()` (e.g. `from .targets import <target_name>`) so it registers when the CLI runs.

The target receives a `ModelGraph` with the full model and `GenerationOptions`
with output directory, version, and any CLI extras. A Python skeleton target
could be added under `targets/python/` using the same pattern (state enum/class,
dispatch, config from PSM).
