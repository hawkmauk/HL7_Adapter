package MDA_Lifecycle {
    
    doc /* Project lifecycle gates and signoff artifacts used across CIM/PIM/PSM. */

    enum def LifecyclePhase {
        enum Concept;
        enum LogicalDesign;
        enum PlatformRealization;
        enum ValidationAndRelease;
    }

    enum def SignoffStatus {
        enum Draft;
        enum InReview;
        enum Approved;
        enum Rejected;
    }

    part def <LifecycleMilestone> 'Lifecycle Milestone' {
        doc /* A governance checkpoint where evidence is reviewed and stakeholders approve progression. */
    }

    part def <GatewayCheck> 'Gateway Check' {
        doc /* Review activity validating model quality, stakeholder concern coverage, and readiness to proceed. */
    }

    part def <SignoffRecord> 'Signoff Record' {
        doc /* Persistent evidence of stakeholder consensus, approvals, and open issues at a milestone. */
    }

    part def <CIMConsensusGateway> 'CIM Consensus Gateway' :> 'Lifecycle Milestone' {
        doc /* CIM milestone where stakeholders confirm model validity and concern coverage before entering PIM. */
    }

    part def <PIMConsensusGateway> 'PIM Consensus Gateway' :> 'Lifecycle Milestone' {
        doc /* PIM milestone where stakeholders confirm logical architecture and traceability before entering PSM. */
    }

    part def <PSMReleaseGateway> 'PSM Release Gateway' :> 'Lifecycle Milestone' {
        doc /* PSM milestone where implementation, verification evidence, and operational readiness are approved. */
    }
}
