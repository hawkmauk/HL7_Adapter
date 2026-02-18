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

        action def <PublishHL7Event> 'Publish HL7 Event' {
            doc /* Upstream actor publishes a framed HL7 message to the adapter listener. */
        }

        action def <ReceiveMLLPMessage> 'Receive MLLP Message' {
            doc /* Adapter accepts inbound framed data from a TCP connection. */
        }

        action def <ParseAndValidateHL7> 'Parse and Validate HL7' {
            doc /* Adapter parses HL7 structure and validates required message content. */
        }

        action def <TransformToJSON> 'Transform to JSON' {
            doc /* Adapter maps selected HL7 fields into a stable JSON representation. */
        }

        action def <PostPayloadToAPI> 'Post Payload to API' {
            doc /* Adapter submits transformed payload to downstream HTTP endpoint. */
        }

        action def <HandleOperationalError> 'Handle Operational Error' {
            doc /* Adapter logs, reports, and applies retry or rejection behavior for failures. */
        }

        /* Coarse-grained CIM-level flow for ingestion and forwarding. */
        action def <EventFlow> 'Event Flow' {
            doc
            /* Main CIM-level flow from publish through receive, parse, transform, and post.
               Detailed protocol-specific behavior and error handling are refined in PIM behavior. */

            action publish : PublishHL7Event;
            action receive : ReceiveMLLPMessage;
            action parse : ParseAndValidateHL7;
            action transform : TransformToJSON;
            action post : PostPayloadToAPI;

            first publish then receive;
            first receive then parse;
            first parse then transform;
            first transform then post;
            first post then done;
        }
    }

    package UseCases {
        doc /* CIM-level use cases derived from the EventFlow operation. */

        private import Stakeholders::*;
        private import Context::*;
        private import Domain::*;
        private import Operations::*;
        private import Mission::*;

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
            include 'Parse HL7 Message';
            include 'Transform HL7 Message';
            include 'Forward JSON Payload';
        }

        /* CIM-level use cases decomposed from the main flow. */

        use case 'Send HL7 Message' {
            subject upstreamSystem : UpstreamHL7System;
            actor adapterService : HL7AdapterService;

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
            subject adapterService : HL7AdapterService;
            actor upstreamSystem : UpstreamHL7System;

            objective {
                doc
                /* Primary scenario
                   ----------------
                   adapterService conceptually receives and unwraps the framed HL7Message.
                   - Operation: ReceiveMLLPMessage.
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

        use case 'Parse HL7 Message' {
            subject adapterService : HL7AdapterService;
            actor upstreamSystem : UpstreamHL7System;

            objective {
                doc
                /* Primary scenario
                   ----------------
                   adapterService parses the HL7Message and validates required content at CIM level.
                   - Operation: ParseAndValidateHL7.
                   - Domain: HL7Message, PatientDemographics, MessageMetadata.
                   - Mission: Accurate Clinical Transformation (M2).

                   Alternate scenarios (parse stage)
                   --------------------------------
                   A1. Optional clinical segments omitted
                       - HL7Message lacks certain optional segments; required PatientDemographics and core fields are present.
                       - ParseAndValidateHL7 still succeeds; PatientDemographics may be partially populated.

                   A2. Additional non-critical segments present
                       - HL7Message contains extra segments not used by this adapter.
                       - These are ignored conceptually; validation focuses on required content.

                   Exception scenarios (parse stage)
                   --------------------------------
                   E3. Malformed header or segment structure
                       - HL7Message has an invalid structure (e.g. malformed MSH, inconsistent field separators).
                       - A ParseError is raised, linked to HL7Message and relevant segmentId/fieldPath.

                   E4. Missing mandatory patient data
                       - PatientDemographics lacks mandatory fields (e.g. patientId or dateOfBirth).
                       - ParseAndValidateHL7 fails validation and records a ParseError, leading to degraded handling. */
            }
        }

        use case 'Transform HL7 Message' {
            subject adapterService : HL7AdapterService;
            actor downstreamApiOwner : DownstreamAPIOwner;

            objective {
                doc
                /* Primary scenario
                   ----------------
                   adapterService transforms a validated HL7Message into a JSONPayload suitable
                   for conceptual consumption by downstreamApiOwner.
                   - Operation: TransformToJSON.
                   - Domain: HL7Message, JSONPayload.
                   - Mission: Accurate Clinical Transformation (M2).

                   Alternate scenarios (transform stage)
                   -------------------------------------
                   A1. Mapping with optional fields omitted
                       - Certain fields in JSONPayload are absent because corresponding HL7 segments were optional.
                       - Clinical meaning required for the mission is still preserved.

                   A2. Additional derived fields
                       - adapterService derives additional non-essential fields (e.g. summary fields) in JSONPayload.
                       - CIM notes their presence conceptually without prescribing implementation details. */
            }
        }

        use case 'Forward JSON Payload' {
            subject adapterService : HL7AdapterService;
            actor downstreamApiOwner : DownstreamAPIOwner;

            objective {
                doc
                /* Primary scenario
                   ----------------
                   adapterService posts the JSONPayload to a RESTEndpoint owned by downstreamApiOwner.
                   - Operation: PostPayloadToAPI.
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
            actor upstreamSystem : UpstreamHL7System;
            actor downstreamApiOwner : DownstreamAPIOwner;

            objective {
                doc
                /* Handle Integration Error (CIM) covers degraded scenarios conceptually
                   described by the EventFlow operation, including ParseError and DeliveryError.
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
        satisfy 'Accurate Clinical Transformation' by 'Parse HL7 Message';
        satisfy 'Accurate Clinical Transformation' by 'Transform HL7 Message';
        satisfy 'Secure Interoperability' by 'Forward JSON Payload';
        satisfy 'Operational Transparency' by 'Handle Integration Error (CIM)';
    }

    package Mission {
        doc /* Mission intent and stakeholder-oriented outcome statements for challenge scope. */

        requirement <M1> 'Reliable Event Ingestion' {
            doc /* The solution shall consistently ingest framed HL7 events from a local sender. */
        }

        requirement <M2> 'Accurate Clinical Transformation' {
            doc /* The solution shall preserve key clinical identifiers and message semantics during mapping to JSON. */
        }

        requirement <M3> 'Secure Interoperability' {
            doc /* The solution shall forward transformed payloads over HTTPS to a downstream API. */
        }

        requirement <M4> 'Operational Transparency' {
            doc /* The solution shall expose meaningful error outcomes for failed parsing or forwarding attempts. */
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
