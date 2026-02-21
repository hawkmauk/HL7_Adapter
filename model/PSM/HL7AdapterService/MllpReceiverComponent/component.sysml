package PSM_MllpReceiverComponent {

    alias Structure for PSM_MLLPReceiver_Structure;
    alias Action for PSM_MLLPReceiver_Actions;
    alias Interface for PSM_MLLPReceiverComponent_Interface;

    private import Action::*;
    private import ScalarValues::*;

    doc /* PSM MLLP Receiver component. Refines PIM::LogicalArchitecture::MLLPReceiver. */

    part def <MLLPReceiver> 'MLLP Receiver' :> PIM::LogicalArchitecture::MLLPReceiver {
        doc /* Refines PIM::LogicalArchitecture::MLLPReceiver. Technology binding: Node.js net/socket or custom MLLP framing. Implementation comprises TCP socket listener (Node.js net.Server), MLLP framing parser (start/end byte and length), and connection manager (accept/close/timeout). Configurable host/port. */
        attribute bindHost : String { doc /* Listen address for the MLLP server (e.g. 0.0.0.0 for all interfaces). */ }
        attribute bindPort : Integer { doc /* TCP port for MLLP listener (e.g. 2575). */ }
        attribute maxPayloadSize : Integer { doc /* Maximum MLLP payload size in bytes; frames exceeding this are rejected. */ }
        attribute connectionIdleTimeoutMs : Integer { doc /* Idle timeout in milliseconds before closing a connection. */ }

        constant mllpStartByte : Integer = 11 { doc /* MLLP start block character (0x0B). */ }
        constant mllpEndByteFirst : Integer = 28 { doc /* MLLP end block first byte (0x1C). */ }
        constant mllpEndByteSecond : Integer = 13 { doc /* MLLP end block second byte (0x0D). */ }

        perform action parseMllpFrame : ParseMllpFrame;
        perform action buildMllpMessage : BuildMllpMessage;
        perform action buildAck : BuildAck;
        perform action buildNak : BuildNak;
        perform action startReceiver : StartReceiver;
        perform action stopReceiver : StopReceiver;
        perform action initializeFromBinding : InitializeMLLPReceiver;

        rep textualRepresentation language "TypeScript"
        /*
import * as net from 'net';
        */

        rep classMembers language "TypeScript"
        /*
private _server: net.Server | null = null;
        */
    }
}
