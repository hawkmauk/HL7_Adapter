package PSM_TechnologySelection {
    doc /* Technology trade studies for the HL7 Adapter PSM. Criteria are derived from PIM requirements (SYS1–SYS4) and from target environment (Lyrebird Health stack: TypeScript/Node.js backend, AWS, Terraform). Selections align with both PIM and the Lead Forward-Deployed Engineer role. */

    package LanguageRuntimeSelection {
        doc /* Trade study: language and runtime.
Criteria: HL7 library ecosystem, async I/O for MLLP and HTTP, operational fit, alignment with Lyrebird backend (TypeScript/Node.js).
Candidates: Python (python-hl7, aiohttp); Node.js/TypeScript (node-hl7-complete, axios/undici); Go (go-hl7, net/http).
Selection: Node.js/TypeScript.
Rationale: Aligns with Lyrebird’s backend stack and UK forward-deployment role; satisfies PIM (async ingestion, parsing, forwarding); strong npm ecosystem for HL7 and HTTP; TypeScript improves maintainability for integrations and config. Python and Go considered but deprioritised to match team stack and hiring context. */
    }

    package HL7ParserSelection {
        doc /* Trade study: HL7 parser library.
Criteria (from PIM Parser, SYS2.1–SYS2.5): MSH parsing and header metadata; PID and patient identifier extraction; deterministic handling of optional/repeated segments; character encoding normalisation to UTF-8/JSON; consistent policy for missing or malformed required fields.
Candidates: node-hl7-complete; hl7-standard (Node); python-hl7 (reference only).
Selection: node-hl7-complete (or equivalent Node-compatible HL7 library that meets criteria).
Rationale: Node-compatible parser that supports segment access, MSH/PID extraction, and encoding handling; evaluated against SYS2.x; fits chosen Node.js/TypeScript runtime. */
    }

    package HTTPClientSelection {
        doc /* Trade study: HTTP client for downstream REST forwarding.
Criteria (from PIM HTTPForwarder, SYS3.1–SYS3.5): modern TLS and cipher configuration; endpoint URL and certificate validation (fail closed); configurable method and headers; 2xx/4xx/5xx handling; configurable retry and timeout.
Candidates: axios; undici; node-fetch with retry/timeout wrappers.
Selection: axios or undici (TLS, retry, timeout support).
Rationale: Both support HTTPS, configurable timeouts, and retry patterns; align with Lyrebird backend; selection documented with rationale for TLS, retry policy, and timeout behaviour vs SYS3.x. */
    }

    package DeploymentModelSelection {
        doc /* Trade study: deployment model.
Criteria: operability, scaling, portability, alignment with Lyrebird infrastructure (AWS, Terraform).
Options: standalone process; container (Docker); serverless (e.g. Lambda).
Selection: AWS-backed deployment (Lambda + API Gateway or container on ECS/Fargate) with Terraform for Infrastructure as Code.
Rationale: Matches Lyrebird’s AWS and Terraform stack; supports forward deployment and customer-specific configurations; Terraform for repeatable, reviewable deployments. */
    }
}
