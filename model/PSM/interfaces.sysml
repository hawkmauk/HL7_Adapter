package PSM_Interfaces {
    doc /* PSM interface bindings: concrete protocol and API detail for MLLP ingress, HTTP egress, and runtime configuration. Refines PIM::Interfaces with technology bindings (Node.js net/socket, axios/undici, env/file/CLI). AIM S8.4. */

    private import PIM::Interfaces::*;
    private import PIM::Behavior::*;
    private import CIM::Domain::*;
    private import ScalarValues::*;

    /* =======================================================================
     * MLLP Ingress Binding
     * TCP socket parameters, MLLP block characters (0x0B, 0x1C, 0x0D), buffers.
     * Technology: Node.js net/socket. Refs: SYS1.1–SYS1.5.
     * ======================================================================= */

    part def <MLLPIngressBinding> 'MLLP Ingress Binding' {
        doc /* Protocol binding for MLLP ingress. TCP listener (Node.js net.Server), MLLP framing with start/end block characters, configurable buffer sizes. */

        attribute bindHost : String { doc /* Listen address (e.g. 0.0.0.0). Default from config. */ }
        attribute bindPort : Integer = 2575 { doc /* TCP port for MLLP listener. */ }
        attribute connectionBacklog : Integer = 128 { doc /* Socket listen backlog. */ }
        attribute connectionIdleTimeoutMs : Integer = 60000 { doc /* Idle timeout before closing connection (ms). */ }

        attribute mllpStartBlock : Integer = 11 { doc /* MLLP start block character (0x0B). */ }
        attribute mllpEndBlockFirst : Integer = 28 { doc /* MLLP end block first byte (0x1C). */ }
        attribute mllpEndBlockSecond : Integer = 13 { doc /* MLLP end block second byte (0x0D). */ }

        attribute receiveBufferSizeBytes : Integer = 65536 { doc /* TCP receive buffer size. */ }
        attribute maxPayloadSizeBytes : Integer = 1048576 { doc /* Max MLLP payload size; frames exceeding are rejected. */ }
    }

    /* =======================================================================
     * HTTP Egress Binding
     * HTTPS URL pattern, method POST, Content-Type application/json, TLS, auth.
     * Technology: axios/undici. Refs: SYS3.1–SYS3.5.
     * ======================================================================= */

    part def <HTTPEgressBinding> 'HTTP Egress Binding' {
        doc /* Protocol binding for HTTP egress to downstream API. HTTPS, POST, application/json; TLS and optional API key or OAuth. */

        attribute baseUrlPattern : String { doc /* Downstream REST base URL (e.g. https://api.example.com/v1). */ }
        attribute httpMethod : String = "POST" { doc /* HTTP method for posting payloads. */ }
        attribute contentType : String = "application/json" { doc /* Content-Type header value. */ }

        attribute tlsMinVersion : String = "TLSv1.2" { doc /* Minimum TLS version. */ }
        attribute tlsRejectUnauthorized : Integer = 1 { doc /* 1 = reject invalid server certificates. */ }

        attribute authenticationKind : String = "none" { doc /* none | apiKey | oauth2. */ }
        attribute apiKeyHeaderName : String { doc /* Header name for API key (e.g. X-API-Key). */ }
        attribute oauthTokenEndpoint : String { doc /* OAuth2 token endpoint URL when authenticationKind = oauth2. */ }

        attribute requestTimeoutMs : Integer = 30000 { doc /* HTTP request timeout (ms). */ }
        attribute maxRetries : Integer = 3 { doc /* Max retry attempts for transient failures. */ }
        attribute retryBackoffMs : Integer = 1000 { doc /* Initial backoff before first retry (ms). */ }
    }

    /* =======================================================================
     * Runtime Config Binding
     * Config source (env vars, config file, CLI args), schema reference, defaults.
     * ======================================================================= */

    part def <RuntimeConfigBinding> 'Runtime Config Binding' {
        doc /* Configuration source and schema. Enumerates parameters with types and defaults; config loaded from env, file, or CLI. */

        attribute configSource : String = "env" { doc /* env | file | cli (primary source). */ }
        attribute configFilePath : String { doc /* Path to config file when configSource includes file. */ }
        attribute envVarPrefix : String = "HL7_ADAPTER_" { doc /* Prefix for environment variables. */ }
        attribute configSchemaRef : String { doc /* Reference to config schema (path or name). */ }

        attribute bindHost : String = "0.0.0.0" { doc /* MLLP listen address. */ }
        attribute bindPort : Integer = 2575 { doc /* MLLP listen port. */ }
        attribute maxPayloadSize : Integer = 1048576 { doc /* Max MLLP payload (bytes). */ }
        attribute connectionIdleTimeoutMs : Integer = 60000 { doc /* MLLP connection idle timeout (ms). */ }
        attribute baseUrl : String { doc /* Downstream API base URL. */ }
        attribute requestTimeoutMs : Integer = 30000 { doc /* HTTP request timeout (ms). */ }
        attribute maxRetries : Integer = 3 { doc /* HTTP max retries. */ }
        attribute retryBackoffMs : Integer = 1000 { doc /* HTTP retry backoff (ms). */ }
        attribute tlsMinVersion : String = "TLSv1.2" { doc /* Min TLS version. */ }
        attribute logLevel : String = "info" { doc /* Log level (info, warn, error). */ }
        attribute metricsPrefix : String = "hl7_adapter" { doc /* Metrics name prefix. */ }
        attribute deadLetterPath : String { doc /* Dead-letter path or queue. */ }
    }

    /* =======================================================================
     * Protocol error codes and response mappings
     * ======================================================================= */

    part def <MLLPErrorMapping> 'MLLP Error Mapping' {
        doc /* MLLP protocol errors mapped to PIM signals and handling. Framing error, buffer overflow, connection reset, timeout -> MLLPFrameErrorSignal or connection close. */
    }

    part def <HTTPResponseMapping> 'HTTP Response Mapping' {
        doc /* HTTP status to delivery outcome. 2xx -> delivery success (HTTP2xxSignal); 4xx/5xx -> delivery failure (HTTP5xxOrNetworkErrorSignal); 503 -> retry; network error -> retry or fail after maxRetries. */
    }

    /* =======================================================================
     * PSM port and interface defs (refine PIM)
     * ======================================================================= */

    port def <PSM_MLLPIngressPort> 'PSM MLLP Ingress Port' :> MLLPIngressPort {
        doc /* Adapter receives MLLP frame; protocol detail in MLLPIngressBinding (TCP, 0x0B/0x1C/0x0D, buffer sizes). */
        in item ::> mllpFrame : MLLPFrame;
        in attribute ::> frameReceived : MLLPFrameReceivedSignal;
    }

    port def <PSM_MLLPEgressPort> 'PSM MLLP Egress Port' :> MLLPEgressPort {
        doc /* Upstream sends MLLP frame; protocol binding as MLLPIngressBinding (consumer side). */
        out item ::> mllpFrame : MLLPFrame;
        out attribute ::> frameSent : MLLPFrameCompleteSignal;
    }

    port def <PSM_JSONEgressPort> 'PSM JSON Egress Port' :> JSONEgressPort {
        doc /* Adapter sends JSON to downstream; protocol detail in HTTPEgressBinding (HTTPS, POST, application/json, TLS, auth). */
        out item ::> jsonPayload : JSONPayload;
        out attribute ::> payloadSent : SendJSONRequestedSignal;
        out attribute ::> deliverySuccess : HTTP2xxSignal;
        out attribute ::> deliveryFailure : HTTP5xxOrNetworkErrorSignal;
    }

    port def <PSM_JSONIngressPort> 'PSM JSON Ingress Port' :> JSONIngressPort {
        doc /* Downstream receives JSON; binding as HTTPEgressBinding. */
        in item ::> jsonPayload : JSONPayload;
        in attribute ::> payloadReceived : HTTP2xxSignal;
    }

    interface def <PSM_UpstreamToAdapter> 'PSM Upstream to Adapter' :> UpstreamToAdapter {
        doc /* Boundary interface with MLLP binding (TCP, MLLP chars, buffers). */
        end supplierPort : PSM_MLLPEgressPort;
        end consumerPort : PSM_MLLPIngressPort;
    }

    interface def <PSM_AdapterToDownstream> 'PSM Adapter to Downstream' :> AdapterToDownstream {
        doc /* Boundary interface with HTTP binding (HTTPS, POST, Content-Type, TLS, auth). */
        end supplierPort : PSM_JSONEgressPort;
        end consumerPort : PSM_JSONIngressPort;
    }
}
