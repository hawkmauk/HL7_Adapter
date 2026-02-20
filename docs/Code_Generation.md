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
`constraint`, `use case`, `occurrence`, `action`, `state`, `attribute def`,
`item`, and signal declarations.

For state machines the parser extracts:

- Inline state declarations (`state Idle;`)
- State bodies with entry/do actions
- Transitions with source-state context (`accept Signal then Target`)
- State-machine port declarations (`in name : Type;`)

### Graph Builder (`graph/builder.py`)

`build_model_graph` in `graph/builder.py` walks `ModelIndex` and constructs a
`ModelGraph`: a directed labelled graph where nodes are model elements and edges
represent typed relationships.

**Edge labels:**

| Label              | Meaning                                        |
|--------------------|------------------------------------------------|
| `contains`         | Parent–child containment                       |
| `supertype`        | `:>` / `:` inheritance                         |
| `transition`       | `accept Signal then Target` (carries `signal_name`, `machine`) |
| `initial_transition` | `entry; then State`                          |
| `entry_action`     | State → action (entry)                         |
| `do_action`        | State → action (do)                            |
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

### What each module contains

- **State enum** — one member per child state of the PIM state machine
- **Signal type** — union of all signal names triggering transitions
- **Config interface** — typed configuration attributes from the PSM part definition
- **Component class** — extends `EventEmitter`, implements `dispatch(signal)` with a
  nested `switch` implementing the state machine transitions

### How transitions are mapped

The SysML pattern:

```
state Idle;
accept ListenerStartSignal
    then Listening;
```

maps to:

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
