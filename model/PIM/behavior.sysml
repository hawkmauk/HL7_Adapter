package PIM_Behavior {

    private import CIM::*;
    private import CIM::Domain::*;
    private import CIM::Actions::*;

    doc
    /* PIM-level behavior for the HL7 Adapter, modeled with state machines for each logical
       component and a top-level controller. Transitions are driven by signals that are
       conceptually mapped to CIM::Events occurrences (e.g. MLLP frame received, HL7 message
       transformed, JSON payload sent/received, integration errors). */

    /* -----------------------------------------------------------------------
     * Signals (PIM-level triggers mapped from CIM::Events)
     * --------------------------------------------------------------------- */

    attribute def ListenerStartSignal;
    attribute def ListenerStopSignal;

    attribute def MLLPFrameReceivedSignal;
    attribute def MLLPFrameCompleteSignal;
    attribute def MLLPFrameCreatedSignal;
    attribute def MLLPFrameErrorSignal;

    attribute def MLLPHandlerCompleteSignal;
    attribute def MLLPHandlerFailedSignal;

    attribute def HL7MessageCreatedSignal;
    attribute def HL7HandlerCompleteSignal;
    attribute def HL7HandlerFailedSignal;

    attribute def HL7TransformRequestedSignal;
    attribute def HL7TransformerCompleteSignal;
    attribute def HL7TransformerFailedSignal;

    attribute def SendJSONRequestedSignal;
    attribute def HTTP2xxSignal;
    attribute def HTTP5xxOrNetworkErrorSignal;
    attribute def ForwarderMaxRetriesExceededSignal;

    attribute def IntegrationErrorRaisedSignal;
    attribute def RequiresEscalationSignal;
    attribute def EscalationCompletedSignal;

    attribute def ClassificationCompletedSignal;

    attribute def ResetComponentSignal;

    doc
    /* Signal-to-CIM event mapping (conceptual)
       - MLLPFrameReceivedSignal / MLLPFrameCompleteSignal correspond to CIM::Events::MLLPFrameReceived.
       - HL7TransformSucceededSignal corresponds to CIM::Events::HL7MessageTransformed.
       - SendJSONRequestedSignal / HTTP2xxSignal / HTTP5xxOrNetworkErrorSignal align with
         CIM::Events::JSONPayloadSent / JSONPayloadReceived and IntegrationError handling.
       - IntegrationErrorRaisedSignal is raised when CIM-level errors (e.g. parse/delivery)
         are detected and propagated into PIM ErrorHandler behavior.
       These signals are PIM-level triggers for the state machines below. */

    /* PIM action usages refining CIM::Operations for state entry/do/exit binding. */
    action receiveMLLPFrame : ReceiveMLLPFrame;
    action createHL7Message : CreateHL7Message;
    action createMetadata : CreateMetadata;
    action createDemographics : CreateDemographics;
    action createJsonPayload : CreateJsonPayload;
    action sendJSONPayload : SendJSONPayload;
    action handleIntegrationError : HandleIntegrationError;

    /* -----------------------------------------------------------------------
     * MLLPReceiver state machine
     * This state machine is responsible for receiving an MLLPFrame from the listener.
     * --------------------------------------------------------------------- */

    state def MLLPReceiverStates;

    state mllpReceiver : MLLPReceiverStates {
        entry; then Idle;

        state Idle;
        accept ListenerStartSignal
            then Listening;

        state Listening;
        accept MLLPFrameReceivedSignal
            then Receiving;
        accept ListenerStopSignal
            then Idle;

        state Receiving {
            do receiveMLLPFrame;
        }
        accept MLLPFrameCompleteSignal
            then FrameComplete;
        accept MLLPFrameErrorSignal
            then Error;

        state FrameComplete;
        accept MLLPFrameReceivedSignal
            then Receiving;

        state Error;
        accept ResetComponentSignal
            then Idle;
    }

    /* -----------------------------------------------------------------------
     * MLLPHandler state machine
     * This state machine is responsible for creating an HL7Message from an
     * MLLPFrame.
     * --------------------------------------------------------------------- */

    state def MLLPHandlerStates;

    state  mllpHandler : MLLPHandlerStates {

        in mllpFrame : MLLPFrame;

        entry; then Idle;

        state Idle;
        accept MLLPFrameCreatedSignal
            then CreatingHL7Message;

        state CreatingHL7Message {
            entry createHL7Message { in mllpFrame = mllpFrame; }
        }
        accept MLLPHandlerCompleteSignal
            then Complete;
        accept MLLPHandlerFailedSignal
            then Error;

        state Complete;
        accept ResetComponentSignal
            then Idle;

        state Error;
        accept ResetComponentSignal
            then Idle;
    }

    /* -----------------------------------------------------------------------
     * Parser state machine
     * This state machine is responsible for parsing an HL7Message into a
     * MessageMetadata and PatientDemographics.
     * --------------------------------------------------------------------- */

    state def HL7HandlerStates;

    state hl7Handler : HL7HandlerStates {

        in hl7Message : HL7Message;

        entry; then Idle;

        state Idle;
        accept HL7MessageCreatedSignal
            then Parsing;

        state Parsing {
            entry createMetadata { in hl7Message = hl7Message; }
            do createDemographics { in hl7Message = hl7Message; }
        }
        accept HL7HandlerCompleteSignal
            then Complete;
        accept HL7HandlerFailedSignal
            then Error;

        state Complete;
        accept ResetComponentSignal
            then Idle;

        state Error;
        accept ResetComponentSignal
            then Idle;
    }

    /* -----------------------------------------------------------------------
     * Transformer state machine
     * This state machine is responsible for transforming an HL7Message into a
     * JSONPayload.
     * --------------------------------------------------------------------- */

    state def HL7TransformerStates;

    state hl7Transformer : HL7TransformerStates {

        in hl7Message : HL7Message;
        in 'metadata' : MessageMetadata;
        in demographics : PatientDemographics;

        entry; then Idle;

        state Idle;
        accept HL7TransformRequestedSignal
            then Mapping;

        state Mapping {
            do createJsonPayload { in 'metadata' = 'metadata'; in demographics = demographics; }
        }
        accept HL7TransformerCompleteSignal
            then Complete;
        accept HL7TransformerFailedSignal
            then Error;

        state Complete;
        accept ResetComponentSignal
            then Idle;

        state Error;
        accept ResetComponentSignal
            then Idle;
    }

    /* -----------------------------------------------------------------------
     * HTTPForwarder state machine
     * This state machine is responsible for forwarding a JSONPayload to a
     * downstream system.
     * --------------------------------------------------------------------- */

    state def HTTPForwarderStates;

    state httpForwarder : HTTPForwarderStates {

        in jsonPayload : JSONPayload;

        entry; then Idle;

        state Idle;
        accept SendJSONRequestedSignal
            then Sending;

        state Sending {
            do sendJSONPayload { in jsonPayload = jsonPayload; }
        }
        accept HTTP2xxSignal
            then Success;
        accept HTTP5xxOrNetworkErrorSignal
            then Retrying;
        accept ForwarderMaxRetriesExceededSignal
            then Failed;

        state Success;
        accept ResetComponentSignal
            then Idle;

        state Retrying;
        accept ForwarderMaxRetriesExceededSignal
            then Failed;
        accept SendJSONRequestedSignal
            then Sending;

        state Failed;
        accept ResetComponentSignal
            then Idle;
    }

    /* -----------------------------------------------------------------------
     * ErrorHandler state machine
     * This state machine is responsible for handling integration errors.
     * --------------------------------------------------------------------- */

    state def ErrorHandlerStates;

    state errorHandler : ErrorHandlerStates {

        in integrationError : IntegrationError;

        entry; then Idle;

        state Idle;
        accept IntegrationErrorRaisedSignal
            then Classifying;

        state Classifying {
            do handleIntegrationError { in integrationError = integrationError; }
        }
        accept RequiresEscalationSignal
            then Escalating;
        accept EscalationCompletedSignal
            then Resolved;

        state Escalating;
        accept EscalationCompletedSignal
            then Resolved;

        state Resolved;
        accept ResetComponentSignal
            then Idle;
    }

    /* -----------------------------------------------------------------------
     * Top-level HL7Adapter controller state machine
     * This state machine is responsible for coordinating the other state machines.
     * --------------------------------------------------------------------- */

    state def HL7AdapterControllerStates;

    state hl7AdapterController : HL7AdapterControllerStates {
        entry; then Idle;

        state Idle;
        accept ListenerStartSignal
            then Starting;

        state Starting;
        accept MLLPFrameReceivedSignal
            then ReceivingFrame;

        state ReceivingFrame;
        accept MLLPFrameCompleteSignal
            then HandlingFrame;
        accept MLLPFrameErrorSignal
            then HandlingError;

        state HandlingFrame;
        accept MLLPHandlerCompleteSignal
            then HandlingHL7Message;
        accept MLLPHandlerFailedSignal
            then HandlingError;

        state HandlingHL7Message;
        accept HL7HandlerCompleteSignal
            then TransformingHL7Message;
        accept HL7HandlerFailedSignal
            then HandlingError;

        state TransformingHL7Message;
        accept HL7TransformerCompleteSignal
            then Forwarding;
        accept HL7TransformerFailedSignal
            then HandlingError;

        state Forwarding;
        accept HTTP2xxSignal
            then Idle;
        accept HTTP5xxOrNetworkErrorSignal
            then HandlingError;

        state HandlingError;
        accept IntegrationErrorRaisedSignal
            then HandlingError;
        accept ResetComponentSignal
            then Idle;
    }
}