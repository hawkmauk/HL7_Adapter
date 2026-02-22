## HL7 Adapter – Model-Driven Architecture Workspace

[![Release docs](https://github.com/hawkmauk/HL7_Adapter/actions/workflows/release-docs.yml/badge.svg)](https://github.com/hawkmauk/HL7_Adapter/actions/workflows/release-docs.yml)
[![Build docs](https://github.com/hawkmauk/HL7_Adapter/actions/workflows/build-docs.yml/badge.svg)](https://github.com/hawkmauk/HL7_Adapter/actions/workflows/build-docs.yml)

This project is a **proof of concept** for a **Digital Thread**: the **model** is the single source of truth, and we generate both documentation and the executable adapter from it. For the full picture (MDA levels, repository structure, how we develop), see [Digital Thread and MDA](docs/Digital_Thread_and_MDA.md).

### How to run locally

The easiest way to see the demo is to run the pre-built Docker image (adapter, dashboard, MLLP emitter, and HTTPS endpoint in one container):

```bash
docker pull ghcr.io/hawkmauk/hl7-adapter:latest
docker run -p 3000:3000 -p 2575:2575 -p 8080:8080 -p 8081:8081 ghcr.io/hawkmauk/hl7-adapter:latest
```

Launch the [dashboard](http://localhost:8081)

Ports: adapter REST API **3000**, MLLP **2575**, HTTPS endpoint **8080**, dashboard **8081**. To run from source (without Docker), see [Building](docs/Building.md).

### How it works

1. **HL7 publisher** — A sender (e.g. the [MLLP Emitter](tests/mllp-emitter/README.md)) publishes HL7 messages over TCP using MLLP framing (start 0x0B, end 0x1C 0x0D).
2. **Receiver** — The adapter’s MLLP receiver listens on a configurable port (e.g. 2575), accepts MLLP-framed messages, and returns ACK/NAK per HL7.
3. **Parse and transform** — The adapter parses the HL7 message (MSH, PID, etc.), maps key fields (patient ID, name, DOB, message type), and produces a structured JSON payload.
4. **POST to REST API** — The adapter sends that JSON via POST to a configurable HTTPS endpoint (e.g. `https://localhost:8080/api/v1/messages`).
5. **Error handling** — Parse failures, validation errors, and delivery failures are classified, logged, and reflected in metrics and health; the operational store records message lifecycle and errors for audit.

All of this (structure, behaviour, requirements) is defined in the **model**; the executable is **generated** from the model, so the architecture and the implementation stay in sync.

### Trade-offs

We chose **maintainability and flexibility over speed**. A lot of effort went into demonstrating a **repeatable delivery model** (model as single source of truth, generated docs, generated code, traceability) rather than delivering a one-off integration. As a result, some important production-oriented features are **not yet implemented**:

- **REST API authentication** — The health and metrics endpoints are unauthenticated. For production, they should be protected (e.g. API keys, mTLS, or integration with an IdP).
- **Encryption of data at rest** — The operational store (SQLite/PostgreSQL) does not currently encrypt persisted data. Sensitive payloads and audit data should be encrypted at rest in a production deployment.
- **GDPR-style capabilities** — Subject access requests (information requests) and right to erasure (“right to be forgotten”) are not implemented. The **requirements are still recorded in the model** (e.g. CIM/PIM requirements for data subject rights and retention); they would show as **not yet satisfied** in SysML analytics or traceability views, and can be implemented in a later phase without changing the architecture.

These gaps are intentional for this proof of concept: the **model** carries the full set of requirements and design, so we can see what is missing and prioritise it when moving toward production.

### Ideas for improving reliability in production

- **Authentication and authorisation** on the RestApi (health, metrics, message/error queries) and optionally on the downstream HTTPS endpoint side.
- **Encryption at rest** for the operational store and any stored message content or PII.
- **Implement GDPR-related behaviour** (subject access, erasure, retention policies) as specified in the model.
- **Stricter TLS and certificate validation** in production (no disabling verification); consider mTLS for adapter-to-downstream and for RestApi.
- **Rate limiting and backpressure** on the MLLP listener and on outbound POST to avoid overwhelming the downstream API.
- **Structured logging and correlation IDs** across the pipeline for debugging and audit.
- **Automated tests** (including integration tests with real MLLP and HTTPS) run in CI on every pull request; the model already drives unit tests via verification cases.

### Example HL7 message and sample API output

**Sample HL7 message (ADT^A01):**

```
MSH|^~\&|SENDING_APP|SENDING_FAC|RECEIVING_APP|RECEIVING_FAC|20260218120000||ADT^A01|MSG_001|P|2.5
EVN|A01|20260218120000
PID|1||PAT_12345^^^HOSP^MR||Doe^Jane^^^Ms||19850315|F|||123 Main St^^Anytown^CA^90210^^M||(555)123-4567|(555)987-6543||S||123456789
```

**Sample JSON payload** (as sent by the adapter via POST to the downstream API, e.g. `https://localhost:8080/api/v1/messages`):

```json
{
  "messageType": "ADT^A01",
  "messageControlId": "MSG_001",
  "patientId": "PAT_12345^^^HOSP^MR",
  "patientName": "Doe^Jane^^^Ms",
  "dateOfBirth": "19850315"
}
```

The operational store and internal flows use a richer **metadata** and **demographics** view (sending/receiving app/facility, given/family name, gender); the current PSM transformer sends this flat JSON to the downstream API. The model defines both the logical shape and the mapping from HL7 segments.

### Documentation

- [Digital Thread and MDA](docs/Digital_Thread_and_MDA.md)
- [CI/CD](docs/CI_CD.md)
- [Building](docs/Building.md)
- [Configuration](docs/Configuration.md)
- [Rest API](docs/RestApi_Dashboard_Contract.md)
- [Software Development Lifecycle](docs/Software_Development_Lifecycle.md)
- [Blog](docs/blog/README.md)

Generated docs (HTML and PDF) are also published on **GitHub Pages**: [https://hawkmauk.github.io/HL7_Adapter/](https://hawkmauk.github.io/HL7_Adapter/).
