package PIM_Requirements {
    doc /* PIM-level system requirements SYS1-SYS4 and their sub-requirements. Decomposed per AIM S6.3/S7.8; traceability to logical blocks and CIM mission in PIM_Allocations. */

    /* -----------------------------------------------------------------------
     * SYS1 — Reliable Event Ingestion (PIM)
     * ----------------------------------------------------------------------- */

    requirement <SYS1> 'SYS1.Reliable Event Ingestion' {
        doc /* The adapter shall consistently ingest framed HL7 events from upstream and pass them to parsing/transformation. Refines CIM M1. */
    }

    requirement <SYS1_1> 'SYS1.1.MLLP Framing Validation' {
        doc /* The adapter shall validate MLLP framing (start/end delimiters and payload length) for each frame and reject or flag structural violations. Derives from CIM M1_3. Satisfied by MLLPReceiver. */
    }

    requirement <SYS1_2> 'SYS1.2.Connection Lifecycle' {
        doc /* The adapter shall accept, maintain, and gracefully close MLLP connections and handle disconnects and timeouts without corrupting unrelated message streams. Derives from CIM M1_2. Satisfied by MLLPReceiver. */
    }

    requirement <SYS1_3> 'SYS1.3.Backpressure Handling' {
        doc /* The adapter shall apply backpressure or flow control when downstream parsing or forwarding is slower than inbound arrival. Derives from CIM M1_4. Satisfied by MLLPReceiver and HL7AdapterService. */
    }

    requirement <SYS1_4> 'SYS1.4.ACK Generation' {
        doc /* The adapter shall return delivery confirmations or ACK behavior indicating acceptance, rejection, or retryable failure per message. Derives from CIM M1_5. Satisfied by MLLPReceiver and HL7AdapterService. */
    }

    requirement <SYS1_5> 'SYS1.5.Ingestion Reliability' {
        doc /* The adapter shall ingest well-formed HL7 messages without loss under nominal load. Derives from CIM M1_1. Satisfied by MLLPReceiver. */
    }

    /* -----------------------------------------------------------------------
     * SYS2 — Accurate Clinical Transformation (PIM)
     * ----------------------------------------------------------------------- */

    requirement <SYS2> 'SYS2.Accurate Clinical Transformation' {
        doc /* The adapter shall preserve key clinical identifiers and message semantics during HL7-to-JSON mapping. Refines CIM M2. */
    }

    requirement <SYS2_1> 'SYS2.1.MSH Parsing' {
        doc /* The adapter shall parse MSH segment and map required header fields to internal metadata. Derives from CIM M2_1. Satisfied by Parser. */
    }

    requirement <SYS2_2> 'SYS2.2.PID Extraction' {
        doc /* The adapter shall extract PID (and required patient identifiers) deterministically for mapping to JSON. Derives from CIM M2_1/M2_2. Satisfied by Parser. */
    }

    requirement <SYS2_3> 'SYS2.3.Segment Iteration' {
        doc /* The adapter shall handle optional and repeated HL7 segments deterministically and specify in-scope segments for mapping. Derives from CIM M2_2. Satisfied by Parser. */
    }

    requirement <SYS2_4> 'SYS2.4.Character Encoding Handling' {
        doc /* The adapter shall interpret and normalize HL7 character encodings to a canonical JSON representation (e.g. UTF-8) without corruption. Derives from CIM M2_3. Satisfied by Parser. */
    }

    requirement <SYS2_5> 'SYS2.5.Missing-Field Default Policy' {
        doc /* The adapter shall apply a consistent policy for missing or malformed required fields (e.g. null, safe defaults, or reject) and surface to operators. Derives from CIM M2_4. Satisfied by Parser. */
    }

    /* -----------------------------------------------------------------------
     * SYS3 — Secure Interoperability (PIM)
     * ----------------------------------------------------------------------- */

    requirement <SYS3> 'SYS3.Secure Interoperability' {
        doc /* The adapter shall forward transformed payloads over HTTPS to a downstream API with appropriate security. Refines CIM M3. */
    }

    requirement <SYS3_1> 'SYS3.1.TLS Configuration' {
        doc /* The adapter shall use modern TLS versions and cipher configurations for outbound HTTPS. Derives from CIM M3_1. Satisfied by HTTPForwarder. */
    }

    requirement <SYS3_2> 'SYS3.2.Endpoint URL Validation' {
        doc /* The adapter shall validate and authenticate downstream REST endpoint URLs (e.g. server certs, mutual TLS) and fail closed when identity cannot be established. Derives from CIM M3_2. Satisfied by HTTPForwarder. */
    }

    requirement <SYS3_3> 'SYS3.3.HTTP Method and Headers' {
        doc /* The adapter shall use specified HTTP method and headers for posting payloads (e.g. POST, Content-Type, auth headers). Derives from CIM M3_2. Satisfied by HTTPForwarder. */
    }

    requirement <SYS3_4> 'SYS3.4.Response Code Handling' {
        doc /* The adapter shall handle HTTP response codes (2xx success, 4xx/5xx errors) and map to delivery success or failure signals. Derives from CIM M3. Satisfied by HTTPForwarder. */
    }

    requirement <SYS3_5> 'SYS3.5.Retry Policy' {
        doc /* The adapter shall apply a configurable retry policy for transient failures (e.g. 503, network errors) with bounded attempts. Derives from CIM M3. Satisfied by HTTPForwarder. */
    }

    requirement <SYS3_6> 'SYS3.6.Regional Compliance Profile' {
        doc /* The adapter shall support configuration or deployment profiles that align with regional data protection obligations (e.g. HIPAA in the USA, GDPR in the EU) as refined from CIM M3.3. Satisfied by HL7AdapterService. */
    }

    /* -----------------------------------------------------------------------
     * SYS4 — Operational Transparency (PIM)
     * ----------------------------------------------------------------------- */

    requirement <SYS4> 'SYS4.Operational Transparency' {
        doc /* The adapter shall expose meaningful error outcomes and operational visibility for parsing and forwarding. Refines CIM M4. */
    }

    requirement <SYS4_1> 'SYS4.1.Error Classification Taxonomy' {
        doc /* The adapter shall classify integration errors into clear categories (parse, delivery, configuration, data-quality) for operator impact and remediation. Derives from CIM M4_1. Satisfied by ErrorHandler. */
    }

    requirement <SYS4_2> 'SYS4.2.Structured Log Format' {
        doc /* The adapter shall emit structured logs with stable field names (correlation IDs, message IDs, error codes) for log analysis tooling. Derives from CIM M4_2. Satisfied by ErrorHandler. */
    }

    requirement <SYS4_3> 'SYS4.3.Metrics Counters' {
        doc /* The adapter shall expose metrics (success/failure/retry counts, throughput, latency percentiles) consumable by monitoring systems. Derives from CIM M4_3. Satisfied by ErrorHandler. */
    }

    requirement <SYS4_4> 'SYS4.4.Health-Check Endpoint' {
        doc /* The adapter shall provide a health-check endpoint or signal indicating operational readiness. Derives from CIM M4_3. Satisfied by HL7AdapterService and ErrorHandler. */
    }

    requirement <SYS4_5> 'SYS4.5.Alerting Hooks' {
        doc /* The adapter shall support integration with alerting workflows (thresholds on error rates, latency, connectivity) for operations engineers. Derives from CIM M4_4. Satisfied by ErrorHandler. */
    }

    /* -----------------------------------------------------------------------
     * SYS5 — Operational Data Store / Message Audit (PIM)
     * ----------------------------------------------------------------------- */

    requirement <SYS5> 'SYS5.Operational Data Store' {
        doc /* The adapter shall persist an audit trail of incoming MLLP frames and HL7 messages (lifecycle status), delivery attempts, and integration errors, and expose queryable APIs for message status and error history (AIM S12.7–12.9). Refines CIM M3_4 and M4. */
    }

    requirement <SYS5_1> 'SYS5.1.Message Lifecycle Persistence' {
        doc /* The adapter shall persist message lifecycle state (received, parsed, transformed, delivered, failed) for each ingested frame/message. Derives from CIM M3_4, M4. Satisfied by OperationalStore. */
    }

    requirement <SYS5_2> 'SYS5.2.Queryable Message Status' {
        doc /* The adapter shall expose queryable message status and delivery attempt history (e.g. via REST). Derives from CIM M3_4, M4. Satisfied by OperationalStore and RestApi. */
    }

    requirement <SYS5_3> 'SYS5.3.Queryable Error History' {
        doc /* The adapter shall expose queryable error history (message_id, error_class, detail, timestamp) for operators. Derives from CIM M4. Satisfied by OperationalStore and RestApi. */
    }
}
