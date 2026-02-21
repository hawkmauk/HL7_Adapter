package PSM_MLLPReceiverComponent_Interface {

    /* =======================================================================
     * MLLP Ingress Binding
     * TCP socket parameters, MLLP block characters (0x0B, 0x1C, 0x0D), buffers.
     * Technology: Node.js net/socket. Refs: SYS1.1–SYS1.5.
     * ======================================================================= */

    private import ScalarValues::*;
    private import PIM::Interfaces::*;
    private import CIM::Domain::*;
    private import PIM::Behavior::*;

    part def <MLLPIngressBinding> 'MLLP Ingress Binding' {
        doc /* Protocol binding for MLLP ingress. TCP listener (Node.js net.Server), MLLP framing with start/end block characters, configurable buffer sizes. */

        attribute bindHost : String { doc /* Listen address (e.g. 0.0.0.0). Default from config. */ }
        attribute bindPort : Integer = 2575 { doc /* TCP port for MLLP listener. */ }
        attribute connectionBacklog : Integer = 128 { doc /* Socket listen backlog. */ }
        attribute connectionIdleTimeoutMs : Integer = 60000 { doc /* Idle timeout before closing connection (ms). */ }

        attribute mllpStartBlock : Integer = 11 { doc /* MLLP start block character (0x0B). */ }
        attribute mllpEndBlockFirst : Integer = 28 { doc /* MLLP end block first byte (0x1C). */ }
        attribute mllpEndBlockSecond : Integer = 13 { doc /* MLLP end block second byte (0x0D). */ }

        attribute receiveBufferSizeBytes : Integer = 65536 { doc /* TCP receive buffer size. */ }
        attribute maxPayloadSizeBytes : Integer = 1048576 { doc /* Max MLLP payload size; frames exceeding are rejected. */ }
    }

    port def <PSM_MLLPIngressPort> 'PSM MLLP Ingress Port' :> MLLPIngressPort {
        doc /* Adapter receives MLLP frame; protocol detail in MLLPIngressBinding (TCP, 0x0B/0x1C/0x0D, buffer sizes). */
        in item ::> mllpFrame : MLLPFrame;
        in attribute ::> frameReceived : MLLPFrameReceivedSignal;
    }

}