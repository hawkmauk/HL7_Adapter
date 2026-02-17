package 'PIM-ViewLibrary' {
    private import Views::*;
    private import ViewLibrary::StandardViewpointCatalog::*;

    package PIMStandardViewpointCatalog {
        doc /* PIM-specific viewpoint catalog specializing the abstract lifecycle documentation contract. */

        viewpoint def LogicalArchitectureViewpoint :> ArchitectureAndBehaviorViewpoint {
            doc /* Covers platform-independent decomposition, interfaces, and behavioral refinement. */
        }

        viewpoint def RequirementAllocationViewpoint :> StakeholderConcernsViewpoint {
            doc /* Covers system requirements, allocations, and traceability from CIM concerns to PIM design. */
        }

        viewpoint def PIMVerificationReadinessViewpoint :> VerificationAndComplianceViewpoint {
            doc /* Covers platform-independent verification intent and criteria before PSM realization. */
        }

        viewpoint def PIMLifecycleGatewayReadinessViewpoint :> LifecycleGateReadinessViewpoint {
            doc /* Covers PIM gate readiness, unresolved design risks, and signoff evidence. */
        }
    }
}
