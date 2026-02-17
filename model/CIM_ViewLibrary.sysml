package 'CIM-ViewLibrary' {
    private import Views::*;
    private import ProjectLifecycle::StandardDocumentationFramework::StandardViewpointCatalog::*;

    package CIMStandardStructure {
        doc /* Reusable contract for CIM organization across projects. */

        requirement def CIM_DomainPackageRequired {
            doc /* A conforming CIM shall include the package CIM::Domain. */
        }

        requirement def CIM_StakeholdersPackageRequired {
            doc /* A conforming CIM shall include the package CIM::Stakeholders. */
        }

        requirement def CIM_ContextPackageRequired {
            doc /* A conforming CIM shall include the package CIM::Context. */
        }

        requirement def CIM_OperationsPackageRequired {
            doc /* A conforming CIM shall include the package CIM::Operations. */
        }

        requirement def CIM_MissionPackageRequired {
            doc /* A conforming CIM shall include the package CIM::Mission. */
        }

        requirement def CIM_AssumptionsPackageRequired {
            doc /* A conforming CIM shall include the package CIM::Assumptions. */
        }
    }

    package CIMStandardViewpointCatalog {
        doc /* CIM-specific viewpoint catalog that specializes the cross-model abstract standard viewpoint catalog. */

        viewpoint def StakeholderNeedsViewpoint :> StakeholderConcernsViewpoint {
            doc /* Covers stakeholder intent, outcomes, and traceability concerns. */
        }

        viewpoint def ConOpsViewpoint :> ArchitectureAndBehaviorViewpoint {
            doc /* Covers mission, operational context, and assumptions for system use. */
        }

        viewpoint def OperationalScenariosViewpoint :> ArchitectureAndBehaviorViewpoint {
            doc /* Covers nominal and degraded operational scenario narratives. */
        }

        viewpoint def InterfaceContextViewpoint :> ArchitectureAndBehaviorViewpoint {
            doc /* Covers external boundaries and exchanged conceptual artifacts. */
        }

        viewpoint def ComplianceAndSafetyViewpoint :> VerificationAndComplianceViewpoint {
            doc /* Covers policy/constraint obligations and operational hazard posture. */
        }

        viewpoint def LifecycleGatewayReadinessViewpoint :> LifecycleGateReadinessViewpoint {
            doc /* Covers CIM gateway entry criteria, stakeholder consensus status, and signoff evidence. */
        }
    }
}
