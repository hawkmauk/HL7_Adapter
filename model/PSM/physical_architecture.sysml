package PSM_PhysicalArchitecture {

    private import PIM::*;
    private import PSM::Interfaces::*;
    private import PSM::Actions::*;
    private import ScalarValues::*;
    private import CIM::Datatype::*;

    doc /* PSM physical architecture: each PIM logical component refined with technology bindings and implementation-specific attributes (config, library types). Refines PIM::LogicalArchitecture. Each part is configured by the binding(s) that are inputs to its initializeFromBinding action: MLLPReceiver by MLLPIngressBinding and RuntimeConfigBinding; Parser, Transformer, ErrorHandler by RuntimeConfigBinding; HTTPForwarder by HTTPEgressBinding and RuntimeConfigBinding. */

    part def <MLLPReceiver> 'MLLP Receiver' :> PIM::LogicalArchitecture::MLLPReceiver {
        doc /* Refines PIM::LogicalArchitecture::MLLPReceiver. Technology binding: Node.js net/socket or custom MLLP framing. Implementation comprises TCP socket listener (Node.js net.Server), MLLP framing parser (start/end byte and length), and connection manager (accept/close/timeout). Configurable host/port. */
        attribute bindHost : String { doc /* Listen address for the MLLP server (e.g. 0.0.0.0 for all interfaces). */ }
        attribute bindPort : Integer { doc /* TCP port for MLLP listener (e.g. 2575). */ }
        attribute maxPayloadSize : Integer { doc /* Maximum MLLP payload size in bytes; frames exceeding this are rejected. */ }
        attribute connectionIdleTimeoutMs : Integer { doc /* Idle timeout in milliseconds before closing a connection. */ }

        perform action parseMllpFrame : ParseMllpFrame;
        perform action buildMllpMessage : BuildMllpMessage;
        perform action buildAck : BuildAck;
        perform action buildNak : BuildNak;
        perform action start : StartReceiver;
        perform action stop : StopReceiver;
        perform action initializeFromBinding : InitializeMLLPReceiver;

        rep textualRepresentation language "TypeScript"
        /*
import * as net from 'net';

// MLLP framing constants (0x0B start, 0x1C 0x0D end).
export const MLLP_START = 0x0b;
export const MLLP_END_1 = 0x1c;
export const MLLP_END_2 = 0x0d;

export interface ParseMllpResult {
  payload?: Buffer;
  done: boolean;
  error?: string;
  consumed: number;
}
        */

        rep classMembers language "TypeScript"
        /*
private _server: net.Server | null = null;
        */
    }

    part def <Parser> 'Parser' :> PIM::LogicalArchitecture::Parser {
        doc /* Refines PIM::LogicalArchitecture::Parser. Technology binding: node-hl7-complete. Implementation uses HL7 segment iterator, field extractor, and validation rules engine; library-specific API in use. */
        attribute encodingFallback : String { doc /* Fallback character encoding when not specified in MSH (e.g. UTF-8). */ }
        attribute strictValidation : Integer { doc /* When non-zero, reject messages that violate structural or required-field rules. */ }
        attribute segmentWhitelist : String { doc /* Comma-separated segment IDs in scope for parsing; others may be ignored. */ }
        perform action initializeFromBinding : InitializeParser;
    }

    part def <Transformer> 'Transformer' :> PIM::LogicalArchitecture::Transformer {
        doc /* Refines PIM::LogicalArchitecture::Transformer. Technology binding: TypeScript/JavaScript (object to JSON). Field mapping configuration, JSON serialization strategy, optional schema validation. */
        attribute mappingConfigPath : String { doc /* Path or name of the field-mapping configuration (HL7 to JSON). */ }
        attribute jsonPrettyPrint : Integer { doc /* When non-zero, serialize JSON with indentation for readability. */ }
        attribute schemaValidateOutput : Integer { doc /* When non-zero, validate output JSON against a schema before forwarding. */ }
        perform action initializeFromBinding : InitializeTransformer;
    }

    part def <HTTPForwarder> 'HTTP Forwarder' :> PIM::LogicalArchitecture::HTTPForwarder {
        doc /* Refines PIM::LogicalArchitecture::HTTPForwarder. Technology binding: axios or undici (TLS, retry, timeout). HTTP client configuration: base URL, TLS settings, retry policy, timeout; request/response handling. */
        attribute baseUrl : String { doc /* Downstream REST API base URL for posting payloads. */ }
        attribute requestTimeoutMs : Integer { doc /* HTTP request timeout in milliseconds. */ }
        attribute maxRetries : Integer { doc /* Maximum retry attempts for transient failures (e.g. 503). */ }
        attribute retryBackoffMs : Integer { doc /* Initial backoff delay in milliseconds before first retry. */ }
        attribute tlsMinVersion : String { doc /* Minimum TLS version (e.g. TLSv1.2). */ }
        attribute tlsRejectUnauthorized : Integer { doc /* When non-zero, reject connections with invalid server certificates. */ }
        perform action initializeFromBinding : InitializeHTTPForwarder;
    }

    part def <ErrorHandler> 'Error Handler' :> PIM::LogicalArchitecture::ErrorHandler {
        doc /* Refines PIM::LogicalArchitecture::ErrorHandler. Technology binding: Node.js logging (e.g. pino). Error classification taxonomy (enum or policy), structured logger, metrics collector (success/failure/retry counters), dead-letter queue or file. */
        attribute logLevel : String { doc /* Minimum log level (e.g. info, warn, error). */ }
        attribute metricsPrefix : String { doc /* Prefix for exposed metrics (e.g. hl7_adapter). */ }
        attribute deadLetterPath : String { doc /* File path or queue identifier for messages that cannot be delivered after retries. */ }
        attribute classificationTaxonomy : String { doc /* Name or path of the error classification taxonomy (e.g. ParseError, DeliveryError). */ }
        perform action initializeFromBinding : InitializeErrorHandler;
    }

    part def <HL7AdapterService> 'HL7 Adapter Service' :> PIM::LogicalArchitecture::HL7AdapterService {
        doc /* Refines PIM HL7 Adapter Service. Technology binding: Node.js runtime; AWS Lambda or Docker (Terraform). Boundary ports use PSM interface bindings (MLLP ingress, HTTP egress). */
        port :>> fromUpstream : PSM_MLLPIngressPort;
        port :>> toDownstream : PSM_JSONEgressPort;

        part :>> mllpReceiver : MLLPReceiver;
        part :>> parser : Parser;
        part :>> transformer : Transformer;
        part :>> httpForwarder : HTTPForwarder;
        part :>> errorHandler : ErrorHandler;

        perform action bootstrap : BootstrapAdapter;
    }

    part def <ParseMllpResult> 'Parse MLLP Result' {
        doc /* Refines PIM::LogicalArchitecture::ParseMllpResult. Technology binding: Node.js net/socket or custom MLLP framing. Implementation comprises TCP socket listener (Node.js net.Server), MLLP framing parser (start/end byte and length), and connection manager (accept/close/timeout). Configurable host/port. */
        attribute payload : Buffer;
        attribute success : Boolean;
        attribute error : String;
        attribute consumed : Integer;
    }
}
