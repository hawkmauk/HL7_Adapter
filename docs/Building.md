# Building

The script **`scripts/build.sh`** runs the code generators and then builds the resulting artifacts. It can be run from anywhere; it switches to the project root automatically.

## Usage

```bash
./scripts/build.sh <target>
```

## Targets

| Target       | What it does |
|-------------|----------------|
| `latex`     | Runs the LaTeX generator (`model/` → `out/latex/`), then builds PDFs and HTML with `pdflatex` and `make4ht`. Outputs go to `out/pdf/` and `out/html/`. Build intermediates (`.aux`, `.4ct`, etc.) are removed. |
| `typescript`| Runs the TypeScript generator (`model/` → `out/typescript/`), then runs `npm install`, `npm run build`, `npm run test`, and `npm run start` in the generated output directory. |

## Prerequisites

- **All targets:** Python 3 and the project’s generator dependencies (see `ci/generators/`).
- **`latex`:** `pdflatex` and `make4ht` (e.g. TeX Live and tex4ht).
- **`typescript`:** Node.js and npm (for install, build, test, and start in `out/typescript/`).

## Examples

```bash
./scripts/build.sh latex       # generate docs and build PDFs/HTML
./scripts/build.sh typescript  # generate TypeScript app, install, build, test, and start
```

## Running without Docker

To run the adapter from source instead of using the pre-built Docker image:

1. **Prerequisites:** Python 3 (for the generator), Node.js and npm.
2. **Generate and run the adapter:**
   ```bash
   ./scripts/build.sh typescript
   ```
   This generates the TypeScript app from the model into `out/typescript/`, runs `npm install`, `npm run build`, `npm run test`, and `npm run start`. The adapter listens for HL7 on MLLP (default port 2575) and posts transformed JSON to the URL in `config.json`.
3. **Optional — full demo:** Start the [demo HTTPS endpoint](../tests/https-endpoint/README.md) (e.g. `https://localhost:8080/api/v1/messages`), set `httpForwarder.baseUrl` and `tlsRejectUnauthorized: 0` in `out/typescript/config.json`, then run the [MLLP Emitter](../tests/mllp-emitter/README.md) to send HL7 messages to the adapter. JSON will be POSTed to the demo endpoint.

For config file location, config shape, operational store, and demo tools, see [Configuration](Configuration.md).
