package PIM_Interfaces {
    doc /* PIM interfaces at the system boundary only: UpstreamHL7System ↔ HL7AdapterService ↔ DownstreamAPIOwner. Signal-typed flow properties per AIM S7.5. Internal data flow between MLLPReceiver, Parser, Transformer, HTTPForwarder, ErrorHandler is not port-based. */

    private import CIM::Domain::*;
    private import CIM::Events::*;
    private import PIM::Behavior::*;

    /* -----------------------------------------------------------------------
     * Boundary: UpstreamHL7System → HL7AdapterService (MLLP ingress)
     * ----------------------------------------------------------------------- */

    port def <MLLPEgressPort> 'MLLP Egress Port' {
        doc /* Upstream system sends MLLP frame and frame-sent event to the adapter. */
        out item mllpFrame : MLLPFrame;
        out attribute frameSent : MLLPFrameCompleteSignal;
    }

    port def <MLLPIngressPort> 'MLLP Ingress Port' {
        doc /* Adapter receives MLLP frame and frame-received event from upstream. */
        in item mllpFrame : MLLPFrame;
        in attribute frameReceived : MLLPFrameReceivedSignal;
    }

    interface def <UpstreamToAdapter> 'Upstream to Adapter' {
        doc /* Boundary interface: UpstreamHL7System supplies MLLP frames to HL7AdapterService. */
        end supplierPort : MLLPEgressPort;
        end consumerPort : MLLPIngressPort;
    }

    /* -----------------------------------------------------------------------
     * Boundary: HL7AdapterService → DownstreamAPIOwner (JSON egress)
     * ----------------------------------------------------------------------- */

    port def <JSONEgressPort> 'JSON Egress Port' {
        doc /* Adapter sends JSON payload and payload-sent event to downstream. */
        out item jsonPayload : JSONPayload;
        out attribute payloadSent : SendJSONRequestedSignal;
        out attribute deliverySuccess : HTTP2xxSignal;
        out attribute deliveryFailure : HTTP5xxOrNetworkErrorSignal;
    }

    port def <JSONIngressPort> 'JSON Ingress Port' {
        doc /* Downstream system receives JSON payload and payload-received event from adapter. */
        in item jsonPayload : JSONPayload;
        in attribute payloadReceived : HTTP2xxSignal;
    }

    interface def <AdapterToDownstream> 'Adapter to Downstream' {
        doc /* Boundary interface: HL7AdapterService supplies JSON payloads to DownstreamAPIOwner. */
        end supplierPort : JSONEgressPort;
        end consumerPort : JSONIngressPort;
    }
}
