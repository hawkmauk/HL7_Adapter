package PIM {
    private import CIM::*;
    private import MDA::PIM::Structure::*;

    package UseCases {
        doc /* System use cases refining CIM operational scenarios; actors from CIM Stakeholders. */

        private import CIM::Stakeholders::*;
        private import CIM::Operations::*;

        use case def <IngestAndForwardEvent> 'Ingest and Forward Event' {
            doc /* Nominal path: upstream publishes HL7, adapter receives, parses, transforms, posts to API. Refines Operations::NominalFlow. */
        }

        use case def <HandleParseFailure> 'Handle Parse Failure' {
            doc /* Parsing fails; adapter invokes error handling. Refines DegradedFlow parse branch. */
        }

        use case def <HandleDeliveryFailure> 'Handle Delivery Failure' {
            doc /* Delivery to downstream API fails; adapter invokes error handling. Refines DegradedFlow delivery branch. */
        }

        part actorUpstream : UpstreamHL7System;
        part actorDownstream : DownstreamAPIOwner;
        part actorIntegrationEngineer : IntegrationEngineer;
        part actorOperationsEngineer : OperationsEngineer;
    }

    package Interfaces {
        doc /* Logical interfaces and message types between adapter and environment; no protocol or technology detail. */

        private import CIM::Domain::*;
        private import CIM::Context::*;

        part def <DeliveryResult> 'Delivery Result' {
            doc /* Logical success or failure outcome of a delivery attempt. */
        }

        part def <ParsedMessage> 'Parsed Message' {
            doc /* Logical output of parser: metadata and extracted content or error. */
        }

        port def <MLLPIngressPort> 'MLLP Ingress Port' {
            doc /* Inbound framed message from upstream. */
            in item framedMessage : MLLPFrame;
        }

        port def <HTTPEgressPort> 'HTTP Egress Port' {
            doc /* Outbound payload and response to downstream API. */
            in item payload : JSONPayload;
            out item response : DeliveryResult;
        }

        port def <RuntimeConfigPort> 'Runtime Config Port' {
            doc /* Conceptual runtime settings. */
            in item config : RuntimeConfiguration;
        }

        interface def <MLLPIngressInterface> 'MLLP Ingress Interface' {
            doc /* Association between adapter and upstream for framed HL7 messages. */
            end adapterPort : MLLPIngressPort;
            end upstreamPort : MLLPIngressPort;
        }

        interface def <HTTPEgressInterface> 'HTTP Egress Interface' {
            doc /* Association between adapter and downstream API for payload delivery. */
            end adapterPort : HTTPEgressPort;
            end apiPort : HTTPEgressPort;
        }

        interface def <RuntimeConfigInterface> 'Runtime Config Interface' {
            doc /* Association between adapter and configuration source. */
            end adapterPort : RuntimeConfigPort;
            end configSource : RuntimeConfigPort;
        }
    }

    package LogicalArchitecture {
        doc /* Logical system block and components; white-box view of the HL7 Adapter. */

        private import CIM::Domain::*;
        private import CIM::Context::*;
        private import PIM::Interfaces::*;

        part def <MLLPReceiver> 'MLLP Receiver' {
            doc /* Accepts inbound framed HL7 messages from upstream. */
        }

        part def <Parser> 'Parser' {
            doc /* Parses and validates HL7 structure and required content. */
        }

        part def <Transformer> 'Transformer' {
            doc /* Maps HL7 content into a stable JSON representation. */
        }

        part def <HTTPForwarder> 'HTTP Forwarder' {
            doc /* Submits transformed payload to downstream REST endpoint. */
        }

        part def <ErrorHandler> 'Error Handler' {
            doc /* Logs, reports, and applies retry or rejection for parse or delivery failures. */
        }

        part def <HL7Adapter> 'HL7 Adapter' {
            doc /* Logical system refining CIM Context::HL7AdapterService. */

            part mllpReceiver : MLLPReceiver;
            part parser : Parser;
            part transformer : Transformer;
            part httpForwarder : HTTPForwarder;
            part errorHandler : ErrorHandler;

            port mllpIngress : MLLPIngressPort;
            port httpEgress : HTTPEgressPort;
            port runtimeConfig : RuntimeConfigPort;

            connect mllpIngress to mllpReceiver;
            connect mllpReceiver to parser;
            connect parser to transformer;
            connect transformer to httpForwarder;
            connect httpForwarder to httpEgress;
            connect parser to errorHandler;
            connect httpForwarder to errorHandler;
        }
    }

    package Requirements {
        doc /* System-level requirements refining CIM Mission M1–M4; satisfy by logical blocks. */

        private import CIM::Mission::*;
        private import PIM::LogicalArchitecture::*;

        requirement <SYS1> 'Reliable Event Ingestion' {
            doc /* The system shall consistently ingest framed HL7 events from a local sender. Derived from M1. */
        }

        requirement <SYS2> 'Accurate Clinical Transformation' {
            doc /* The system shall preserve key clinical identifiers and message semantics during mapping to JSON. Derived from M2. */
        }

        requirement <SYS3> 'Secure Interoperability' {
            doc /* The system shall forward transformed payloads over HTTPS to a downstream API. Derived from M3. */
        }

        requirement <SYS4> 'Operational Transparency' {
            doc /* The system shall expose meaningful error outcomes for failed parsing or forwarding attempts. Derived from M4. */
        }

        part hl7_adapter : HL7Adapter;
        satisfy SYS1 by hl7_adapter.mllpReceiver;
        satisfy SYS2 by hl7_adapter.parser;
        satisfy SYS2 by hl7_adapter.transformer;
        satisfy SYS3 by hl7_adapter.httpForwarder;
        satisfy SYS4 by hl7_adapter.errorHandler;
    }

    package DataModel {
        doc /* Logical structures aligned with CIM Domain; reuse Domain types, add PIM DTOs where needed. */

        private import CIM::Domain::*;

        part def <ParseResult> 'Parse Result' {
            doc /* Either parsed content (metadata, demographics) or ParseError. */
        }
    }

    package Behavior {
        doc /* Logical actions and flows refining CIM operations; nominal and degraded flows. */

        private import CIM::Operations::*;
        private import PIM::LogicalArchitecture::*;
        private import PIM::Interfaces::*;

        action def <ReceiveFramedMessage> 'Receive Framed Message' {
            doc /* Adapter accepts inbound framed data. Refines ReceiveMLLPMessage. */
        }

        action def <ParseAndValidate> 'Parse and Validate' {
            doc /* Parse HL7 structure and validate required content. Refines ParseAndValidateHL7. */
        }

        action def <TransformToJSON> 'Transform to JSON' {
            doc /* Map HL7 fields to stable JSON. Refines TransformToJSON. */
        }

        action def <PostToEndpoint> 'Post to Endpoint' {
            doc /* Submit payload to downstream HTTP endpoint. Refines PostPayloadToAPI. */
        }

        action def <HandleError> 'Handle Error' {
            doc /* Log, report, and apply retry or rejection. Refines HandleOperationalError. */
        }

        action def <ProcessNominalFlow> 'Process Nominal Flow' {
            doc /* Flow from receive through post; mirrors CIM NominalFlow. */
            action receiveFramedMessage : ReceiveFramedMessage;
            action parseAndValidate : ParseAndValidate;
            action transformToJSON : TransformToJSON;
            action postToEndpoint : PostToEndpoint;

            first receiveFramedMessage then parseAndValidate;
            first parseAndValidate then transformToJSON;
            first transformToJSON then postToEndpoint;
            first postToEndpoint then done;
        }

        action def <ProcessDegradedFlowParse> 'Process Degraded Flow (Parse)' {
            doc /* Parse fails; invoke error handling. */
            action receiveFramedMessage : ReceiveFramedMessage;
            action parseAndValidate : ParseAndValidate;
            action handleError : HandleError;

            first receiveFramedMessage then parseAndValidate;
            first parseAndValidate then handleError;
            first handleError then done;
        }

        action def <ProcessDegradedFlowDelivery> 'Process Degraded Flow (Delivery)' {
            doc /* Delivery fails; invoke error handling. */
            action receiveFramedMessage : ReceiveFramedMessage;
            action parseAndValidate : ParseAndValidate;
            action transformToJSON : TransformToJSON;
            action postToEndpoint : PostToEndpoint;
            action handleError : HandleError;

            first receiveFramedMessage then parseAndValidate;
            first parseAndValidate then transformToJSON;
            first transformToJSON then postToEndpoint;
            first postToEndpoint then handleError;
            first handleError then done;
        }
    }

    package Allocations {
        doc /* Placeholder for future PIM allocations between requirements, logical architecture, and behavior. */
    }
}
