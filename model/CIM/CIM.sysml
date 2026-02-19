package CIM {

    package Domain {
        doc /* Domain ontology for a local HL7 to HTTPS integration context. */
        private import ScalarValues::*;
        private import Events::*;

        abstract part def <SensitiveData> 'Sensitive Data' {
            doc /* Sensitive data that is not to be exposed to the system. */
        }

        part def <Observable> 'Observable' {
            doc /* Observable part that can be observed by the system. */
            event occurrence created : Created;
        }

        part def <HL7DeliveryConfirmation> 'HL7 Delivery Confirmation' {
            doc /* Conceptual representation of a confirmation of HL7 delivery to the adapter listener. */

            attribute controlId : String;
            attribute sentTimestamp : String;

        }

        part def <HL7Message> 'HL7 Message' :> 'Observable' {
            doc /* Conceptual representation of an inbound HL7 message (any version) in the integration context. */

            attribute messageType : String;
            attribute triggerEvent : String;
            attribute controlId : String;
            attribute sentTimestamp : String;
            attribute rawMessage : SensitiveData;

        }

        part def <MLLPFrame> 'MLLP Frame' :> 'Observable' {
            doc /* Transport framing envelope used to delimit HL7 payloads on TCP streams. */

            attribute startDelimiter : String;
            attribute endDelimiter : String;
            attribute payloadLength : Integer;

        }

        part def <PatientDemographics> 'Patient Demographics' {
            doc /* Conceptual patient data extracted from HL7 segments, such as PID content. */

            attribute patientId : String;
            attribute givenName : SensitiveData;
            attribute familyName : SensitiveData;
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

        part def <JSONPayload> 'JSON Payload' :> 'Observable' {
            doc /* Structured payload produced from HL7 content and posted to a REST endpoint. */

            attribute payloadType : String;
            attribute schemaVersion : String;
            attribute body : SensitiveData;

        }

        part def <RESTEndpoint> 'REST Endpoint' {
            doc /* Conceptual HTTP interface that receives transformed clinical event payloads. */

            attribute name : String;
            attribute resourcePath : String;
            attribute purpose : String;
            attribute interactionStyle : String;

        }

        part def <IntegrationError> 'Integration Error' :> 'Observable' {
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

    package Events {

        private import ScalarValues::*;
        private import Domain::*;

        doc
        /* Event occurrences represent technology‑agnostic send/receive points for messages
           between systems or components at CIM level (AIM S2.1, S7.5). The specific actions
           that produce or consume each event are documented on the individual occurrences. */

        occurrence def Created {
            doc /* This event will be used by Observable domain objects to signal their creation.
            It is the first of what could be many lifecycle events that could be raised by the object. */
        }

        occurrence def <MLLPFrameSent> 'MLLP Frame Sent' {
            doc /* Send end of an MLLP frame transaction. Produced by: SendMLLPFrame (upstream). */
        }

        occurrence def <MLLPFrameReceived> 'MLLP Frame Received' {
            doc /* Receive end of an MLLP frame transaction. Consumed by: ReceiveMLLPFrame (adapter). */
        }

        occurrence def <HL7MessageTransformed> 'HL7 Message Transformed' {
            doc /* Transformed end of an HL7 message transaction. Produced by: TransformHL7Message (adapter). Consumed by: SendJSONPayload (adapter). */
        }

        occurrence def <JSONPayloadSent> 'JSON Payload Sent' {
            doc /* Send end of a JSON payload transaction. Produced by: SendJSONPayload (adapter). */
        }

        occurrence def <JSONPayloadReceived> 'JSON Payload Received' {
            doc /* Receive end of a JSON payload transaction. Consumed by: ReceiveJSONPayload (downstream). */
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

        action def <CreateHL7Message> 'Create HL7 Message' {
            doc /* Extract the HL7 message from the MLLP frame. */
            in mllpFrame : MLLPFrame;
            out hl7Message : HL7Message;
            out attribute success : Boolean;
        }

        action def <CreateMetadata> 'Create Metadata' {
            doc /* Adapter maps selected HL7 fields into a stable JSON representation. */
            in hl7Message : HL7Message;
            out 'metadata' : MessageMetadata;
            out attribute success : Boolean;
        }

        action def <CreateDemographics> 'Create Demographics' {
            doc /* Extract the demographics from the HL7 message. */
            in hl7Message : HL7Message;
            out demographics : PatientDemographics;
            out attribute success : Boolean;
        }

        action def <CreateJsonPayload> 'Create JSON Payload' {
            doc /* Transform the HL7 message into a JSON payload. */
            in 'metadata' : MessageMetadata;
            in demographics : PatientDemographics;
            out jsonPayload : JSONPayload;
            out attribute success : Boolean;
        }

        action def <SendJSONPayload> 'Send JSON Payload' {
            doc /* Send the JSON payload to the downstream API. */
            in jsonPayload : JSONPayload;
            out attribute success : Boolean;
        }

        action def <ReceiveJSONPayload> 'Receive JSON Payload' {
            doc /* Receive the JSON payload from the downstream API. */
            out jsonPayload : JSONPayload;
            out attribute success : Boolean;
        }

        action def <CreateIntegrationError> 'Create Integration Error' {
            doc /* Adapter handles an integration error. */
            out integrationError : IntegrationError;
        }

        action def <HandleIntegrationError> 'Handle Integration Error' {
            doc /* Adapter handles an integration error. */
            in integrationError : IntegrationError;
        }

        /* Coarse-grained CIM-level flow for ingestion and forwarding. */
        action def <HandleFrame> 'Handle Frame' {

            doc /* Main CIM-level flow from publish through receive, parse, transform, and post.
               Detailed protocol-specific behavior and error handling are refined in PIM behavior. */

            in mllpFrame : MLLPFrame;

            action extract : CreateHL7Message;
            action sendError : CreateIntegrationError;

            flow from mllpFrame to extract.mllpFrame;

            first start;
            then extract;
            if extract.success then done; else sendError;

            out attribute success : Boolean = extract.success;
        }

        action def <HandleMessage> 'Handle Message' {
            doc /* Main CIM-level flow from publish through receive, parse, transform, and post. */

            in hl7message : HL7Message;

            action createMetadata : CreateMetadata;
            action createDemographics : CreateDemographics;
            action createJsonPayload : CreateJsonPayload;
            action createIntegrationError : CreateIntegrationError;

            flow from hl7message to createMetadata.hl7Message;
            flow from hl7message to createDemographics.hl7Message;
            flow from createMetadata.'metadata' to createJsonPayload.'metadata';
            flow from createDemographics.demographics to createJsonPayload.demographics;

            first hl7message;
            then fork;
                then createMetadata;
                then createDemographics;
            then join;
            if createMetadata.success and createDemographics.success then createJsonPayload; else createIntegrationError;
            then done;

            out attribute success : Boolean = createMetadata.success and createDemographics.success;
        }

        action def <HandleJsonPayload> 'Handle Json Payload' {
            doc /* Downstream API owner receives the JSON payload. */

            in jsonPayload : JSONPayload;
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
                /* Main Success Scenario
                   ---------------------
                   1. upstreamSystem sends an HL7Message framed in an MLLPFrame towards adapterService
                      (Send MLLP Frame – msgMLLPFrame from upstreamSystem.msgMLLPFrameSent to
                      adapterService.msgMLLPFrameReceived).
                   2. adapterService receives the MLLPFrame and unwraps it into an HL7Message for
                      further handling (Receive MLLP Frame / Handle Frame).
                   3. adapterService extracts demographics and metadata and composes a JSONPayload
                      from the HL7Message (Handle HL7 Message – CreateMetadata, CreateDemographics,
                      CreateJsonPayload).
                   4. adapterService sends the JSONPayload to a RESTEndpoint owned by
                      downstreamApiOwner (Send JSON Payload – JSONPayloadExchange).
                   5. downstreamApiOwner receives the JSONPayload (Receive JSON Payload).
                   6. No IntegrationError is raised; the event is considered successfully ingested
                      and forwarded.

                   Alternate Paths
                   ---------------
                   A1. HL7 content variations
                       - As described in Handle HL7 Message (optional segments omitted, additional
                         non‑critical segments present), extraction still yields a clinically
                         sufficient JSONPayload.
                       - Rejoin at step 3 when JSONPayload is composed successfully.

                   A2. Multiple logical REST endpoints
                       - As described in Send JSON Payload, adapterService selects among multiple
                         RESTEndpoint variants based on JSONPayload content.
                       - Rejoin at step 4 once JSONPayload is successfully posted.

                   Exception Paths
                   ---------------
                   E1. Frame‑level failures (oversized frame, connection reset/timeout)
                       - As described in Receive MLLP Frame, adapterService records an
                         IntegrationError and does not proceed to HL7 handling.
                       - Control flows into Handle Integration Error (CIM); this scenario does not
                         rejoin the main success path.

                   E2. HL7 content errors (malformed header, missing mandatory data)
                       - As described in Handle HL7 Message, a ParseError/IntegrationError is
                         raised and handled by Handle Integration Error (CIM).
                       - Scenario terminates in degraded mode; no rejoin to step 3.

                   E3. Delivery failures (downstream HTTP / policy issues)
                       - As described in Send JSON Payload, a DeliveryError/IntegrationError is
                         raised and handled by Handle Integration Error (CIM).
                       - Scenario terminates in degraded mode; no rejoin to step 5. */
            }

            include 'Send MLLP Frame';
            include 'Receive MLLP Frame';
            include 'Handle HL7 Message';
            include 'Send JSON Payload';
            include 'Receive JSON Payload';
            include 'Handle Integration Error (CIM)';
        }

        /* CIM-level use cases decomposed from the main flow. */

        use case 'Send MLLP Frame' {
            doc /* Upstream HL7 system sends an MLLPFrame (containing an HL7Message) to the adapter. */
            private import Domain::*;
            private import Events::*;

            subject upstreamSystem : UpstreamHL7System {
                event occurrence msgMLLPFrameSent : MLLPFrameSent;
            }
            actor adapterService : HL7AdapterService{
                event occurrence msgMLLPFrameReceived : MLLPFrameReceived;
            }
            message msgMLLPFrame of MLLPFrame
                from upstreamSystem.msgMLLPFrameSent to adapterService.msgMLLPFrameReceived;

            first msgMLLPFrame;
            then done;

            objective {
                doc
                /* Primary scenario
                   ----------------
                   upstreamSystem creates an HL7Message and frames it in an MLLPFrame, then
                   conceptually sends that frame towards adapterService.
                   - Message flow: msgMLLPFrame of MLLPFrame from
                     upstreamSystem.msgMLLPFrameSent to adapterService.msgMLLPFrameReceived.
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

        use case 'Receive MLLP Frame' {

            private import Domain::*;
            private import Events::*;

            subject adapterService : HL7AdapterService{
                event occurrence msgMLLPFrameReceived : MLLPFrameReceived;
            }
            actor upstreamSystem : UpstreamHL7System {
                event occurrence msgMLLPFrameSent : MLLPFrameSent;
            }
            message msgMLLPFrame of MLLPFrame
                from upstreamSystem.msgMLLPFrameSent to adapterService.msgMLLPFrameReceived;

            action extract : CreateHL7Message;
            flow from msgMLLPFrame to extract.mllpFrame;

            first msgMLLPFrame;
            then extract;
            then done;

            objective {
                doc
                /* Primary scenario
                   ----------------
                   adapterService conceptually receives the MLLPFrame and unwraps it to obtain
                   an HL7Message for further processing.
                   - Message flow: msgMLLPFrame of MLLPFrame from
                     upstreamSystem.msgMLLPFrameSent to adapterService.msgMLLPFrameReceived.
                   - Action flow: CreateHL7Message reads the received MLLPFrame
                     (flow from msgMLLPFrame to extract.mllpFrame) and creates the HL7Message.
                   - Operations: ReceiveMLLPFrame (frame ingress) and ExtractHL7Message / CreateHL7Message
                     (HL7 content extraction).
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

            subject adapterService : HL7AdapterService {
                event occurrence msgHL7MessageCreated : Created;
            }
            part hl7Message : HL7Message;

            message hl7MessageCreated
                from hl7Message.created to adapterService.msgHL7MessageCreated;

            action extractMetadata : CreateMetadata;
            action extractDemographics : CreateDemographics;
            action composeJsonPayload : CreateJsonPayload;
            action sendError : CreateIntegrationError;

            flow from hl7MessageCreated to extractMetadata.hl7Message;
            flow from hl7MessageCreated to extractDemographics.hl7Message;
            flow from extractMetadata.'metadata' to composeJsonPayload.'metadata';
            flow from extractDemographics.demographics to composeJsonPayload.demographics;

            first hl7MessageCreated;
            then fork;
                then extractMetadata;
                then extractDemographics;
            then join;
            if extractMetadata.success and extractDemographics.success then composeJsonPayload; else sendError;
            then done;

            objective {
                doc
                /* Main Success Scenario
                   ---------------------
                   1. An HL7Message instance is created from a received MLLPFrame; its creation is
                      signalled to adapterService (message hl7MessageCreated from hl7Message.created
                      to adapterService.msgHL7MessageCreated).
                   2. adapterService forks into two parallel extraction actions:
                      - CreateMetadata to derive MessageMetadata from the HL7Message.
                      - CreateDemographics to derive PatientDemographics from the HL7Message.
                   3. Both CreateMetadata and CreateDemographics succeed, producing 'metadata' and
                      demographics outputs.
                   4. adapterService composes a JSONPayload in CreateJsonPayload from metadata and
                      demographics (flows from extractMetadata.'metadata' and
                      extractDemographics.demographics).
                   5. The JSONPayload is made available for subsequent sending to downstream
                      systems.

                   Alternate Paths
                   ---------------
                   A1. Optional clinical segments omitted
                       - HL7Message lacks certain optional segments; required PatientDemographics
                         and core fields are present.
                       - Both extraction actions still succeed, though demographics may be
                         partially populated.
                       - Rejoin at step 3/4 when CreateJsonPayload has sufficient inputs.

                   A2. Additional non‑critical segments present
                       - HL7Message contains extra segments not used by this adapter.
                       - These are ignored; extraction focuses on required content.
                       - Rejoin at step 3/4 with normal JSONPayload composition.

                   A3. Mapping with optional JSON fields omitted
                       - Certain fields in JSONPayload are absent because corresponding HL7
                         segments were optional.
                       - Clinical meaning required for the mission is still preserved.
                       - Rejoin at step 5 with a valid but partially populated JSONPayload.

                   A4. Additional derived JSON fields
                       - adapterService derives additional non‑essential (summary) fields in
                         JSONPayload.
                       - CIM records these without prescribing detailed implementation.
                       - Rejoin at step 5 with an enriched JSONPayload.

                   Exception Paths
                   ---------------
                   E3. Malformed header or segment structure
                       - HL7Message has an invalid structure (e.g. malformed MSH, inconsistent
                         field separators).
                       - A ParseError is raised, linked to HL7Message and relevant segmentId/fieldPath.
                       - Flow proceeds to CreateIntegrationError / Handle Integration Error (CIM);
                         this path does not rejoin the main success scenario.

                   E4. Missing mandatory patient data
                       - PatientDemographics lacks mandatory fields (e.g. patientId or dateOfBirth).
                       - Extraction/validation fails and records a ParseError, leading to degraded
                         handling via Handle Integration Error (CIM); no rejoin. */
            }
        }

        use case 'Send JSON Payload' {

            private import Domain::*;
            private import Events::*;

            item jsonPayload : JSONPayload;
            
            subject adapterService : HL7AdapterService {
                event occurrence msgJSONPayloadSent : JSONPayloadSent;
                event occurrence msgJSONPayloadCreated : Created;
            }
            actor downstreamApiOwner : DownstreamAPIOwner {
                event occurrence msgJSONPayloadReceived : JSONPayloadReceived;
            }

            message jsonPayloadCreated
                from jsonPayload.created to adapterService.msgJSONPayloadCreated;
            message JSONPayloadExchange of JSONPayload
                from adapterService.msgJSONPayloadSent to downstreamApiOwner.msgJSONPayloadReceived;

            first jsonPayloadCreated;
            then JSONPayloadExchange;
            then done;

            objective {
                doc
                /* Main Success Scenario
                   ---------------------
                   1. A JSONPayload instance is created by prior HL7 handling; its creation is
                      signalled to adapterService (message jsonPayloadCreated from jsonPayload.created
                      to adapterService.msgJSONPayloadCreated).
                   2. adapterService prepares and sends the JSONPayload to a RESTEndpoint owned by
                      downstreamApiOwner (SendJSONPayload).
                   3. The JSONPayload is received by downstreamApiOwner
                      (ReceiveJSONPayload – JSONPayloadExchange from
                      adapterService.msgJSONPayloadSent to downstreamApiOwner.msgJSONPayloadReceived).
                   4. No DeliveryError or IntegrationError is raised; the handoff is considered
                      successful.

                   Alternate Paths
                   ---------------
                   A1. Multiple logical endpoints
                       - RESTEndpoint represents a family of logical endpoints; adapterService
                         selects one based on JSONPayload content.
                       - All selected endpoints conceptually satisfy the same handoff intent.
                       - Rejoin at step 3 once JSONPayload is successfully received.

                   Exception Paths
                   ---------------
                   E5. Downstream temporary failure (e.g. 503)
                       - RESTEndpoint responds with a temporary failure; a DeliveryError is recorded.
                       - Handling is delegated to Handle Integration Error (CIM); this scenario does
                         not rejoin the main success path.

                   E6. Network or connectivity failure
                       - Conceptual network issues prevent delivery (e.g. connection reset, timeout).
                       - A DeliveryError is raised; no successful handoff occurs; flow proceeds to
                         Handle Integration Error (CIM); no rejoin.

                   E7. Security or policy failure
                       - Conceptual security/policy constraints (e.g. PHIHandlingPolicy) prevent
                         forwarding.
                       - IntegrationError reflects the failure to meet M3/M4 obligations for this
                         message; flow proceeds to Handle Integration Error (CIM); no rejoin. */
            }
        }

        use case 'Receive JSON Payload' {
            doc /* Downstream API owner receives the JSONPayload that adapterService has sent. */
            private import Domain::*;
            private import Events::*;

            subject downstreamApiOwner : DownstreamAPIOwner {
                event occurrence msgJSONPayloadReceived : JSONPayloadReceived;
            }
            actor adapterService : HL7AdapterService {
                event occurrence msgJSONPayloadSent : JSONPayloadSent;
            }

            message jsonPayloadReceived of JSONPayload
                from adapterService.msgJSONPayloadSent to downstreamApiOwner.msgJSONPayloadReceived;
            
            first jsonPayloadReceived;
            then done;
            
        }

        use case 'Handle Integration Error (CIM)' {

            subject adapterService : HL7AdapterService {
                event occurrence msgIntegrationErrorCreated : Created;
            }

            actor operationsEngineer : OperationsEngineer;
            part integrationError : IntegrationError;

            message integrationErrorCreated
                from integrationError.created to adapterService.msgIntegrationErrorCreated;

            action handleIntegrationError : HandleIntegrationError;

            first integrationErrorCreated;
            then handleIntegrationError;
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

        satisfy 'Reliable Event Ingestion' by 'Send MLLP Frame';
        satisfy 'Reliable Event Ingestion' by 'Receive MLLP Frame';
        satisfy 'Accurate Clinical Transformation' by 'Handle HL7 Message';
        satisfy 'Secure Interoperability' by 'Send JSON Payload';
        satisfy 'Secure Interoperability' by 'Receive JSON Payload';
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