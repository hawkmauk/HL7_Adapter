package PSM_HL7AdapterService {

    alias Action for PSM_HL7AdapterService_Actions;
    alias Interface for PSM_HL7AdapterService_Interfaces;

    alias MLLPReceiver for PSM_MllpReceiverComponent;
    alias Parser for PSM_ParserComponent;
    alias Transformer for PSM_TransformerComponent;
    alias HTTPForwarder for PSM_HTTPForwarderComponent;
    alias ErrorHandler for PSM_ErrorHandlerComponent;
    alias RestApi for PSM_RestApiComponent;
    
    alias MLLPIngressPort for MLLPReceiver::Interface::PSM_MLLPIngressPort;
    alias JSONEgressPort for HTTPForwarder::Interface::PSM_JSONEgressPort;

    doc /* PSM physical architecture: each PIM logical component refined with technology bindings and implementation-specific attributes (config, library types). Refines PIM::LogicalArchitecture. Each part is configured by the binding(s) that are inputs to its initializeFromBinding action: MLLPReceiver by MLLPIngressBinding and RuntimeConfigBinding; Parser, Transformer, ErrorHandler by RuntimeConfigBinding; HTTPForwarder by HTTPEgressBinding and RuntimeConfigBinding. */

    part def <HL7AdapterService> 'HL7 Adapter Service' :> PIM::LogicalArchitecture::HL7AdapterService {
        doc /* Refines PIM HL7 Adapter Service. Technology binding: Node.js runtime; AWS Lambda or Docker (Terraform). Boundary ports use PSM interface bindings (MLLP ingress, HTTP egress). */
        port :>> fromUpstream : MLLPIngressPort;
        port :>> toDownstream : JSONEgressPort;

        part :>> mllpReceiver : MLLPReceiver::MLLPReceiver;
        part :>> parser : Parser::Parser;
        part :>> transformer : Transformer::Transformer;
        part :>> httpForwarder : HTTPForwarder::HTTPForwarder;
        part :>> errorHandler : ErrorHandler::ErrorHandler;
        part :>> restApi : RestApi::RestApi;

        perform action initialize : Action::InitializeAdapter;
    }
}
