package PIM_Views {

    private import Views::*;
    private import PIM::*;
    private import MDA::Lifecycle::*;
    private import MDA::Structure::*;
    private import MDA::PIM::View::*;

    package ConcernMapping {
        private import CIM::Stakeholders::*;
        private import PIM::LogicalArchitecture::*;

        doc /* PIM-level concerns with trace to stakeholders; coverage requirements reference these concerns. */

        concern def CON_PIM_001_LogicalCoherence {
            doc /* Logical architecture and component design fit for implementation. Evidence: PIM::LogicalArchitecture::**, PIM::Interfaces::**. */
            subject hl7AdapterService : HL7AdapterService;
            stakeholder integrationEngineer : IntegrationEngineer;
        }
        concern logicalCoherance : CON_PIM_001_LogicalCoherence;

        concern def CON_PIM_002_InterfaceContractClarity {
            doc /* Logical interface contracts, payload structure, and error behavior. Evidence: PIM::Interfaces::**, PIM::Behavior::**. */
            subject hl7AdapterService : HL7AdapterService;
            stakeholder clinicalSystemOwner : ClinicalSystemOwner;
            stakeholder StakeholderCatalog : DownstreamAPIOwner;
        }
        concern interfaceContractClarity : CON_PIM_002_InterfaceContractClarity;

        concern def CON_PIM_003_AllocationCompleteness {
            doc /* PIM requirements fully allocated to logical architecture, interfaces, and behaviors. Evidence: PIM::Requirements::**, PIM::Allocations::**. */
            subject hl7AdapterService : HL7AdapterService;
            stakeholder integrationEngineer : IntegrationEngineer;
            stakeholder operationsEngineer : OperationsEngineer;
        }
        concern allocationCompleteness : CON_PIM_003_AllocationCompleteness;

        concern def CON_PIM_004_VerificationReadiness {
            doc /* Verification objectives, test approach, and coverage of PIM requirements. Evidence: PIM::Parametrics::**. */
            subject hl7AdapterService : HL7AdapterService;
            stakeholder integrationEngineer : IntegrationEngineer;
            stakeholder operationsEngineer : OperationsEngineer;
        }
        concern verificationReadiness : CON_PIM_004_VerificationReadiness;

        concern def CON_PIM_005_GatewayReadiness {
            doc /* PIM gate entry criteria, design risks, and signoff evidence before entering PSM. Evidence: MDA_Lifecycle::PIMConsensusGateway, signoff roles. */
        }
        concern gatewayReadiness : CON_PIM_005_GatewayReadiness;
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
            doc /* CON_PIM_001_LogicalCoherence -> VPT_PIM_001_LogicalArchitecture -> LogicalArchitecture_Document. */
            satisfy ConcernMapping::logicalCoherance;
        }

        requirement CM_PIM_002 {
            doc /* CON_PIM_002_InterfaceContractClarity -> VPT_PIM_001_LogicalArchitecture + VPT_PIM_003_BehaviorDesign -> InterfaceDesign_Document. */
            satisfy ConcernMapping::interfaceContractClarity;
        }

        requirement CM_PIM_003 {
            doc /* CON_PIM_003_AllocationCompleteness -> VPT_PIM_002_RequirementAllocation -> Allocation_Document. */
            satisfy ConcernMapping::allocationCompleteness;
        }

        requirement CM_PIM_004 {
            doc /* CON_PIM_004_VerificationReadiness -> VPT_PIM_004_VerificationReadiness -> Verification_Document. */
            satisfy ConcernMapping::verificationReadiness;
        }

        requirement CM_PIM_005 {
            doc /* CON_PIM_005_GatewayReadiness -> VPT_PIM_005_PIMGatewayReadiness -> PIMGatewaySignoff_Document. */
            satisfy ConcernMapping::gatewayReadiness;
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
