package CIM {

    package Domain {
        doc /* Domain ontology for a local HL7 to HTTPS integration context. */

        part def HL7Message {
            doc /* Conceptual representation of an inbound HL7 v2 message carried over MLLP. */
        }

        part def MLLPFrame {
            doc /* Transport framing envelope used to delimit HL7 payloads on TCP streams. */
        }

        part def PatientDemographics {
            doc /* Conceptual patient data extracted from HL7 segments, such as PID content. */
        }

        part def MessageMetadata {
            doc /* Conceptual metadata extracted from MSH fields, including trigger event type. */
        }

        part def JSONPayload {
            doc /* Structured payload produced from HL7 content and posted to a REST endpoint. */
        }

        part def RESTEndpoint {
            doc /* Conceptual HTTP interface that receives transformed clinical event payloads. */
        }

        part def IntegrationError {
            doc /* Any recoverable or non-recoverable operational issue during receive, parse, map, or forward. */
        }

        part def ParseError :> IntegrationError {
            doc /* Error caused by malformed HL7 structure or missing required fields. */
        }

        part def DeliveryError :> IntegrationError {
            doc /* Error caused by network, API availability, or unsuccessful HTTP response. */
        }
    }

    package Stakeholders {
        doc /* Stakeholder and actor concepts interacting with or governing the integration. */

        part def IntegrationEngineer {
            doc /* Builds, configures, and maintains the adapter and local deployment. */
        }

        part def ClinicalSystemOwner {
            doc /* Owns the upstream HL7-producing system and data quality expectations. */
        }

        part def UpstreamHL7System {
            doc /* External clinical system that publishes HL7 events to the receiver. */
        }

        part def DownstreamAPIOwner {
            doc /* Owns the HTTP API that consumes transformed event payloads. */
        }

        part def SecurityAndComplianceOfficer {
            doc /* Ensures patient data handling, transport security, and compliance obligations. */
        }

        part def OperationsEngineer {
            doc /* Monitors runtime health, failures, retries, and service continuity. */
        }
    }

    package Context {
        doc /* Operational context in which the adapter is used as a black-box service. */

        part def HL7AdapterService {
            doc /* Conceptual service that receives HL7 via MLLP, transforms to JSON, and forwards to API. */
        }

        part def LocalDevelopmentEnvironment {
            doc /* Local machine and process environment used for challenge execution and testing. */
        }

        part def NetworkBoundary {
            doc /* Boundary separating MLLP ingress and HTTPS egress communication domains. */
        }

        part def RuntimeConfiguration {
            doc /* Conceptual runtime settings such as host, port, endpoint URL, and security options. */
        }
    }

    package Operations {
        doc /* High-level operational activities and scenarios, kept technology-agnostic at CIM level. */

        action def PublishHL7Event {
            doc /* Upstream actor publishes a framed HL7 message to the adapter listener. */
        }

        action def ReceiveMLLPMessage {
            doc /* Adapter accepts inbound framed data from a TCP connection. */
        }

        action def ParseAndValidateHL7 {
            doc /* Adapter parses HL7 structure and validates required message content. */
        }

        action def TransformToJSON {
            doc /* Adapter maps selected HL7 fields into a stable JSON representation. */
        }

        action def PostPayloadToAPI {
            doc /* Adapter submits transformed payload to downstream HTTP endpoint. */
        }

        action def HandleOperationalError {
            doc /* Adapter logs, reports, and applies retry or rejection behavior for failures. */
        }

        action def NominalFlow {
            doc /* Main operational scenario from inbound event publication to successful API handoff. */
            action publishHL7Event : PublishHL7Event;
            action receiveMLLPMessage : ReceiveMLLPMessage;
            action parseAndValidateHL7 : ParseAndValidateHL7;
            action transformToJSON : TransformToJSON;
            action postPayloadToAPI : PostPayloadToAPI;

            first publishHL7Event then receiveMLLPMessage;
            first receiveMLLPMessage then parseAndValidateHL7;
            first parseAndValidateHL7 then transformToJSON;
            first transformToJSON then postPayloadToAPI;
            first postPayloadToAPI then done;
        }

        action def DegradedFlow {
            doc /* Degraded scenario where parsing or delivery fails and error handling is invoked. */
            action publishHL7Event : PublishHL7Event;
            action receiveMLLPMessage : ReceiveMLLPMessage;
            action parseAndValidateHL7 : ParseAndValidateHL7;
            action handleOperationalError : HandleOperationalError;

            first publishHL7Event then receiveMLLPMessage;
            first receiveMLLPMessage then parseAndValidateHL7;
            first parseAndValidateHL7 then handleOperationalError;
            first handleOperationalError then done;
        }
    }

    package Mission {
        doc /* Mission intent and stakeholder-oriented outcome statements for challenge scope. */

        requirement <M1> ReliableEventIngestion {
            doc /* The solution shall consistently ingest framed HL7 events from a local sender. */
        }

        requirement <M2> AccurateClinicalTransformation {
            doc /* The solution shall preserve key clinical identifiers and message semantics during mapping to JSON. */
        }

        requirement <M3> SecureInteroperability {
            doc /* The solution shall forward transformed payloads over HTTPS to a downstream API. */
        }

        requirement <M4> OperationalTransparency {
            doc /* The solution shall expose meaningful error outcomes for failed parsing or forwarding attempts. */
        }
    }

    package Assumptions {
        doc /* Non-design assumptions and constraints shaping the challenge solution space. */

        constraint def LocalExecutionOnly {
            doc /* System execution is limited to a local development environment for the exercise. */
        }

        constraint def MLLPTransportRequired {
            doc /* HL7 transport from publisher to receiver uses Minimal Lower Layer Protocol framing. */
        }

        constraint def HTTPSForwardingRequired {
            doc /* Outbound payload delivery uses an HTTPS REST endpoint interface. */
        }

        constraint def LimitedScopeTesting {
            doc /* Verification scope includes representative and limited test cases rather than full certification coverage. */
        }

        constraint def PHIHandlingPolicy {
            doc /* Patient-related data must be handled in a manner consistent with security and compliance expectations. */
        }
    }
}
