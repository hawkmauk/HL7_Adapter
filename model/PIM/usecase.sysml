package PIM_UseCases {
    doc /* PIM design-level use cases with interaction elaborations between logical components. Refines CIM operational scenarios per AIM S5.6; includes human-in-the-loop (Integration Engineer, Operations Engineer) per AIM S7.3. */

    private import CIM::Stakeholders::*;
    private import CIM::Context::*;
    private import CIM::Domain::*;
    private import PIM::LogicalArchitecture::*;

    /* -----------------------------------------------------------------------
     * IngestAndForwardEvent — nominal flow: MLLPReceiver -> Parser -> Transformer -> HTTPForwarder
     * ----------------------------------------------------------------------- */

    use case def IngestAndForwardEvent {
        doc /* Design-level elaboration of CIM Ingest and Forward Event. Shows message sequence between PIM logical components (MLLPReceiver, Parser, Transformer, HTTPForwarder) and data flow with return signals. */
        objective {
            doc /* Refines CIM Ingest and Forward Event. Nominal path: receive MLLP frame, parse to HL7 message and metadata/demographics, transform to JSON payload, forward to downstream API. Integration Engineer and Operations Engineer are actors for configuration and monitoring. */
        }

        subject adapter : HL7AdapterService;
        actor integrationEngineer : IntegrationEngineer;
        actor operationsEngineer : OperationsEngineer;
    }

    occurrence def IngestAndForwardEventFlow {
        doc /* Sequence of messages between MLLPReceiver, Parser, Transformer, HTTPForwarder; data flow and return signals aligned with PIM::Behavior state machines. */

        use case ingestAndForwardEvent : IngestAndForwardEvent {
            part mllpReceiver[1] : MLLPReceiver {
                event occurrence frameCompleteSent;
            }
            part parser[1] : Parser {
                event occurrence frameReceived;
                then event occurrence hl7MessageCreatedSent;
            }
            part transformer[1] : Transformer {
                event occurrence transformRequestedReceived;
                then event occurrence jsonPayloadCreatedSent;
            }
            part httpForwarder[1] : HTTPForwarder {
                event occurrence payloadReceived;
                then event occurrence httpSuccessSent;
            }

            message msgFrame of MLLPFrame[1] from mllpReceiver.frameCompleteSent to parser.frameReceived;
            message msgHL7AndExtracts of HL7Message[1] from parser.hl7MessageCreatedSent to transformer.transformRequestedReceived;
            message msgPayload of JSONPayload[1] from transformer.jsonPayloadCreatedSent to httpForwarder.payloadReceived;

            first msgFrame then msgHL7AndExtracts;
            first msgHL7AndExtracts then msgPayload;
        }
    }

    /* -----------------------------------------------------------------------
     * HandleParseFailure — Parser to ErrorHandler: classification and logging
     * ----------------------------------------------------------------------- */

    use case def HandleParseFailure {
        doc /* Design-level elaboration: Parser to ErrorHandler interaction including classification and logging steps. */
        objective {
            doc /* Refines CIM Handle Integration Error for parse path. Parser raises parse error; ErrorHandler classifies and logs; optionally escalates to Operations Engineer. */
        }

        subject adapter : HL7AdapterService;
        actor operationsEngineer : OperationsEngineer;
    }

    occurrence def HandleParseFailureFlow {
        doc /* Parser emits parse failure; ErrorHandler receives, classifies, logs; optional human-in-the-loop escalation. */

        use case handleParseFailure : HandleParseFailure {
            part parser[1] : Parser {
                event occurrence parseFailedSent;
            }
            part errorHandler[1] : ErrorHandler {
                event occurrence errorReceived;
                then event occurrence classificationCompletedSent;
            }
            part opsEngineer[1] :> operationsEngineer {
                event occurrence escalationAcknowledged;
            }

            message msgParseError of ParseError[1] from parser.parseFailedSent to errorHandler.errorReceived;
            message msgEscalationToOps of IntegrationError[1] from errorHandler.classificationCompletedSent to opsEngineer.escalationAcknowledged;

            first msgParseError then msgEscalationToOps;
        }

    }

    /* -----------------------------------------------------------------------
     * HandleDeliveryFailure — HTTPForwarder to ErrorHandler and retry loop
     * ----------------------------------------------------------------------- */

    use case def HandleDeliveryFailure {
        doc /* Design-level elaboration: HTTPForwarder to ErrorHandler and retry loop; optional human-in-the-loop for retry decision or escalation. */
        objective {
            doc /* Refines CIM Handle Integration Error for delivery path. HTTPForwarder reports delivery failure; ErrorHandler records; retry loop (SendJSONRequested until success or max retries); Operations Engineer for escalation. */
        }

        subject adapter : HL7AdapterService;
        actor operationsEngineer : OperationsEngineer;
    }

    occurrence def HandleDeliveryFailureFlow {
        doc /* HTTPForwarder reports failure (HTTP5xx/network); ErrorHandler receives; retry loop; on max retries exceeded, optional escalation to Operations Engineer. */

        use case handleDeliveryFailure : HandleDeliveryFailure {
            part httpForwarder[1] : HTTPForwarder {
                event occurrence deliveryFailureSent;
                then event occurrence retryRequestedReceived;
                then event occurrence maxRetriesExceededSent;
            }
            part errorHandler[1] : ErrorHandler {
                event occurrence deliveryErrorReceived;
                then event occurrence retryRequestedSent;
            }
            part opsEngineer[1] :> operationsEngineer {
                event occurrence retryOrEscalateAcknowledged;
            }

            message msgDeliveryError of DeliveryError from httpForwarder.deliveryFailureSent to errorHandler.deliveryErrorReceived;
            message msgRetryRequest of JSONPayload from errorHandler.retryRequestedSent to httpForwarder.retryRequestedReceived;
            message msgMaxRetriesExceeded of DeliveryError from httpForwarder.maxRetriesExceededSent to opsEngineer.retryOrEscalateAcknowledged;

            first msgDeliveryError then msgRetryRequest;
            first msgRetryRequest then msgMaxRetriesExceeded;
        }
    }
}
