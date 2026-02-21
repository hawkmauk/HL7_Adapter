package PSM_HL7AdapterService_Actions {

    private import PSM_MLLPReceiver_Actions::*;
    private import PSM_Parser_Actions::*;
    private import PSM_Transformer_Actions::*;
    private import PSM_HTTPForwarder_Actions::*;
    private import PSM_ErrorHandler_Actions::*;
    private import PSM_HL7AdapterService_Interfaces::*;
    private import PSM_HL7AdapterService::*;

    doc /* PSM action definitions. Component actions live in per-component packages; this package re-exports them and defines BootstrapAdapter. */

    alias ParseMllpFrame for PSM_MLLPReceiver_Actions::ParseMllpFrame;
    alias BuildMllpMessage for PSM_MLLPReceiver_Actions::BuildMllpMessage;
    alias BuildAck for PSM_MLLPReceiver_Actions::BuildAck;
    alias BuildNak for PSM_MLLPReceiver_Actions::BuildNak;
    alias StartReceiver for PSM_MLLPReceiver_Actions::StartReceiver;
    alias StopReceiver for PSM_MLLPReceiver_Actions::StopReceiver;
    alias InitializeMLLPReceiver for PSM_MLLPReceiver_Actions::InitializeMLLPReceiver;

    alias ParseHL7Message for PSM_Parser_Actions::ParseHL7Message;
    alias HandleIncomingHL7 for PSM_Parser_Actions::HandleIncomingHL7;
    alias InitializeParser for PSM_Parser_Actions::InitializeParser;

    alias TransformToJSON for PSM_Transformer_Actions::TransformToJSON;
    alias HandleTransformRequest for PSM_Transformer_Actions::HandleTransformRequest;
    alias InitializeTransformer for PSM_Transformer_Actions::InitializeTransformer;

    alias InitializeHTTPForwarder for PSM_HTTPForwarder_Actions::InitializeHTTPForwarder;
    alias InitializeErrorHandler for PSM_ErrorHandler_Actions::InitializeErrorHandler;

    alias MLLPIngressBinding for PSM_HL7AdapterService_Interfaces::PSM_MLLPIngressPort;
    alias HTTPEgressBinding for PSM_HL7AdapterService_Interfaces::PSM_JSONEgressPort;

    action def <BootstrapAdapter> 'Bootstrap Adapter' {
        in mllpBinding : MLLPIngressBinding;
        in httpBinding : HTTPEgressBinding;
        in :> self : HL7AdapterService;
        doc /* Supply bindings once and initialize the whole adapter. Composes: invoke InitializeMLLPReceiver on self.mllpReceiver with mllpBinding and runtimeConfig; InitializeParser on self.parser with runtimeConfig; InitializeTransformer on self.transformer with runtimeConfig; InitializeHTTPForwarder on self.httpForwarder with httpBinding and runtimeConfig; InitializeErrorHandler on self.errorHandler with runtimeConfig. */
    }
}
