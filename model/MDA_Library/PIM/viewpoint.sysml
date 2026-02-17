package PIM_Viewpoint {

    doc /* PIM-specific viewpoint catalog aligned with the MDA standard viewpoint pattern. */

    private import MDA_Viewpoint::*;
    private import MDA_Structure::*;

    /* Generic PIM-level concerns */

    concern 'PIM logical coherence' {
        doc /* Ensure the PIM model provides a coherent, consistent logical decomposition and interface structure. */

        subject system : System;

        stakeholder se : SystemsEngineer;
        stakeholder tl : TechnicalLead;
    }

    concern 'PIM allocation completeness' {
        doc /* Ensure PIM-level requirements are fully allocated to logical architecture, interfaces, and behaviors. */

        subject system : System;

        stakeholder se : SystemsEngineer;
        stakeholder qa : QualityAssuranceLead;
    }

    concern 'PIM interface contract clarity' {
        doc /* Ensure logical interfaces, ports, and message contracts are well-defined and stable. */

        subject system : System;

        stakeholder se : SystemsEngineer;
        stakeholder tl : TechnicalLead;
    }

    concern 'PIM verification readiness' {
        doc /* Ensure there is sufficient PIM-level verification intent and coverage before entering PSM. */

        subject system : System;

        stakeholder se : SystemsEngineer;
        stakeholder qa : QualityAssuranceLead;
    }

    concern 'PIM gateway readiness' {
        doc /* Ensure there is adequate PIM evidence and consensus to pass the PIM lifecycle gateway. */

        subject system : System;

        stakeholder se : SystemsEngineer;
        stakeholder tl : TechnicalLead;
        stakeholder pm : ProjectManager;
    }

    /* PIM viewpoints specialized from the abstract MDA viewpoints */

    viewpoint def LogicalArchitectureViewpoint :> ArchitectureAndBehaviorViewpoint {
        doc /* Covers platform-independent decomposition, interfaces, and behavioral refinement. */

        frame 'PIM logical coherence';

        require constraint {
            doc /* A Logical Architecture view shall show the PIM-level components, their responsibilities, and key interfaces. */
        }
    }

    viewpoint def RequirementAllocationViewpoint :> StakeholderConcernsViewpoint {
        doc /* Covers system requirements, allocations, and traceability from CIM concerns to PIM design. */

        frame 'PIM allocation completeness';

        require constraint {
            doc /* A Requirement Allocation view shall show how PIM requirements trace to logical blocks, interfaces, and behaviors. */
        }
    }

    viewpoint def PIMVerificationReadinessViewpoint :> VerificationAndComplianceViewpoint {
        doc /* Covers platform-independent verification intent and criteria before PSM realization. */

        frame 'PIM verification readiness';

        require constraint {
            doc /* A PIM Verification Readiness view shall show verification objectives, planned cases, and coverage of PIM requirements. */
        }
    }

    viewpoint def PIMLifecycleGatewayReadinessViewpoint :> LifecycleGateReadinessViewpoint {
        doc /* Covers PIM gate readiness, unresolved design risks, and signoff evidence. */

        frame 'PIM gateway readiness';

        require constraint {
            doc /* A PIM Gateway Readiness view shall show entry criteria, design risks, and signoff evidence for the PIM gate. */
        }
    }
}

