package 'CIM-ViewLibrary' {
    private import Views::*;

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

    package StandardViewpointCatalog {
        doc /* Reusable viewpoint definition catalog to be instantiated in project view models. */

        viewpoint def StakeholderNeedsViewpoint {
            doc /* Covers stakeholder intent, outcomes, and traceability concerns. */
        }

        viewpoint def ConOpsViewpoint {
            doc /* Covers mission, operational context, and assumptions for system use. */
        }

        viewpoint def OperationalScenariosViewpoint {
            doc /* Covers nominal and degraded operational scenario narratives. */
        }

        viewpoint def InterfaceContextViewpoint {
            doc /* Covers external boundaries and exchanged conceptual artifacts. */
        }

        viewpoint def ComplianceAndSafetyViewpoint {
            doc /* Covers policy/constraint obligations and operational hazard posture. */
        }
    }

    package StandardRenderProfiles {
        doc /* Reusable render profile definitions for document generation consistency. */

        view def ElementTableProfile {
            render asElementTable;
        }

        view def TreeDiagramProfile {
            render asTreeDiagram;
        }

        view def TextualNotationProfile {
            render asTextualNotation;
        }
    }
}
