package ProjectLifecycle {
    private import Views::*;

    package LifecycleGovernance {
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

    package StandardDocumentationFramework {
        doc /* Shared documentation framework used by CIM/PIM/PSM viewpoint catalogs and document generation. */

        package StandardProjectStakeholders {
            doc /* Cross-project governance stakeholders for lifecycle decisions and signoff. */

            part def <Customer> 'Customer' {
                doc /* Funding or sponsoring stakeholder who accepts delivered value and outcomes. */
            }

            part def <ProjectManager> 'Project Manager' {
                doc /* Accountable for schedule, scope, risks, and gate readiness coordination. */
            }

            part def <SystemsEngineer> 'Systems Engineer' {
                doc /* Owns model coherence, stakeholder concern coverage, and architectural traceability. */
            }

            part def <TechnicalLead> 'Technical Lead' {
                doc /* Ensures technical feasibility and alignment of logical and implementation solutions. */
            }

            part def <QualityAssuranceLead> 'Quality Assurance Lead' {
                doc /* Assures verification coverage, test quality, and release confidence evidence. */
            }

            part def <ComplianceOfficer> 'Compliance Officer' {
                doc /* Verifies regulatory, privacy, and policy obligations are represented and satisfied. */
            }

            part def <OperationsOwner> 'Operations Owner' {
                doc /* Confirms operational supportability, monitoring readiness, and service transition fit. */
            }
        }

        package StandardViewpointCatalog {
            doc /* Abstract viewpoint contract that CIM/PIM/PSM viewpoint catalogs specialize. */

            abstract viewpoint def StakeholderConcernsViewpoint {
                doc /* Captures stakeholder identities, concerns, and concern-to-evidence traceability. */
            }

            abstract viewpoint def LifecycleGateReadinessViewpoint {
                doc /* Captures gateway entry/exit criteria, unresolved issues, and signoff status. */
            }

            abstract viewpoint def ArchitectureAndBehaviorViewpoint {
                doc /* Captures structural and behavioral evidence needed for design and review decisions. */
            }

            abstract viewpoint def VerificationAndComplianceViewpoint {
                doc /* Captures verification coverage and compliance posture evidence for approvals. */
            }
        }

        package StandardRenderProfiles {
            doc /* Reusable render profile definitions for consistent document generation across CIM/PIM/PSM. */

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
}
