package PSM_PhysicalArchitecture {

    private import PIM::*;
    private import PSM::Interfaces::*;
    private import PSM::Actions::*;
    private import ScalarValues::*;
    private import CIM::Datatype::*;

    private import MLLPReceiver_Structure::*;
    private import PSM_MLLPReceiver::*;
    private import PSM_Parser::*;
    private import PSM_Transformer::*;
    private import PSM_HTTPForwarder::*;
    private import PSM_ErrorHandler::*;

    doc /* PSM physical architecture: each PIM logical component refined with technology bindings and implementation-specific attributes (config, library types). Refines PIM::LogicalArchitecture. Each part is configured by the binding(s) that are inputs to its initializeFromBinding action: MLLPReceiver by MLLPIngressBinding and RuntimeConfigBinding; Parser, Transformer, ErrorHandler by RuntimeConfigBinding; HTTPForwarder by HTTPEgressBinding and RuntimeConfigBinding. */

    alias ParseMllpResult for MLLPReceiver_Structure::ParseMllpResult;
    alias MLLPReceiver for PSM_MLLPReceiver::MLLPReceiver;
    alias Parser for PSM_Parser::Parser;
    alias Transformer for PSM_Transformer::Transformer;
    alias HTTPForwarder for PSM_HTTPForwarder::HTTPForwarder;
    alias ErrorHandler for PSM_ErrorHandler::ErrorHandler;

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
}
