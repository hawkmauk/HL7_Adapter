package CIM_Events {

    private import ScalarValues::*;

    doc
    /* Event occurrences represent technology‑agnostic send/receive points for messages
       between systems or components at CIM level (AIM S2.1, S7.5). The specific actions
       that produce or consume each event are documented on the individual occurrences. */

    occurrence def Created {
        doc /* This event will be used by Observable domain objects to signal their creation.
        It is the first of what could be many lifecycle events that could be raised by the object. */
    }

    occurrence def <MLLPFrameSent> 'MLLP Frame Sent' {
        doc /* Send end of an MLLP frame transaction. Produced by: SendMLLPFrame (upstream). */
    }

    occurrence def <MLLPFrameReceived> 'MLLP Frame Received' {
        doc /* Receive end of an MLLP frame transaction. Consumed by: ReceiveMLLPFrame (adapter). */
    }

    occurrence def <HL7MessageTransformed> 'HL7 Message Transformed' {
        doc /* Transformed end of an HL7 message transaction. Produced by: TransformHL7Message (adapter). Consumed by: SendJSONPayload (adapter). */
    }

    occurrence def <JSONPayloadSent> 'JSON Payload Sent' {
        doc /* Send end of a JSON payload transaction. Produced by: SendJSONPayload (adapter). */
    }

    occurrence def <JSONPayloadReceived> 'JSON Payload Received' {
        doc /* Receive end of a JSON payload transaction. Consumed by: ReceiveJSONPayload (downstream). */
    }
}
