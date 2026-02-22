# RestApi Component Implementation — Review

**Issue:** RestApi component implementation — health, metrics, and dashboard data  
**Labels:** feature, PSM, implementation  
**Milestone:** Core Implementation  
**AIM reference:** Chapter 12 S12.7–12.9 (API access), Chapter 8 S8.5 (component configuration)

---

## 1. Where the implementation lives

- **Part definition:** `model/PSM/HL7AdapterService/RestApiComponent/component.sysml`  
  - Defines `PSM_RestApiComponent::RestApi` with `listenPort` (default 3000), `initializeFromBinding : InitializeRestApi`, and `getStatus : GetRestApiStatus`.
- **Performed actions:** `model/PSM/HL7AdapterService/RestApiComponent/actions.sysml`  
  - **InitializeRestApi:** Full TypeScript snippet for the HTTP server, `sendJson`, GET `/health`, GET `/metrics`, 404 for other routes, 500 on catch, `server.listen(port)`, and `this._dispatch('StartServerSignal')`.
  - **GetRestApiStatus:** Returns `{ status: this.state }` for inclusion in health.
- **Runtime:** Generated `out/typescript/src/rest_api.ts` contains the same logic (generated from the model). Implementation is syntactically valid and reflects the model.

Convention is satisfied: the runnable REST server implementation lives in the PSM model (RestApiComponent part def and its performed action defs).

---

## 2. GET /health — acceptance criteria

**Requirement:** Return 200 with JSON including overall status and per-component status where available.

- **Status:** Met, after the change below.
- **Behavior:**  
  - Response is 200 with `Content-Type: application/json`.  
  - Body includes:
    - **`status`:** Aggregate `'ready' | 'degraded'`, derived from ErrorHandler: `degraded` if `service.errorHandler.getStatus().status === 'degraded'`, else `'ready'`. *(This aggregate field was missing in the original model/runtime; it has been added to the model and the generated runtime.)*
    - **`components`:** `errorHandler`, `mllpReceiver`, `parser`, `transformer`, `httpForwarder`, `restApi`, each from the corresponding `service.<part>.getStatus()`.

---

## 3. GET /metrics — acceptance criteria

**Requirement:** Return 200 with JSON including message-flow and error metrics suitable for dashboard consumption.

- **Status:** Met.
- **Behavior:**  
  - Response is 200 with `Content-Type: application/json`.  
  - Body is `components.errorHandler` with: `errors_total`, `errors_parse_error`, `errors_validation_error`, `errors_connection_error`, `errors_timeout_error`, `errors_http_client_error`, `errors_http_server_error`, `messages_received`, `messages_parsed`, `messages_transformed`, `messages_delivered`.  
  - Data comes from `service.errorHandler.getMetrics()`. Structure matches the dashboard contract and is suitable for dashboards without extra transformation.

---

## 4. Dashboard data contract

- **Location:** `docs/RestApi_Dashboard_Contract.md`.
- **Content:** Documents guaranteed fields for GET `/health` (including `status` and `components`) and GET `/metrics` (including `components.errorHandler` counters), plus 404 for other routes. Component doc in `RestApiComponent` references this contract.
- **Optional combined endpoint:** Contract states that GET `/api/status` or GET `/api/dashboard` may be added later; not implemented here (acceptable).

---

## 5. RestApi startup and port

- **Wiring:** In `out/typescript/src/service.ts`, `initialize(config)` calls `this.restApi.initializeFromBinding(this)`, passing the service so RestApi can call `service.errorHandler.getStatus()`, `service.errorHandler.getMetrics()`, and other component accessors.
- **Port:** RestApi uses `this._config.listenPort ?? 3000` (model and runtime). Config is provided at construction (e.g. `config.restApi.listenPort` from the service config). RestApi listens on that port after `server.listen(port, ...)`.

---

## 6. State machine and lifecycle

- **PIM:** RestApi states in PIM are Initializing and Serving; transition to Serving on `StartServerSignal`.
- **Runtime:** `RestApiState` has `INITIALIZING` and `SERVING`; `_dispatch('StartServerSignal')` is called after `server.listen(...)` and transitions to `SERVING`. Transitions are logged and emitted via `this.emit('transition', { from, to, signal })`. No separate “Failed” state in PIM/PSM; failures in request handling result in 500 responses.

---

## 7. Tests

- **Verification in model:** `model/PSM/HL7AdapterService/RestApiComponent/verification.sysml` defines an action `actCreateAdapterInitializeAndQueryHealthMetricsAndUnknownRoute` with vitest code that:
  - Builds config with `REST_PORT = 38473`, creates `Hl7AdapterService`, calls `adapter.initialize(config)`.
  - Fetches GET `/health`, GET `/metrics`, and GET `/unknown`.
  - Asserts: health 200, `health.status` in `['ready','degraded']`, `health.components` with `errorHandler` and `restApi`; metrics 200, `metrics.components.errorHandler` with `errors_total`, `messages_received`, `messages_delivered`; unknown route 404.
- **Gap:** The vitest generator only emits tests for **verification def** nodes (see `ci/generators/targets/vitest/queries.py`). This RestApi verification is a package-level **action**, not a **verification def** with a subject. Therefore this scenario is not currently generated as a runnable test file.
- **Recommendation:** Add a verification def (e.g. `RestApiHealthMetricsTest` with subject `adapter : HL7AdapterService`) that invokes this action (or inlines the same steps), so the generator produces a test that runs in CI and covers health 200, metrics 200, and 404 for unknown routes.

---

## 8. Summary and changes made

| Criterion | Status |
|-----------|--------|
| Model contains full implementation (server, routes, responses) | Met |
| GET /health returns 200 with overall + per-component status | Met (aggregate `status` added in model and runtime) |
| GET /metrics returns 200 with message-flow and error metrics | Met |
| Dashboard data contract documented | Met (`docs/RestApi_Dashboard_Contract.md`) |
| RestApi started with service and listens on configured port | Met |
| State machine implemented and transitions observable | Met |
| Tests cover health, metrics, and 404 | Partially met (verification action exists; not emitted as test — add verification def to get runnable tests) |

**Changes applied during review:**

1. **Aggregate `status` on GET /health:** The contract and verification expect a top-level `status: 'ready' | 'degraded'`. The implementation previously returned only `components`. The model (`actions.sysml`) and the generated runtime (`rest_api.ts`) were updated to derive `status` from `service.errorHandler.getStatus().status` and include it in the health response.
2. **Recommendation:** Add a verification def in `RestApiComponent/verification.sysml` (or equivalent) so the RestApi health/metrics/404 scenario is generated as a runnable vitest and included in the test suite.

After the next TypeScript generation from the model, `out/typescript/src/rest_api.ts` should be regenerated so it stays in sync with the model; the manual edit to `rest_api.ts` was made to align the current codebase with the contract and verification until then.
