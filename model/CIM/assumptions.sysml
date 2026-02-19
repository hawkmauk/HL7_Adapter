package CIM_Assumptions {
    doc /* Non-design assumptions and constraints shaping the challenge solution space. */

    constraint def <LocalExecutionOnly> 'Local Execution Only' {
        doc /* System execution is limited to a local development environment for the exercise. */
    }

    constraint def <MLLPTransportRequired> 'MLLP Transport Required' {
        doc /* HL7 transport from publisher to receiver uses Minimal Lower Layer Protocol framing. */
    }

    constraint def <HTTPSForwardingRequired> 'HTTPS Forwarding Required' {
        doc /* Outbound payload delivery uses an HTTPS REST endpoint interface. */
    }

    constraint def <LimitedScopeTesting> 'Limited Scope Testing' {
        doc /* Verification scope includes representative and limited test cases rather than full certification coverage. */
    }

    constraint def <PHIHandlingPolicy> 'PHI Handling Policy' {
        doc /* Patient-related data must be handled in a manner consistent with security and compliance expectations. */
    }
}
