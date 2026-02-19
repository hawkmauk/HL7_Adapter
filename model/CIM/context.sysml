package CIM_Context {

    private import ScalarValues::*;
    private import ISQ::*;

    doc /* Operational context in which the adapter is used as a black-box service. */

    part def <HL7AdapterService> 'HL7 Adapter Service' {
        doc /* Conceptual service that receives HL7 via MLLP, transforms to JSON, and forwards to API. */

        attribute maxMllpFramePayloadSize : Integer = 4096;
    }

    part def <LocalDevelopmentEnvironment> 'Local Development Environment' {
        doc /* Local machine and process environment used for challenge execution and testing. */
    }

    part def <NetworkBoundary> 'Network Boundary' {
        doc /* Boundary separating MLLP ingress and HTTPS egress communication domains. */
    }

    part def <RuntimeConfiguration> 'Runtime Configuration' {
        doc /* Conceptual runtime settings such as host, port, endpoint URL, and security options. */
    }
}
