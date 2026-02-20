package PIM_LogicalArchitecture {

    private import PIM::Interfaces::*;
    private import CIM::Stakeholders::*;
    private import CIM::Context::*;

    doc /* Logical architecture for the PIM system. Ports are only on the boundary (UpstreamHL7System, HL7AdapterService, DownstreamAPIOwner). Internal components have no ports; data/signal flow between them is described in behavior and use case elaborations. */

    part def <MLLPReceiver> 'MLLP Receiver' {
        doc /* Receives MLLP frames from the listener and passes complete frames to the parser. Receptions: MLLPFrameReceivedSignal, MLLPFrameCompleteSignal, MLLPFrameErrorSignal (from PIM::Behavior). */
    }

    part def <Parser> 'Parser' {
        doc /* Parses HL7 message from MLLP frame into metadata and demographics (HL7Handler in behavior). Receptions: MLLPFrameCompleteSignal; sends HL7HandlerCompleteSignal, HL7HandlerFailedSignal. */
    }

    part def <Transformer> 'Transformer' {
        doc /* Transforms HL7 message and extracted data into JSON payload (HL7Transformer in behavior). Receptions: HL7TransformRequestedSignal; sends HL7TransformerCompleteSignal, HL7TransformerFailedSignal. */
    }

    part def <HTTPForwarder> 'HTTP Forwarder' {
        doc /* Forwards JSON payload to downstream REST endpoint; handles retries. Receptions: SendJSONRequestedSignal; sends HTTP2xxSignal, HTTP5xxOrNetworkErrorSignal, ForwarderMaxRetriesExceededSignal. */
    }

    part def <ErrorHandler> 'Error Handler' {
        doc /* Classifies and logs integration errors; supports escalation. Receptions: IntegrationErrorRaisedSignal, ClassificationCompletedSignal, RequiresEscalationSignal, EscalationCompletedSignal. */
    }

    part def HL7AdapterService :> CIM::Context::HL7AdapterService {
        doc /* Adapter at PIM level with boundary ports only. Internal composition of MLLPReceiver, Parser, Transformer, HTTPForwarder, ErrorHandler; internal flow is not port-based. */
        port fromUpstream : MLLPIngressPort;
        port toDownstream : JSONEgressPort;

        part mllpReceiver : MLLPReceiver;
        part parser : Parser;
        part transformer : Transformer;
        part httpForwarder : HTTPForwarder;
        part errorHandler : ErrorHandler;
    }
}
