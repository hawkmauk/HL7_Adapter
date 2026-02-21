package PIM_LogicalArchitecture {

    private import PIM::Interfaces::*;
    private import PIM::Behavior::*;
    private import CIM::Stakeholders::*;
    private import CIM::Context::*;

    doc /* Logical architecture for the PIM system. Ports are only on the boundary (UpstreamHL7System, HL7AdapterService, DownstreamAPIOwner). Internal components have no ports; data/signal flow between them is described in behavior and use case elaborations. Each component exhibits its state machine from PIM::Behavior, establishing traceable ownership. */

    part def <MLLPReceiver> 'MLLP Receiver' {
        doc /* Receives MLLP frames from the listener and passes complete frames to the parser. */
        exhibit mllpReceiver;
    }

    part def <Parser> 'Parser' {
        doc /* Parses HL7 message from MLLP frame into metadata and demographics. */
        exhibit hl7Handler;
    }

    part def <Transformer> 'Transformer' {
        doc /* Transforms HL7 message and extracted data into JSON payload. */
        exhibit hl7Transformer;
    }

    part def <HTTPForwarder> 'HTTP Forwarder' {
        doc /* Forwards JSON payload to downstream REST endpoint; handles retries. */
        exhibit httpForwarder;
    }

    part def <ErrorHandler> 'Error Handler' {
        doc /* Classifies and logs integration errors; supports escalation. */
        exhibit errorHandler;
    }

    part def HL7AdapterService :> CIM::Context::HL7AdapterService {
        doc /* Adapter at PIM level with boundary ports only. Internal composition of MLLPReceiver, Parser, Transformer, HTTPForwarder, ErrorHandler. Exhibits the top-level controller state machine. */
        exhibit hl7AdapterController;

        port fromUpstream : MLLPIngressPort;
        port toDownstream : JSONEgressPort;

        part mllpReceiver : MLLPReceiver;
        part parser : Parser;
        part transformer : Transformer;
        part httpForwarder : HTTPForwarder;
        part errorHandler : ErrorHandler;
    }
}
