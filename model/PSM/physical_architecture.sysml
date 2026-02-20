package PSM_PhysicalArchitecture {

    private import PIM::*;

    doc /* PSM physical architecture: each PIM logical component refined with technology bindings (Node.js/TypeScript, AWS). Supports Lyrebird stack alignment and PIM requirements. */

    part def <MLLPReceiver> 'MLLP Receiver' :> PIM::LogicalArchitecture::MLLPReceiver {
        doc /* Refines PIM MLLP Receiver. Technology binding: Node.js net/socket or custom MLLP framing. */
    }

    part def <Parser> 'Parser' :> PIM::LogicalArchitecture::Parser {
        doc /* Refines PIM Parser. Technology binding: node-hl7-complete (or selected Node HL7 library). */
    }

    part def <Transformer> 'Transformer' :> PIM::LogicalArchitecture::Transformer {
        doc /* Refines PIM Transformer. Technology binding: TypeScript/JavaScript (object to JSON). */
    }

    part def <HTTPForwarder> 'HTTP Forwarder' :> PIM::LogicalArchitecture::HTTPForwarder {
        doc /* Refines PIM HTTP Forwarder. Technology binding: axios or undici (TLS, retry, timeout). */
    }

    part def <ErrorHandler> 'Error Handler' :> PIM::LogicalArchitecture::ErrorHandler {
        doc /* Refines PIM Error Handler. Technology binding: Node.js logging / structured logging (e.g. pino). */
    }

    part def <HL7AdapterService> 'HL7 Adapter Service' :> PIM::LogicalArchitecture::HL7AdapterService {
        doc /* Refines PIM HL7 Adapter Service. Technology binding: Node.js runtime; AWS Lambda or Docker (Terraform). */
        part :>> mllpReceiver : MLLPReceiver;
        part :>> parser : Parser;
        part :>> transformer : Transformer;
        part :>> httpForwarder : HTTPForwarder;
        part :>> errorHandler : ErrorHandler;
    }
}
