package CIM {

    package Domain {
        doc /* Domain ontology for a local HL7 to HTTPS integration context. */
        private import ScalarValues::*;

        part def <HL7DeliveryConfirmation> 'HL7 Delivery Confirmation' {
            doc /* Conceptual representation of a confirmation of HL7 delivery to the adapter listener. */

            attribute controlId : String;
            attribute sentTimestamp : String;

        }

        part def <HL7Message> 'HL7 Message' {
            doc /* Conceptual representation of an inbound HL7 message (any version) in the integration context. */

            attribute messageType : String;
            attribute triggerEvent : String;
            attribute controlId : String;
            attribute sentTimestamp : String;

        }

        part def <MLLPFrame> 'MLLP Frame' {
            doc /* Transport framing envelope used to delimit HL7 payloads on TCP streams. */

            attribute startDelimiter : String;
            attribute endDelimiter : String;
            attribute payloadLength : Integer;

        }

        part def <PatientDemographics> 'Patient Demographics' {
            doc /* Conceptual patient data extracted from HL7 segments, such as PID content. */

            attribute patientId : String;
            attribute givenName : String;
            attribute familyName : String;
            attribute dateOfBirth : String;
            attribute gender : String;

        }

        part def <MessageMetadata> 'Message Metadata' {
            doc /* Conceptual metadata extracted from MSH fields, including trigger event type. */

            attribute sendingApplication : String;
            attribute sendingFacility : String;
            attribute receivingApplication : String;
            attribute receivingFacility : String;
            attribute sequenceNumber : String;

        }

        part def <JSONPayload> 'JSON Payload' {
            doc /* Structured payload produced from HL7 content and posted to a REST endpoint. */

            attribute payloadType : String;
            attribute schemaVersion : String;
            attribute body : String;

        }

        part def <RESTEndpoint> 'REST Endpoint' {
            doc /* Conceptual HTTP interface that receives transformed clinical event payloads. */

            attribute name : String;
            attribute resourcePath : String;
            attribute purpose : String;
            attribute interactionStyle : String;

        }

        part def <IntegrationError> 'Integration Error' {
            doc /* Any recoverable or non-recoverable operational issue during receive, parse, map, or forward. */

            attribute code : String;
            attribute messageText : String;
            attribute isRecoverable : Boolean;
            attribute occurredAt : String;

        }

        part def <ParseError> 'Parse Error' :> 'Integration Error' {
            doc /* Error caused by malformed HL7 structure or missing required fields. */

            attribute segmentId : String;
            attribute fieldPath : String;

        }

        part def <DeliveryError> 'Delivery Error' :> 'Integration Error' {
            doc /* Error caused by network, API availability, or unsuccessful HTTP response. */

            attribute statusCode : Integer;
            attribute endpointName : String;
            attribute attemptCount : Integer;

        }
    }

    package Stakeholders {
        doc /* Stakeholder and actor concepts interacting with or governing the integration. */

        part def <IntegrationEngineer> 'Integration Engineer' {
            doc /* Builds, configures, and maintains the adapter and local deployment. */
        }

        part def <ClinicalSystemOwner> 'Clinical System Owner' {
            doc /* Owns the upstream HL7-producing system and data quality expectations. */
        }

        part def <UpstreamHL7System> 'Upstream HL7 System' {
            doc /* External clinical system that publishes HL7 events to the receiver. */
        }

        part def <DownstreamAPIOwner> 'Downstream API Owner' {
            doc /* Owns the HTTP API that consumes transformed event payloads. */
        }

        part def <SecurityAndComplianceOfficer> 'Security and Compliance Officer' {
            doc /* Ensures patient data handling, transport security, and compliance obligations. */
        }

        part def <OperationsEngineer> 'Operations Engineer' {
            doc /* Monitors runtime health, failures, retries, and service continuity. */
        }
    }

    package Context {

        private import ScalarValues::*;
        private import ISQ::*;

        doc /* Operational context in which the adapter is used as a black-box service. */

        part def <HL7AdapterService> 'HL7 Adapter Service' {
            doc /* Conceptual service that receives HL7 via MLLP, transforms to JSON, and forwards to API. */

            attribute maxMllpFramePayloadSize : Integer = 4096;
        }

        part def <LocalDevelopmentEnvironment> 'Local Development Environment' {
            doc /* Local machine and process environment used for challenge execution and testing. */
        }

        part def <NetworkBoundary> 'Network Boundary' {
            doc /* Boundary separating MLLP ingress and HTTPS egress communication domains. */
        }

        part def <RuntimeConfiguration> 'Runtime Configuration' {
            doc /* Conceptual runtime settings such as host, port, endpoint URL, and security options. */
        }
    }

    package Operations {
        doc /* High-level operational activities and scenarios, kept technology-agnostic at CIM level. */

        private import ScalarValues::*;
        private import Domain::*;
        private import Events::*;

        action def <SendMLLPFrame> 'Send MLLP Frame' {
            doc /* Upstream actor publishes a framed HL7 event to the adapter listener. */
            in mllpFrame : MLLPFrame;
            out attribute success : Boolean;
        }

        action def <ReceiveMLLPFrame> 'Receive MLLP Frame' {
            doc /* Adapter accepts inbound framed data from a TCP connection. */
            out mllpFrame : MLLPFrame;
        }

        action def <ExtractHL7Message> 'Extract HL7 Message' {
            doc /* Extract the HL7 message from the MLLP frame. */
            in mllpFrame : MLLPFrame;
            out hl7Message : HL7Message;
            out attribute success : Boolean;
        }

        action def <TransformHL7Message> 'Transform HL7 Message' {
            doc /* Adapter maps selected HL7 fields into a stable JSON representation. */
            in hl7Message : HL7Message;
            out jsonPayload : JSONPayload;
            out attribute success : Boolean;
        }

        action def <SendJSONPayload> 'Send JSON Payload' {
            doc /* Adapter publishes a JSON event to a downstream API. */
            in jsonPayload : JSONPayload;
            out attribute success : Boolean;
        }

        action def <ReceiveJSONPayload> 'Receive JSON Payload' {
            doc /* Adapter receives a JSON event from a downstream API. */
            out jsonPayload : JSONPayload;
            out attribute success : Boolean;
        }

        action def <ReceiveIntegrationError> 'Receive Integration Error' {
            doc /* Adapter receives an integration error. */
            out integrationError : IntegrationError;
        }

        action def <HandleIntegrationError> 'Handle Integration Error' {
            doc /* Adapter handles an integration error. */
            in integrationError : IntegrationError;
        }

        /* Coarse-grained CIM-level flow for ingestion and forwarding. */
        action def <HandleMessage> 'Handle Message' {
            doc
            /* Main CIM-level flow from publish through receive, parse, transform, and post.
               Detailed protocol-specific behavior and error handling are refined in PIM behavior. */

            action receive : ReceiveMLLPFrame;
            action extract : ExtractHL7Message;
            action transform : TransformHL7Message;
            action publish : SendJSONPayload;
            action handleIntegrationError : HandleIntegrationError;

            first receive;
            then extract;
            if extract.success then transform; else handleIntegrationError;
            if transform.success then publish; else handleIntegrationError;
            then done;

            out attribute success : Boolean = extract.success and transform.success;
        }
    }

    package Events {

        private import ScalarValues::*;

        doc
        /* Event occurrences are the send/receive ends where messages are transacted between
           systems or components; actions in Operations are the behaviors that produce or
           consume those events (AIM S2.1, S7.5). Technology-agnostic; no protocol-specific payloads.
           Mapping: HL7MessageSent produced by PublishHL7Event (upstream), consumed at receive end
           by ReceiveHL7Event (adapter). HL7MessageReceived is that receive end. JSONMessageSent
           produced by PublishJSONEvent (adapter), consumed at receive end by ReceiveJSONEvent
           (downstream). Operations::HandleMessage is the adapter’s composite flow. */

        occurrence def <MLLPMessageSent> 'MLLP Frame Sent' {
            doc /* Send end of an HL7 message transaction. Produced by: PublishHL7Event (upstream). */
        }

        occurrence def <MLLPFrameReceived> 'MLLP Frame Received' {
            doc /* Receive end of an HL7 message transaction. Consumed by: ReceiveHL7Event (adapter). */
        }

        occurrence def <HL7MessageExtracted> 'HL7 Message Extracted' {
            doc /* Extracted the HL7 message from the MLLP message. */
            out attribute success : Boolean;
        }

        occurrence def <HL7MessageParsed> 'HL7 Message Parsed' {
            doc /* Parsed end of an HL7 message transaction. Consumed by: ParseHL7Message (adapter). */
            out attribute success : Boolean;
        }

        occurrence def <HL7MessageTransformed> 'HL7 Message Transformed' {
            doc /* Transformed end of an HL7 message transaction. Consumed by: TransformHL7Message (adapter). */
            out attribute success : Boolean;
        }

        occurrence def <JSONMessageSent> 'JSON Message Sent' {
            doc /* Send end of a JSON payload transaction. Produced by: PublishJSONEvent (adapter). */
        }

        occurrence def <JSONMessageReceived> 'JSON Message Received' {
            doc /* Receive end of a JSON payload transaction. Consumed by: ReceiveJSONEvent (downstream). */
        }

        occurrence def <IntegrationErrorSent> 'Integration Error Sent' {
            doc /* Send end of an integration error transaction. Produced by: HandleIntegrationError (adapter). */
        }

        occurrence def <IntegrationErrorReceived> 'Integration Error Received' {
            doc /* Receive end of an integration error transaction. Consumed by: HandleIntegrationError (adapter). */
        }
    }

    package UseCases {
        doc /* CIM-level use cases derived from the HandleMessage operation and event-centric message flows. */

        private import Stakeholders::*;
        private import Context::*;
        private import Domain::*;
        private import Operations::*;
        private import Mission::*;
        private import Events::*;

        /* Core use case that orchestrates the CIM operational story. */
        use case 'Ingest and Forward Event (CIM)' {

            subject adapterService : HL7AdapterService;

            actor upstreamSystem : UpstreamHL7System;
            actor downstreamApiOwner : DownstreamAPIOwner;
            actor operationsEngineer : OperationsEngineer;

            objective {
                doc
                /* Conceptual ingestion of an HL7Message and forwarding of a JSONPayload
                   from upstreamSystem to downstreamApiOwner via adapterService. */
            }

            include 'Send HL7 Message';
            include 'Receive HL7 Message';
            include 'Handle HL7 Message';
            include 'Send JSON Message';
        }

        /* CIM-level use cases decomposed from the main flow. */

        use case 'Send HL7 Message' {

            private import Domain::*;
            private import Events::*;

            subject upstreamSystem : UpstreamHL7System {
                event occurrence msgHL7MessageSent : MLLPMessageSent;
            }
            actor adapterService : HL7AdapterService{
                event occurrence msgHL7MessageReceived : MLLPMessageReceived;
            }
            message msgHL7Message of HL7Message
                from upstreamSystem.msgHL7MessageSent to adapterService.msgHL7MessageReceived;

            objective {
                doc
                /* Primary scenario
                   ----------------
                   upstreamSystem sends an HL7Message, framed in an MLLPFrame, towards adapterService.
                   - Domain: HL7Message, MLLPFrame, MessageMetadata.
                   - Mission: Reliable Event Ingestion (M1).

                   Alternate scenarios (still successful)
                   --------------------------------------
                   A1. Message with optional segments omitted
                       - HL7Message omits optional segments while still containing all mandatory content.
                       - Downstream parsing remains valid; no IntegrationError is raised.

                   A2. Large but acceptable payload
                       - HL7Message size approaches, but does not exceed, the conceptual maxPayloadSize for MLLPFrame.
                       - Message is still accepted for processing at CIM level.

                   A3. Multiple publishers
                       - Several UpstreamHL7System instances send HL7Message instances independently.
                       - Each message follows the same conceptual send interaction with adapterService. */
            }
        }

        use case 'Receive HL7 Message' {

            private import Domain::*;
            private import Events::*;

            subject adapterService : HL7AdapterService{
                event occurrence msgHL7MessageReceived : MLLPMessageReceived;
                event occurrence msgErrorSent : IntegrationErrorSent;
                event occurrence msgErrorReceived : IntegrationErrorReceived;
            }

            actor upstreamSystem : UpstreamHL7System {
                event occurrence msgHL7MessageSent : MLLPMessageSent;
            }
            message msgHL7Message of HL7Message
                from upstreamSystem.msgHL7MessageSent to adapterService.msgHL7MessageReceived;

            message msgError of IntegrationError
                from adapterService.msgErrorSent to adapterService.msgErrorReceived;

            action handleMessage : HandleMessage;

            first msgHL7Message;
            then handleMessage;
            if handleMessage.success then msgHL7Message; else msgError;
            then done;

            objective {
                doc
                /* Primary scenario
                   ----------------
                   adapterService conceptually receives and unwraps the framed HL7Message.
                   - Operation: ReceiveHL7Event.
                   - Domain: MLLPFrame, HL7Message.

                   Exception scenarios (receive stage)
                   -----------------------------------
                   E1. Oversized frame
                       - MLLPFrame.payloadLength exceeds the recommended maxPayloadSize.
                       - adapterService treats this as an IntegrationError case rather than proceeding to parse.

                   E2. Connection reset or timeout
                       - The conceptual connection between upstreamSystem and adapterService is broken mid-transfer.
                       - The partially received HL7Message is not processed further at CIM; an IntegrationError is recorded. */
            }
        }

        use case 'Handle HL7 Message' {

            subject adapterService : HL7AdapterService;

            action handleMessage : HandleMessage;

            first handleMessage;
            then done;

            objective {
                doc
                /* Primary scenario
                   ----------------
                   adapterService parses and transforms the HL7Message (ParseHL7Message, TransformHL7Message).
                   - Domain: HL7Message, PatientDemographics, MessageMetadata.
                   - Mission: Accurate Clinical Transformation (M2).

                   Alternate scenarios (parse stage)
                   --------------------------------
                   A1. Optional clinical segments omitted
                       - HL7Message lacks certain optional segments; required PatientDemographics and core fields are present.
                       - ParseHL7Message still succeeds; PatientDemographics may be partially populated.

                   A2. Additional non-critical segments present
                       - HL7Message contains extra segments not used by this adapter.
                       - These are ignored conceptually; validation focuses on required content.

                   Alternate scenarios (transform stage)
                   -------------------------------------
                   A1. Mapping with optional fields omitted
                       - Certain fields in JSONPayload are absent because corresponding HL7 segments were optional.
                       - Clinical meaning required for the mission is still preserved.

                   A2. Additional derived fields
                       - adapterService derives additional non-essential fields (e.g. summary fields) in JSONPayload.
                       - CIM notes their presence conceptually without prescribing implementation details.

                   Exception scenarios (parse stage)
                   --------------------------------
                   E3. Malformed header or segment structure
                       - HL7Message has an invalid structure (e.g. malformed MSH, inconsistent field separators).
                       - A ParseError is raised, linked to HL7Message and relevant segmentId/fieldPath.

                   E4. Missing mandatory patient data
                       - PatientDemographics lacks mandatory fields (e.g. patientId or dateOfBirth).
                       - ParseHL7Message fails validation and records a ParseError, leading to degraded handling. */
            }
        }

        use case 'Send JSON Message' {

            private import Domain::*;
            private import Events::*;

            subject adapterService : HL7AdapterService {
                event occurrence msgJSONMessageSent : JSONMessageSent;
            }
            actor downstreamApiOwner : DownstreamAPIOwner {
                event occurrence msgJSONMessageReceived : JSONMessageReceived;
            }
            message msgJSONMessage of JSONPayload
                from adapterService.msgJSONMessageSent to downstreamApiOwner.msgJSONMessageReceived;

            action publishJSONEvent : SendJSONPayload;

            first publishJSONEvent;
            then msgJSONMessage;
            then done;

            objective {
                doc
                /* Primary scenario
                   ----------------
                   adapterService posts the JSONPayload to a RESTEndpoint owned by downstreamApiOwner.
                   - Operation: PublishJSONEvent (adapter send); ReceiveJSONEvent (downstream receive).
                   - Domain: JSONPayload, RESTEndpoint.
                   - Mission: Secure Interoperability (M3).

                   Alternate scenarios (forward stage)
                   -----------------------------------
                   A1. Multiple logical endpoints
                       - RESTEndpoint represents a family of logical endpoints; adapterService selects one based on JSONPayload content.
                       - All selected endpoints conceptually satisfy the same handoff intent.

                   Exception scenarios (forward stage)
                   -----------------------------------
                   E5. Downstream temporary failure (e.g. 503)
                       - RESTEndpoint responds with a temporary failure; a DeliveryError is recorded.
                       - Subsequent handling is captured in Handle Integration Error (CIM).

                   E6. Network or connectivity failure
                       - Conceptual network issues prevent delivery (e.g. connection reset, timeout).
                       - A DeliveryError is raised; no successful handoff occurs.

                   E7. Security or policy failure
                       - Conceptual security/policy constraints (e.g. PHIHandlingPolicy) prevent forwarding.
                       - IntegrationError reflects the failure to meet M3/M4 obligations for this message. */
            }
        }

        use case 'Handle Integration Error (CIM)' {

            subject adapterService : HL7AdapterService;

            actor operationsEngineer : OperationsEngineer;

            action handleIntegrationError : HandleIntegrationError;

            first handleIntegrationError;
            then done;

            objective {
                doc
                /* Handle Integration Error (CIM) covers degraded scenarios conceptually
                   described by the HandleMessage operation, including ParseError and DeliveryError.
                   - Domain: IntegrationError, ParseError, DeliveryError.
                   - Mission: Operational Transparency (M4).

                   Example exception scenarios
                   --------------------------
                   E8. Accumulated retries exhausted
                       - DeliveryError.attemptCount indicates repeated unsuccessful attempts.
                       - adapterService ceases retrying and records a final IntegrationError.

                   E9. Persistently malformed input
                       - HL7Message instances repeatedly fail parsing for the same structural reason.
                       - IntegrationError highlights a likely configuration or upstream data quality problem. */
            }
        }

        /* Requirement satisfaction relationships from CIM use cases to mission requirements. */

        satisfy 'Reliable Event Ingestion' by 'Send HL7 Message';
        satisfy 'Accurate Clinical Transformation' by 'Handle HL7 Message';
        satisfy 'Secure Interoperability' by 'Send JSON Message';
        satisfy 'Operational Transparency' by 'Handle Integration Error (CIM)';
    }

    package Mission {
        doc /* Mission intent and stakeholder-oriented outcome statements for challenge scope. */

        requirement <M1> 'Reliable Event Ingestion' {
            doc /* The solution shall consistently ingest framed HL7 events from a local sender. */
        }

        requirement <M1_1> 'M1.Ingestion Reliability' {
            doc /* The solution shall ingest well-formed HL7 messages without loss under nominal load, including reconnects and benign upstream variability, in order to uphold the Reliable Event Ingestion mission intent (M1). */
        }

        requirement <M1_2> 'M1.Connection Handling' {
            doc /* The solution shall accept, maintain, and gracefully close multiple concurrent MLLP connections, including handling mid-stream disconnects and timeouts without corrupting or losing unrelated message streams, in support of M1. */
        }

        requirement <M1_3> 'M1.Framing Validation' {
            doc /* The solution shall validate MLLP framing (start/end delimiters and payload length) for each HL7 message and reject, quarantine, or flag frames with structural violations rather than silently processing them, in support of M1. */
        }

        requirement <M1_4> 'M1.Backpressure and Flow Control' {
            doc /* The solution shall apply backpressure or flow control when downstream parsing or posting is slower than inbound message arrival, so that messages are not dropped or corrupted and upstream systems can adapt send rates, in support of M1. */
        }

        requirement <M1_5> 'M1.Acknowledgement Behavior' {
            doc /* The solution shall return HL7 delivery confirmations or equivalent ACK behavior that clearly indicates acceptance, rejection, or retryable failure for each ingested message, so that upstream systems can make reliable delivery decisions in support of M1. */
        }

        requirement <M1_6> 'M1.Performance Envelope' {
            doc /* The solution shall sustain a specified throughput and latency envelope for ingestion and parse (for example, at least N messages per second at steady state with median parse latency below T milliseconds and bounded retry timing), with actual thresholds to be defined in PIM and verified against M1 Measures of Effectiveness. */
        }

        requirement <M2> 'Accurate Clinical Transformation' {
            doc /* The solution shall preserve key clinical identifiers and message semantics during mapping to JSON. */
        }

        requirement <M2_1> 'M2.Field Mapping Accuracy' {
            doc /* The solution shall map required HL7 fields (such as patient identifiers, encounter identifiers, event type, and timestamps) to JSON payload fields with a specified correctness rate (for example, >99.5 percent correct mappings on a representative test set), in support of M2. */
        }

        requirement <M2_2> 'M2.Segment and Optional Field Handling' {
            doc /* The solution shall handle optional and repeated HL7 segments deterministically, ignoring non-essential content while still preserving required clinical meaning, and shall specify which segments and fields are in-scope for mapping, in support of M2. */
        }

        requirement <M2_3> 'M2.Character Encoding and Normalization' {
            doc /* The solution shall correctly interpret and normalize HL7 character encodings into a canonical JSON representation (for example, UTF-8) without introducing data corruption, mojibake, or loss of clinically relevant symbols, in support of M2. */
        }

        requirement <M2_4> 'M2.Missing-Field Policy' {
            doc /* The solution shall define and apply a consistent policy when required HL7 fields are missing or malformed (for example, mark JSON fields as null, substitute safe defaults, or reject the message) and shall surface these conditions to downstream systems or operators, in support of M2. */
        }

        requirement <M2_5> 'M2.Transformation Performance' {
            doc /* The solution shall perform HL7-to-JSON transformation within a bounded latency budget per message under expected load (for example, median transform time below T milliseconds and 95th percentile below T95), so that clinical event flows remain timely in support of M2. */
        }

        requirement <M3> 'Secure Interoperability' {
            doc /* The solution shall forward transformed payloads over HTTPS to a downstream API. */
        }

        requirement <M3_1> 'M3.TLS Protection' {
            doc /* The solution shall use modern TLS versions and cipher configurations appropriate to the deployment region to protect payloads in transit between the adapter and downstream endpoints, in support of M3. */
        }

        requirement <M3_2> 'M3.Endpoint Authentication' {
            doc /* The solution shall authenticate downstream REST endpoints (for example, via server certificates, mutual TLS, or equivalent mechanisms) and shall fail closed when identity cannot be established, in support of M3. */
        }

        requirement <M3_3> 'M3.PHI Minimization and Regional Compliance' {
            doc /* The solution shall minimize the Protected Health Information (PHI) included in outbound payloads to what is needed for the clinical use case and shall support configuration or deployment profiles to meet regional data protection obligations (for example, HIPAA in the USA, GDPR in the EU, PIPEDA/PHIPA in Canada, PIPL in China, and ABDM/DPDP in India), in support of M3. */
        }

        requirement <M3_4> 'M3.Audit Logging' {
            doc /* The solution shall produce audit-appropriate records for security- and privacy-relevant events (such as access to PHI fields, failed authentications, and cross-region data transfers) with sufficient detail to support regulatory investigations across jurisdictions, in support of M3. */
        }

        requirement <M4> 'Operational Transparency' {
            doc /* The solution shall expose meaningful error outcomes for failed parsing or forwarding attempts. */
        }

        requirement <M4_1> 'M4.Error Classification' {
            doc /* The solution shall classify integration errors into clear categories (for example, parse errors, delivery errors, configuration errors, and upstream data-quality issues) so that operators can quickly determine impact and remediation, in support of M4. */
        }

        requirement <M4_2> 'M4.Structured Logging' {
            doc /* The solution shall emit structured logs for normal and error paths with stable field names (such as correlation IDs, message identifiers, and error codes) suitable for ingestion into log analysis tooling, in support of M4. */
        }

        requirement <M4_3> 'M4.Metrics and Health Signals' {
            doc /* The solution shall expose operational metrics (for example, message throughput, success/error rates, retry counts, and latency percentiles) and health indicators in a form consumable by monitoring systems, in support of M4. */
        }

        requirement <M4_4> 'M4.Alerting Hooks' {
            doc /* The solution shall provide mechanisms for integrating with alerting workflows (for example, thresholds on error rates, latency, or connectivity failures) so that operations engineers receive timely notifications of degraded conditions, in support of M4. */
        }

        /* Measures of Effectiveness (MoEs) for each mission requirement. */

        requirement <M1_MoE1> 'M1.MoE.Ingestion Success Rate' {
            doc /* Over a representative 24-hour test window with well-formed messages and expected load, at least 99.9 percent of HL7 messages offered to the adapter shall be ingested and either successfully acknowledged or deterministically rejected without silent loss, measuring effectiveness of M1. */
        }

        requirement <M2_MoE1> 'M2.MoE.Mapping Correctness' {
            doc /* On a curated validation dataset of HL7 messages, at least 99.5 percent of required clinical fields shall be correctly mapped into JSON payloads (no incorrect values or missing required mappings), measuring effectiveness of M2. */
        }

        requirement <M3_MoE1> 'M3.MoE.Secure Delivery Coverage' {
            doc /* For in-scope deployment regions (for example, USA, EU, Canada, China, and India), 100 percent of configured production endpoints shall enforce TLS-based transport security and endpoint authentication consistent with applicable regional regulations, with no detected clear-text PHI leakage in test scenarios, measuring effectiveness of M3. */
        }

        requirement <M4_MoE1> 'M4.MoE.Error Observability' {
            doc /* In integration testing that induces representative failure modes, at least 99 percent of non-transient integration errors shall be observable via structured logs, metrics, or alerts within an agreed detection time window (for example, under five minutes), measuring effectiveness of M4. */
        }

    }

    package Assumptions {
        doc /* Non-design assumptions and constraints shaping the challenge solution space. */

        constraint def <LocalExecutionOnly> 'Local Execution Only' {
            doc /* System execution is limited to a local development environment for the exercise. */
        }

        constraint def <MLLPTransportRequired> 'MLLP Transport Required' {
            doc /* HL7 transport from publisher to receiver uses Minimal Lower Layer Protocol framing. */
        }

        constraint def <HTTPSForwardingRequired> 'HTTPS Forwarding Required' {
            doc /* Outbound payload delivery uses an HTTPS REST endpoint interface. */
        }

        constraint def <LimitedScopeTesting> 'Limited Scope Testing' {
            doc /* Verification scope includes representative and limited test cases rather than full certification coverage. */
        }

        constraint def <PHIHandlingPolicy> 'PHI Handling Policy' {
            doc /* Patient-related data must be handled in a manner consistent with security and compliance expectations. */
        }
    }

    package LifecycleAlignment {
        doc /* CIM lifecycle gate alignment for stakeholder consensus before progression to PIM. */

        private import MDA::Lifecycle::*;
        private import MDA::Structure::*;

        part cimConsensusMilestone : CIMConsensusGateway;
        part cimGatewayCheck : GatewayCheck;
        part cimSignoffRecord : SignoffRecord;

        part customer : Customer;
        part projectManager : ProjectManager;
        part systemsEngineer : SystemsEngineer;
        part complianceOfficer : ComplianceOfficer;
        part operationsOwner : OperationsOwner;
    }
}
