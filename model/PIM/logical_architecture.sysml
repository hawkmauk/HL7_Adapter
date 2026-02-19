package PIM_LogicalArchitecture {
    
    doc /* Logical architecture for the PIM system. Design-level components used as interaction participants in PIM use case elaborations. */

    part def MLLPReceiver {
        doc /* Receives MLLP frames from the listener and passes complete frames to the parser. */
    }

    part def Parser {
        doc /* Parses HL7 message from MLLP frame into metadata and demographics (HL7Handler in behavior). */
    }

    part def Transformer {
        doc /* Transforms HL7 message and extracted data into JSON payload (HL7Transformer in behavior). */
    }

    part def HTTPForwarder {
        doc /* Forwards JSON payload to downstream REST endpoint; handles retries on delivery failure. */
    }

    part def ErrorHandler {
        doc /* Classifies and logs integration errors; supports escalation (e.g. to Operations Engineer). */
    }
}