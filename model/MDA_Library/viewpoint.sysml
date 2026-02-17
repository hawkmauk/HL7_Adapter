package MDA_Viewpoint {

    private import MDA_Structure::*;

    concern <StakeholderConcerns> 'Stakeholder Concerns' {
        doc /* Captures stakeholder identities, concerns, and concern-to-evidence traceability. */

        subject system : System;

        stakeholder s : Stakeholder;
    }

    concern <LifecycleGateReadiness> 'Lifecycle Gate Readiness' {
        doc /* Captures gateway entry/exit criteria, unresolved issues, and signoff status. */

        subject system : System;

        stakeholder s : Stakeholder;
    }

    concern <ArchitectureAndBehavior> 'Architecture and Behavior' {
        doc /* Captures structural and behavioral evidence needed for design and review decisions. */

        subject system : System;

        stakeholder s : Stakeholder;
    }

    concern <VerificationAndCompliance> 'Verification and Compliance' {
        doc /* Captures verification coverage and compliance posture evidence for approvals. */

        subject system : System;

        stakeholder s : Stakeholder;
    }

    abstract viewpoint def <StakeholderConcernsViewpoint> 'Stakeholder Concerns Viewpoint' {
        doc /* Captures stakeholder identities, concerns, and concern-to-evidence traceability. */

        frame 'Stakeholder Concerns';

        doc /* A Stakeholder Concerns viewpoint shall show stakeholders, their needs, and traceable CIM-level requirements. */
    }

    abstract viewpoint def <LifecycleGateReadinessViewpoint> 'Lifecycle Gate Readiness Viewpoint' {
        doc /* Captures gateway entry/exit criteria, unresolved issues, and signoff status. */

        frame 'Lifecycle Gate Readiness';

        doc /* A Lifecycle Gate Readiness viewpoint shall show gateway entry/exit criteria, unresolved issues, and signoff status. */
    }

    abstract
    viewpoint def <ArchitectureAndBehaviorViewpoint> 'Architecture and Behavior Viewpoint' {
        doc /* Captures structural and behavioral evidence needed for design and review decisions. */

        frame 'Architecture and Behavior';

        doc /* A Architecture and Behavior viewpoint shall show structural and behavioral evidence needed for design and review decisions. */
    }

    abstract
    viewpoint def <VerificationAndComplianceViewpoint> 'Verification and Compliance Viewpoint' {
        doc /* Captures verification coverage and compliance posture evidence for approvals. */

        frame 'Verification and Compliance';

        doc /* A Verification and Compliance viewpoint shall show verification coverage and compliance posture evidence for approvals. */
    }
}