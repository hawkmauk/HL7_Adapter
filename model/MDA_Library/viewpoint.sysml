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

    concern <CodeRealization> 'Code Realization' {
        doc /* Captures model content selected for executable artifact generation (e.g. code). */

        subject system : System;

        stakeholder s : Stakeholder;
    }

    abstract viewpoint def <DocumentationViewpoint> 'Documentation Viewpoint' {
        doc /* Viewpoint type for documentation rendering. Views satisfying this are consumed by documentation targets (e.g. LaTeX). */

        frame 'Architecture and Behavior';

        doc /* A Documentation viewpoint shall expose model content for human-readable documentation. */
    }

    abstract viewpoint def <ExecutableViewpoint> 'Executable Viewpoint' {
        doc /* Viewpoint type for executable artifact generation. Views satisfying this are consumed by code-generation targets (e.g. TypeScript). */

        frame 'Code Realization';

        doc /* An Executable viewpoint shall expose model content for code or other runnable artifact generation. */
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