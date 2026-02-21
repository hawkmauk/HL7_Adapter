# Embedding Code in the SysML v2 Model

SysML v2 allows embedding code (or other textual representations) in the model using a **textual representation** with a named **language**. The body is given in a `/* ... */` block.

---

## Syntax (corrected)

Use **`textualRepresentation`** (not "texturalRepresentation"). Three common patterns:

### 1. Representation on a constraint (assert)

```sysml
assert constraint x_constraint {
    rep inOCL language "ocl"
        /* self.x > 0.0 */
}
```

- **Keyword:** `rep <name> language "<language>"` then the body in `/* ... */`.
- **Example (from repo):** `agent/guides/sysml/src/examples/Simple Tests/TextualRepresentationTest.sysml`.

### 2. Inline language on an action def

```sysml
action def UpdateSensors {
    in sensors : Sensor[*];
    language "Alf"
        /*
         * for (sensor in sensors) {
         *     if (sensor.ready) { Update(sensor); }
         * }
         */
}
```

- **Keyword:** `language "<language>"` (no `rep` name) then the body in `/* ... */`.
- **Example (from repo):** `agent/guides/sysml/src/training/22. Opaque Actions/Opaque Action Example.sysml`.

### 3. PSM action defs (free function implementations)

Functions that are semantically actions (clear inputs, outputs, independently testable) are modelled as **PSM action defs** in `model/PSM/actions.sysml`. CIM-mapped actions specialise their CIM counterpart via `:>`; PSM-only helpers stand alone.

**Option A: Signature from the model, body-only rep.** Declare `in` and `out` parameters on the action def and use **`rep functionBody`** to hold only the inner statements (no `function` keyword or signature). The generator builds the TypeScript function signature from the action's in/out params and wraps the body.

```sysml
action def <BuildMllpMessage> 'Build MLLP Message' {
    in content : String;
    out buffer : Buffer;
    doc /* Wrap a content string in MLLP framing bytes. */
    rep functionBody language "TypeScript"
    /*
  const buf = Buffer.alloc(1 + Buffer.byteLength(content, 'utf8') + 2);
  let off = 0;
  buf[off++] = MLLP_START;
  off += buf.write(content, off, 'utf8');
  buf[off++] = MLLP_END_1;
  buf[off++] = MLLP_END_2;
  return buf;
    */
}
```

**Option B: Full implementation in rep.** Use **`rep textualRepresentation`** with the complete function (signature + body). The generator emits it verbatim. Use this when you prefer to hand-write the signature or when the action is a method (e.g. `in self`).

The PSM part definition connects to its actions via `perform action` usages:

```sysml
part def <MLLPReceiver> 'MLLP Receiver' :> PIM::LogicalArchitecture::MLLPReceiver {
    perform action parseMllpFrame : ParseMllpFrame;
    perform action buildAck : BuildAck;
    ...
}
```

The generator emits the TypeScript rep body from each performed action def as a **free function** in the generated module, in declaration order.

### 3b. Method actions (`in self;` convention)

Action defs that represent **class methods** (rather than free functions) declare an `in self;` parameter. The generator recognises this and emits the body as a class method (indented inside the class) instead of a module-level function. The `self` parameter is a modelling convention only -- it does not appear in the generated TypeScript signature.

```sysml
action def <StartReceiver> 'Start Receiver' {
    in self;
    doc /* Start the MLLP TCP listener and begin accepting connections. */
    rep textualRepresentation language "TypeScript"
    /*
start(): void {
  // ... method body using this._config, this._state, etc. ...
}
    */
}
```

The part definition references both free-function and method actions via `perform action` usages identically:

```sysml
part def <MLLPReceiver> 'MLLP Receiver' :> PIM::LogicalArchitecture::MLLPReceiver {
    perform action parseMllpFrame : ParseMllpFrame;   // free function (no in self)
    perform action start : StartReceiver;              // class method  (in self)
    ...
}
```

### 4. Named rep hooks on a part def (PSM implementation)

PSM part definitions carry non-action implementation code via **multiple named `rep` blocks**. The generator auto-produces a skeleton (state enum, signals, config, class with dispatch) from the PIM state machine and then injects the rep content at well-defined hook points.

Two hook categories are recognised by name:

| Rep name                | Injection point                                |
|-------------------------|------------------------------------------------|
| `textualRepresentation` | Module preamble (extra imports, constants, interfaces) -- emitted **before** action implementations and skeleton types |
| `classMembers`          | Additional class field declarations -- injected **after** skeleton fields, **before** constructor |

Class methods are now modelled as PSM action defs with `in self;` (see section 3b) rather than named rep hooks.

```sysml
part def <MLLPReceiver> 'MLLP Receiver' :> PIM::LogicalArchitecture::MLLPReceiver {
    doc /* ... */
    attribute bindHost : String { ... }
    ...

    perform action parseMllpFrame : ParseMllpFrame;
    perform action buildMllpMessage : BuildMllpMessage;
    perform action buildAck : BuildAck;
    perform action buildNak : BuildNak;
    perform action start : StartReceiver;
    perform action stop : StopReceiver;

    rep textualRepresentation language "TypeScript"
    /*
import * as net from 'net';
export const MLLP_START = 0x0b;
// ... constants, interfaces ...
    */

    rep classMembers language "TypeScript"
    /*
private _server: net.Server | null = null;
    */
}
```

- **Spelling:** `textualRepresentation` (not textural).
- **Language:** Any string is allowed; use `"TypeScript"` or `"typescript"` consistently.
- **Body:** Code inside `/* ... */`. Method action reps should contain full method declarations at zero indentation; the generator adds class-level indentation automatically.
- **CIM / PIM stay clean:** All TypeScript code resides exclusively in the PSM. The PIM state machine defines structure only; the CIM defines domain concepts.

When a PSM part has **no** named reps and **no** performed actions, the generator emits the skeleton only (enum, signals, config, class with `dispatch`). When method actions (or named method reps) are present, `dispatch` is generated as a `private _dispatch()` with a thin public `dispatch()` wrapper so that method code can call `this._dispatch()` internally.

See [Code_Generation.md](Code_Generation.md) for the full assembly pipeline.

---

## Your PSM usage

In `model/PSM/actions.sysml`, all MLLP Receiver behaviour is modelled as PSM action defs:

- **Free functions** (`parseMllpFrame`, `buildMllpMessage`, `buildAck`, `buildNak`) -- no `in self;` parameter, emitted at module level.
- **Class methods** (`start`, `stop`) -- declared with `in self;`, emitted inside the class body.

`ParseMllpFrame` specialises the CIM action `ReceiveMLLPFrame`.

In `model/PSM/physical_architecture.sysml`, the MLLP Receiver part def connects to all action defs via `perform action` usages and carries named reps (`textualRepresentation` for the preamble, `classMembers`). The generator assembles all sources to produce `out/src/mllp_receiver.ts`.

---

## Summary

| Context             | Syntax                                              | Body      |
|---------------------|-----------------------------------------------------|-----------|
| Constraint          | `rep <name> language "<lang>"`                      | `/* ... */` |
| Action def (opaque) | `language "<lang>"`                                 | `/* ... */` |
| PSM action def (signature from in/out) | `in`/`out` params + `rep functionBody language "<lang>"` | Body-only statements |
| PSM action def (full) | `rep textualRepresentation language "<lang>"` on `action def` | Full function/method |
| Part def (PSM)      | `rep <name> language "<lang>"` (multiple allowed)   | `/* ... */` |

Use **textualRepresentation** (one "u") and a space before the opening `/*`.
