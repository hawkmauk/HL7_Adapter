package 'CIM-ProjectViews' {
    private import Views::*;
    private import CIM::*;
    private import MDA::Lifecycle::*;
    private import MDA::Structure::*;
    private import MDA::CIM::View::*;

    package ConcernMapping {
        doc /* Normalized stakeholder concerns with subject and stakeholder definitions; coverage requirements reference these concerns. */

        private import CIM::Stakeholders::*;
        private import CIM::Context::*;

        concern def CON_001_IngestionReliability {
            doc /* System shall reliably ingest framed HL7 events from upstream sources under normal operations. Evidence source: CIM::Operations::PublishHL7Event, CIM::Operations::ReceiveMLLPMessage, CIM::Mission::ReliableEventIngestion. */
            subject hl7AdapterService : HL7AdapterService;
            stakeholder integrationEngineer : IntegrationEngineer;
        }
        concern ingestionReliability : CON_001_IngestionReliability;

        concern def CON_002_ClinicalSemanticPreservation {
            doc /* Transformation shall preserve key clinical identifiers and message intent at concept level. Evidence source: CIM::Domain::HL7Message, CIM::Domain::PatientDemographics, CIM::Mission::AccurateClinicalTransformation. */
            subject hl7AdapterService : HL7AdapterService;
            stakeholder clinicalSystemOwner : ClinicalSystemOwner;
        }
        concern clinicalSemanticPreservation : CON_002_ClinicalSemanticPreservation;

        concern def CON_003_InterfaceBoundaryClarity {
            doc /* External context shall clearly define ingress and egress boundaries. Evidence source: CIM::Context::**, CIM::Domain::**. */
            subject hl7AdapterService : HL7AdapterService;
            stakeholder upstreamHL7System : UpstreamHL7System;
        }
        concern interfaceBoundaryClarity : CON_003_InterfaceBoundaryClarity;

        concern def CON_004_DownstreamDeliveryExpectation {
            doc /* Conceptual contract shall identify intended payload handoff and delivery outcomes. Evidence source: CIM::Domain::**, CIM::Operations::PostPayloadToAPI, CIM::Mission::SecureInteroperability. */
            subject hl7AdapterService : HL7AdapterService;
            stakeholder downstreamAPIOwner : DownstreamAPIOwner;
        }
        concern downstreamDeliveryExpectation : CON_004_DownstreamDeliveryExpectation;

        concern def CON_005_ComplianceObligations {
            doc /* Data handling and transport obligations shall be explicit at context level. Evidence source: CIM::Assumptions::**, CIM::Mission::**. */
            subject hl7AdapterService : HL7AdapterService;
            stakeholder securityAndComplianceOfficer : SecurityAndComplianceOfficer;
        }
        concern complianceObligations : CON_005_ComplianceObligations;

        concern def CON_006_DegradedModeTransparency {
            doc /* Degraded operational behavior shall be explicit for support and incident response planning. Evidence source: CIM::Operations::DegradedFlow, CIM::Domain::IntegrationError, CIM::Mission::OperationalTransparency. */
            subject hl7AdapterService : HL7AdapterService;
            stakeholder operationsEngineer : OperationsEngineer;
        }
        concern degradedModeTransparency : CON_006_DegradedModeTransparency;

        concern def CON_007_GatewayReadiness {
            doc /* CIM stakeholder consensus and gateway signoff before progression to PIM. Evidence: CIM::LifecycleAlignment::cimConsensusMilestone, cimGatewayCheck, cimSignoffRecord, signoff roles. */
        }
        concern gatewayReadiness : CON_007_GatewayReadiness;
    }

    package Viewpoint {
        private import CIM::Stakeholders::*;
        private import MDA::CIM::Viewpoint::*;
        doc /* Concrete project viewports; structured only by standard CIM packages for reuse. */

        view VPT_001_StakeholderNeedsMatrix {
            satisfy stakeholderNeedsViewpoint;
            expose Stakeholders::**;
            expose ConcernMapping::**;
            expose CIM::Mission::**;
            render asElementTable;
        }

        view VPT_002_ConOpsContext {
            satisfy conOpsViewpoint;
            expose CIM::Stakeholders::**;
            expose CIM::Context::**;
            expose CIM::Domain::**;
            expose CIM::Assumptions::**;
            render asTreeDiagram;
        }

        view VPT_003_OperationalFlows {
            satisfy operationalScenariosViewpoint;
            expose CIM::Actions::**;
            render asTextualNotation;
        }

        view VPT_004_ExternalInterfaceContext {
            satisfy interfaceContextViewpoint;
            expose CIM::Domain::**;
            expose CIM::Context::**;
            render asElementTable;
        }

        view VPT_005_ComplianceAndSafety {
            satisfy complianceAndSafetyViewpoint;
            expose CIM::Assumptions::**;
            expose CIM::Mission::**;
            expose CIM::Actions::**;
            expose CIM::Domain::**;
            render asElementTable;
        }

        view VPT_006_CIMGatewayReadiness {
            satisfy lifecycleGatewayReadinessViewpoint;
            expose CIM::LifecycleAlignment::cimConsensusMilestone;
            expose CIM::LifecycleAlignment::cimGatewayCheck;
            expose CIM::LifecycleAlignment::cimSignoffRecord;
            expose Customer;
            expose ProjectManager;
            expose SystemsEngineer;
            expose ComplianceOfficer;
            expose OperationsOwner;
            render asElementTable;
        }
    }

    package CoverageMatrix {
        doc /* Trace matrix from concerns to viewpoints/viewports and planned CIM document sections. */

        requirement CM_001 {
            doc /* ingestionReliability -> VPT_001_StakeholderNeedsMatrix -> SNRS.S1,S2 */
            satisfy ConcernMapping::ingestionReliability;
        }

        requirement CM_002 {
            doc /* clinicalSemanticPreservation -> VPT_001_StakeholderNeedsMatrix -> SNRS.S2,S3 */
            satisfy ConcernMapping::clinicalSemanticPreservation;
        }

        requirement CM_003 {
            doc /* interfaceBoundaryClarity -> VPT_004_ExternalInterfaceContext -> EICD.S1,S2 */
            satisfy ConcernMapping::interfaceBoundaryClarity;
        }

        requirement CM_004 {
            doc /* downstreamDeliveryExpectation -> VPT_004_ExternalInterfaceContext -> EICD.S2,S3 */
            satisfy ConcernMapping::downstreamDeliveryExpectation;
        }

        requirement CM_005 {
            doc /* complianceObligations -> VPT_005_ComplianceAndSafety -> RSCM.S1,S2; SCHA.S2 */
            satisfy ConcernMapping::complianceObligations;
        }

        requirement CM_006 {
            doc /* degradedModeTransparency -> VPT_003_OperationalFlows + VPT_005_ComplianceAndSafety -> OSS.S2,S3; SCHA.S3 */
            satisfy ConcernMapping::degradedModeTransparency;
        }

        requirement CM_007 {
            doc /* gatewayReadiness -> VPT_006_CIMGatewayReadiness -> SIG_CIM_GATE.S1,S2,S3 */
            satisfy ConcernMapping::gatewayReadiness;
        }
    }

    package CIMDocumentBlueprints {
        doc /* CIM document composition blueprints represented as model views bound to viewports. */

        view DOC_CIM_SNRS : SNRS_Document {
            doc /* Stakeholder Needs and Requirements Specification. */
            expose Viewpoint::VPT_001_StakeholderNeedsMatrix;
            expose CoverageMatrix::CM_001;
            expose CoverageMatrix::CM_002;
        }

        view DOC_CIM_ConOps : ConOps_Document {
            doc /* Concept of Operations. */
            expose Viewpoint::VPT_002_ConOpsContext;
            expose CIM::Mission::**;
        }

        view DOC_CIM_OperationalScenarios : OperationalScenarios_Document {
            doc /* Operational Scenarios and Use Case Specification. */
            expose Viewpoint::VPT_003_OperationalFlows;
        }

        view DOC_CIM_EICD : EICD_Document {
            doc /* External Interface Context Document. */
            expose Viewpoint::VPT_004_ExternalInterfaceContext;
        }

        view DOC_CIM_RSCM : RSCM_Document {
            doc /* Regulatory and Standards Compliance Matrix (context-level obligations). */
            expose Viewpoint::VPT_005_ComplianceAndSafety;
        }

        view DOC_CIM_SCHA : SCHA_Document {
            doc /* Safety Case and Hazard Analysis Summary (concept/operational). */
            expose Viewpoint::VPT_005_ComplianceAndSafety;
        }

        view DOC_CIM_GatewaySignoff : GatewaySignoff_Document {
            doc /* CIM stakeholder consensus and gateway signoff record before progression to PIM. */
            expose Viewpoint::VPT_006_CIMGatewayReadiness;
            expose CoverageMatrix::CM_007;
        }
    }

    package AutomationReadiness {
        doc /* Conventions for deterministic LaTeX generation and CI/CD publishing from model views. */

        requirement AUTO_001 {
            doc /* All stakeholder, concern, viewpoint, viewport, and document elements shall use stable IDs with prefixes STK_, CON_, VP_, VPT_, DOC_, CM_, AUTO_. */
        }

        requirement AUTO_002 {
            doc /* Each DOC_CIM_* view shall map to one generated LaTeX artifact named cim-<doc-id>-<version>.pdf and cim-<doc-id>-<version>.tex. */
        }

        requirement AUTO_003 {
            doc /* CI trigger: commit affecting model/*.sysml, docs/guides/*.txt, or generation scripts. */
        }

        requirement AUTO_004 {
            doc /* CI build order: model validation -> view extraction -> LaTeX generation -> artifact packaging. */
        }

        requirement AUTO_005 {
            doc /* Quality gates: no validation errors, complete concern coverage, reproducible artifact hash for identical model input. */
        }

        requirement AUTO_006 {
            doc /* Publish target: versioned build artifacts with immutable naming and branch-based retention policy. */
        }

        requirement AUTO_007 {
            doc /* SIG_CIM_GATE shall generate cim-gateway-signoff-<version>.pdf and cim-gateway-signoff-<version>.tex from DOC_CIM_GatewaySignoff. */
        }
    }
}
