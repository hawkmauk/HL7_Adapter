    package CIM_Viewpoint {

        doc /* CIM-specific viewpoint catalog aligned with the MDA standard viewpoint pattern. */

        private import MDA_Viewpoint::*;
        private import MDA_Structure::*;

        /* Generic CIM-level concerns */

        
        concern 'CIM stakeholder needs coverage' {
            doc /* Ensure CIM-level models capture stakeholder identities, needs, and traceable requirements. */

            subject system : System;

            stakeholder se : SystemsEngineer;
            stakeholder customer : Customer;
            stakeholder pm : ProjectManager;
        }

        concern 'CIM context and mission clarity' {
            doc /* Ensure CIM clearly expresses mission, operational context, and underlying assumptions. */

            subject system : System;

            stakeholder se : SystemsEngineer;
            stakeholder customer : Customer;
        }

        concern 'CIM operational scenario transparency' {
            doc /* Ensure nominal and degraded CIM operational scenarios are explicit and reviewable. */

            subject system : System;

            stakeholder se : SystemsEngineer;
            stakeholder pm : ProjectManager;
        }

        concern 'CIM interface boundary clarity' {
            doc /* Ensure CIM-level external boundaries and conceptual interfaces are well defined. */

            subject system : System;

            stakeholder se : SystemsEngineer;
            stakeholder customer : Customer;
        }

        concern 'CIM compliance and safety posture' {
            doc /* Ensure CIM captures regulatory, policy, and safety obligations at the concept level. */

            subject system : System;

            stakeholder se : SystemsEngineer;
            stakeholder pm : ProjectManager;
        }

        concern 'CIM gateway readiness' {
            doc /* Ensure there is sufficient CIM evidence and consensus to pass the CIM lifecycle gateway. */

            subject system : System;

            stakeholder se : SystemsEngineer;
            stakeholder customer : Customer;
            stakeholder pm : ProjectManager;
        }

        /* CIM viewpoints specialized from the abstract MDA viewpoints */

        viewpoint def StakeholderNeedsViewpoint :> StakeholderConcernsViewpoint {
            doc /* Covers stakeholder intent, outcomes, and traceability concerns. */

            frame 'CIM stakeholder needs coverage';

            require constraint {
                doc /* A Stakeholder Needs view shall show stakeholders, their needs, and traceable CIM-level requirements. */
            }
        }

        viewpoint def ConOpsViewpoint :> ArchitectureAndBehaviorViewpoint {
            doc /* Covers mission, operational context, and assumptions for system use. */

            frame 'CIM context and mission clarity';

            require constraint {
                doc /* A ConOps view shall show mission, stakeholders, context, operations, and assumptions at CIM level. */
            }
        }

        viewpoint def OperationalScenariosViewpoint :> ArchitectureAndBehaviorViewpoint {
            doc /* Covers nominal and degraded operational scenario narratives. */

            frame 'CIM operational scenario transparency';

            require constraint {
                doc /* An Operational Scenarios view shall show nominal and degraded CIM operational flows and narratives. */
            }
        }

        viewpoint def InterfaceContextViewpoint :> ArchitectureAndBehaviorViewpoint {
            doc /* Covers external boundaries and exchanged conceptual artifacts. */

            frame 'CIM interface boundary clarity';

            require constraint {
                doc /* An Interface Context view shall show CIM external actors, boundaries, and key conceptual exchanges. */
            }
        }

        viewpoint def ComplianceAndSafetyViewpoint :> VerificationAndComplianceViewpoint {
            doc /* Covers policy/constraint obligations and operational hazard posture. */

            frame 'CIM compliance and safety posture';

            require constraint {
                doc /* A Compliance and Safety view shall show CIM-level obligations, hazards, and mitigation rationale. */
            }
        }

        viewpoint def LifecycleGatewayReadinessViewpoint :> LifecycleGateReadinessViewpoint {
            doc /* Covers CIM gateway entry criteria, stakeholder consensus status, and signoff evidence. */

            frame 'CIM gateway readiness';

            require constraint {
                doc /* A Gateway Readiness view shall show entry criteria, unresolved issues, and signoff evidence for the CIM gate. */
            }
        }
    }