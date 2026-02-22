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

    constraint def <MessageLifecycleAuditInScope> 'Message Lifecycle Audit In Scope' {
        doc /* Message and frame lifecycle audit (inbound MLLP frames and HL7 messages: received, parsed, transformed, delivered or failed) and queryable delivery/error history are in scope for M3.4.Audit Logging and M4.Operational Transparency. The solution may provide an operational data store to persist and expose this audit trail. */
    }
}
