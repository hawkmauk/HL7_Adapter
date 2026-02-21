package PSM_HL7AdapterService_Interfaces {
    doc /* PSM interface bindings: concrete protocol and API detail for MLLP ingress, HTTP egress, and runtime configuration. Refines PIM::Interfaces with technology bindings (Node.js net/socket, axios/undici, env/file/CLI). AIM S8.4. */

    private import PIM::Interfaces::*;
    private import PIM::Behavior::*;
    private import CIM::Domain::*;
    private import ScalarValues::*;

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


    port def <PSM_MLLPEgressPort> 'PSM MLLP Egress Port' :> MLLPEgressPort {
        doc /* Upstream sends MLLP frame; protocol binding as MLLPIngressBinding (consumer side). */
        out item ::> mllpFrame : MLLPFrame;
        out attribute ::> frameSent : MLLPFrameCompleteSignal;
    }

    port def <PSM_JSONIngressPort> 'PSM JSON Ingress Port' :> JSONIngressPort {
        doc /* Downstream receives JSON; binding as HTTPEgressBinding. */
        in item ::> jsonPayload : JSONPayload;
        in attribute ::> payloadReceived : HTTP2xxSignal;
    }

    alias PSM_MLLPIngressPort for PSM_HL7AdapterService::MLLPReceiver::Interface::PSM_MLLPIngressPort;

    interface def <PSM_UpstreamToAdapter> 'PSM Upstream to Adapter' :> UpstreamToAdapter {
        doc /* Boundary interface with MLLP binding (TCP, MLLP chars, buffers). */
        end supplierPort : PSM_MLLPEgressPort;
        end consumerPort : PSM_MLLPIngressPort;
    }

    alias PSM_JSONEgressPort for PSM_HL7AdapterService::HTTPForwarder::Interface::PSM_JSONEgressPort;

    interface def <PSM_AdapterToDownstream> 'PSM Adapter to Downstream' :> AdapterToDownstream {
        doc /* Boundary interface with HTTP binding (HTTPS, POST, Content-Type, TLS, auth). */
        end supplierPort : PSM_JSONEgressPort;
        end consumerPort : PSM_JSONIngressPort;
    }
}
