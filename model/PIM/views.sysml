package PIM_Views {

    private import Views::*;
    private import PIM::*;
    private import MDA::Lifecycle::*;
    private import MDA::Structure::*;
    private import MDA::PIM::View::*;

    package StakeholderCatalog {
        doc /* PIM-level stakeholder catalog for logical design, allocation, and verification documentation. */

        private import CIM::Stakeholders::*;

        part STK_PIM_IntegrationEngineer : IntegrationEngineer {
            doc /* Focus: logical architecture and interface design fit for implementation. Needs: clear component responsibilities and interface contracts. */
        }

        part STK_PIM_OperationsEngineer : OperationsEngineer {
            doc /* Focus: operability and failure handling at the logical design level. Needs: explicit degraded flows and error handling behavior. */
        }

        part STK_PIM_ClinicalSystemOwner : ClinicalSystemOwner {
            doc /* Focus: preservation of clinical meaning in the logical mapping and error handling. Needs: traceability from requirements to logical design. */
        }

        part STK_PIM_DownstreamAPIOwner : DownstreamAPIOwner {
            doc /* Focus: logical payload structure, interface behavior, and error contracts. Needs: stable, well-specified logical interface design. */
        }
    }

    package Viewpoint {

        private import MDA::PIM::Viewpoint::*;
        doc /* Concrete project PIM viewports bound to the MDA_PIM viewpoints. */

        view VPT_PIM_001_LogicalArchitecture {
            satisfy logicalArchitectureViewpoint;
            expose PIM::LogicalArchitecture::**;
            expose PIM::Interfaces::**;
            render asElementTable;
        }

        view VPT_PIM_002_RequirementAllocation {
            satisfy requirementAllocationViewpoint;
            expose PIM::Requirements::**;
            expose PIM::Allocations::**;
            render asElementTable;
        }

        view VPT_PIM_003_BehaviorDesign {
            satisfy logicalArchitectureViewpoint;
            expose PIM::Behavior::**;
            expose PIM::UseCases::**;

            render asTextualNotation;
        }

        view VPT_PIM_004_VerificationReadiness {
            satisfy pimVerificationReadinessViewpoint;
            expose PIM::Parametrics::**;
            render asElementTable;
        }

        view VPT_PIM_005_PIMGatewayReadiness {
            satisfy pimLifecycleGatewayReadinessViewpoint;
            expose MDA_Lifecycle::PIMConsensusGateway;
            expose MDA_Lifecycle::GatewayCheck;
            expose MDA_Lifecycle::SignoffRecord;
            expose TechnicalLead;
            expose SystemsEngineer;
            expose QualityAssuranceLead;
            render asElementTable;
        }
    }

    package CoverageMatrix {
        doc /* PIM-level trace matrix from stakeholders and concerns to viewpoints/viewports and PIM documents. */

        requirement CM_PIM_001 {
            doc /* STK_PIM_IntegrationEngineer -> PIM logical coherence -> VPT_PIM_001_LogicalArchitecture -> LogicalArchitecture_Document. */
        }

        requirement CM_PIM_002 {
            doc /* STK_PIM_ClinicalSystemOwner + STK_PIM_DownstreamAPIOwner -> PIM interface contract clarity -> VPT_PIM_001_LogicalArchitecture + VPT_PIM_003_BehaviorDesign -> InterfaceDesign_Document. */
        }

        requirement CM_PIM_003 {
            doc /* STK_PIM_IntegrationEngineer + STK_PIM_OperationsEngineer -> PIM allocation completeness -> VPT_PIM_002_RequirementAllocation -> Allocation_Document. */
        }

        requirement CM_PIM_004 {
            doc /* STK_PIM_IntegrationEngineer + STK_PIM_OperationsEngineer -> PIM verification readiness -> VPT_PIM_004_VerificationReadiness -> Verification_Document. */
        }

        requirement CM_PIM_005 {
            doc /* SystemsEngineer + TechnicalLead + ProjectManager -> PIM gateway readiness -> VPT_PIM_005_PIMGatewayReadiness -> PIMGatewaySignoff_Document. */
        }
    }

    package PIMDocumentBlueprints {
        doc /* PIM document composition blueprints represented as model views bound to PIM viewports. */

        view DOC_PIM_LogicalArchitecture : LogicalArchitecture_Document {
            doc /* PIM Logical Architecture Specification for the HL7 Adapter. */
            expose Viewpoint::VPT_PIM_001_LogicalArchitecture;
            expose CoverageMatrix::CM_PIM_001;
        }

        view DOC_PIM_InterfaceDesign : InterfaceDesign_Document {
            doc /* PIM Interface Design Description for the HL7 Adapter. */
            expose Viewpoint::VPT_PIM_001_LogicalArchitecture;
            expose Viewpoint::VPT_PIM_003_BehaviorDesign;
            expose CoverageMatrix::CM_PIM_002;
        }

        view DOC_PIM_BehaviorDesign : BehaviorDesign_Document {
            doc /* PIM Behavior and Use Case Design Document. */
            expose Viewpoint::VPT_PIM_003_BehaviorDesign;
        }

        view DOC_PIM_Allocation : Allocation_Document {
            doc /* PIM Requirements and Allocation Specification. */
            expose Viewpoint::VPT_PIM_002_RequirementAllocation;
            expose CoverageMatrix::CM_PIM_003;
        }

        view DOC_PIM_Verification : Verification_Document {
            doc /* PIM Verification Readiness and Test Intent. */
            expose Viewpoint::VPT_PIM_004_VerificationReadiness;
            expose CoverageMatrix::CM_PIM_004;
        }

        view DOC_PIM_GatewaySignoff : PIMGatewaySignoff_Document {
            doc /* PIM gateway readiness and design review pack before entering PSM. */
            expose Viewpoint::VPT_PIM_005_PIMGatewayReadiness;
            expose CoverageMatrix::CM_PIM_005;
        }
    }
}
