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
    alias HTTPEgressBinding for PSM_HL7AdapterService_Interfaces::HTTPForwarderOutputPort;

    action def <InitializeAdapter> 'Initialize Adapter' :> CIM::Actions::Initialize {
        in config : CIM::Domain::Configuration;
        in :> self : HL7AdapterService;
        doc /* Bindings and service reference; then start listeners (MLLP, RestApi) per state machine do action; wire component events to service dispatch and current-message state. */
        rep functionBody language "TypeScript"
        /*
  this.operationalStore.initializeFromBinding(config.operationalStore);
  this.restApi.initializeFromBinding(this);
  this.mllpReceiver.startReceiver();

  this.mllpReceiver.on('transition', (ev: { signal: string }) => {
    if (ev.signal === 'MLLPFrameReceivedSignal') this.dispatch('MLLPFrameReceivedSignal');
    if (ev.signal === 'ListenerStartSignal') this.dispatch('ListenerStartSignal');
  });
  this.mllpReceiver.on('frameComplete', (payload: Buffer) => {
    this._currentFrame = payload;
    this.dispatch('MLLPFrameCompleteSignal');
  });

  this.parser.on('parseComplete', (data) => {
    this._currentParsed = data;
    this.dispatch('MLLPHandlerCompleteSignal');
  });
  this.parser.on('parseFailed', () => {
    this.dispatch('MLLPHandlerFailedSignal');
  });

  this.transformer.on('transformComplete', (jsonStr: string) => {
    this._currentJson = jsonStr;
    this.dispatch('HL7TransformerCompleteSignal');
  });
  this.transformer.on('transformFailed', () => {
    this.dispatch('HL7TransformerFailedSignal');
  });

  this.httpForwarder.on('deliverySuccess', () => {
    this.dispatch('HTTP2xxSignal');
  });
  this.httpForwarder.on('deliveryFailed', () => {
    this.dispatch('HTTP5xxOrNetworkErrorSignal');
  });

  this.dispatch('ServiceStartedSignal');
        */
    }

    action def <RecordMessageReceived> 'Record Message Received' {
        in :> self : HL7AdapterService;
        doc /* Store message in OperationalStore, record metrics, pass frame to Parser. Uses _currentFrame and sets _currentMessageId. */
        rep functionBody language "TypeScript"
        /*
  this._currentMessageId = `${Date.now()}-${Math.random().toString(36).slice(2)}`;
  const receivedAt = new Date().toISOString();
  const raw = this._currentFrame;
  const rawLength = raw?.length ?? 0;
  this.operationalStore.insertMessage(this._currentMessageId, receivedAt, 'received', undefined, undefined, rawLength);
  this.errorHandler.recordMessageReceived();
  if (raw) this.parser.handleIncomingMessage(raw.toString('utf8'));
        */
    }

    action def <RecordMessageParsed> 'Record Message Parsed' {
        in :> self : HL7AdapterService;
        doc /* Update store to parsed, record metrics, pass parsed data to Transformer. Uses _currentParsed and _currentMessageId. */
        rep functionBody language "TypeScript"
        /*
  this.operationalStore.updateMessageStatus(this._currentMessageId, 'parsed');
  this.errorHandler.recordMessageParsed();
  this.parser.dispatch('ResetComponentSignal');
  this.transformer.handleTransformRequest(this._currentParsed as any);
        */
    }

    action def <RecordMessageTransformed> 'Record Message Transformed' {
        in :> self : HL7AdapterService;
        doc /* Update store to transformed, record metrics, send JSON to HTTPForwarder. Uses _currentJson and _currentMessageId. */
        rep functionBody language "TypeScript"
        /*
  this.operationalStore.updateMessageStatus(this._currentMessageId, 'transformed');
  this.errorHandler.recordMessageTransformed();
  this.transformer.dispatch('ResetComponentSignal');
  const json = this._currentJson;
  if (json) this.httpForwarder.sendJSONPayload(json);
        */
    }

    action def <RecordMessageDelivered> 'Record Message Delivered' {
        in :> self : HL7AdapterService;
        doc /* Update store to delivered and record metrics. Called after HTTPForwarder emits success. */
        rep functionBody language "TypeScript"
        /*
  this.operationalStore.updateMessageStatus(this._currentMessageId, 'delivered');
  this.errorHandler.recordMessageDelivered();
  this.httpForwarder.dispatch('ResetComponentSignal');
        */
    }
}
