package 'CIM-ProjectViews' {
    private import Views::*;
    private import CIM::*;
    private import MDA::Lifecycle::*;
    private import MDA::Structure::*;
    private import MDA::CIM::View::*;
    
    package StakeholderCatalog {
        doc /* Stakeholder catalog for CIM-level documentation products. */

        part STK_IntegrationEngineer : Stakeholders::IntegrationEngineer {
            doc /* Scope: adapter design and configuration. Needs: traceable context, scenarios, and assumptions. Success: can implement and evolve integration with low ambiguity. Level: CIM primary. */
        }

        part STK_ClinicalSystemOwner : Stakeholders::ClinicalSystemOwner {
            doc /* Scope: upstream data semantics and event quality. Needs: mission outcomes and message intent traceability. Success: clinical meaning preserved in transformation. Level: CIM primary. */
        }

        part STK_UpstreamHL7System : Stakeholders::UpstreamHL7System {
            doc /* Scope: sender behavior and framing assumptions. Needs: external interface context and scenario triggers. Success: predictable ingestion contract at system boundary. Level: CIM primary. */
        }

        part STK_DownstreamAPIOwner : Stakeholders::DownstreamAPIOwner {
            doc /* Scope: downstream payload consumption and contract clarity. Needs: payload intent, context boundaries, and error outcomes. Success: reliable API handoff expectations. Level: CIM primary. */
        }

        part STK_SecurityCompliance : Stakeholders::SecurityAndComplianceOfficer {
            doc /* Scope: PHI handling and security posture. Needs: constraints and compliance obligations. Success: obligations are explicit and verifiable. Level: CIM and cross-level. */
        }

        part STK_OperationsEngineer : Stakeholders::OperationsEngineer {
            doc /* Scope: runtime operability and incident handling. Needs: degraded scenarios and operational transparency concerns. Success: clear failure handling and monitoring expectations. Level: CIM primary. */
        }
    }

    package ConcernMapping {
        doc /* Normalized stakeholder concerns with trace hooks back to CIM model content. */

        concern def CON_001_IngestionReliability_Def {
            doc /* System shall reliably ingest framed HL7 events from upstream sources under normal operations. Evidence source: CIM::Operations::PublishHL7Event, CIM::Operations::ReceiveMLLPMessage, CIM::Mission::ReliableEventIngestion. */
        }
        concern CON_001_IngestionReliability : CON_001_IngestionReliability_Def;

        concern def CON_002_ClinicalSemanticPreservation_Def {
            doc /* Transformation shall preserve key clinical identifiers and message intent at concept level. Evidence source: CIM::Domain::HL7Message, CIM::Domain::PatientDemographics, CIM::Mission::AccurateClinicalTransformation. */
        }
        concern CON_002_ClinicalSemanticPreservation : CON_002_ClinicalSemanticPreservation_Def;

        concern def CON_003_InterfaceBoundaryClarity_Def {
            doc /* External context shall clearly define ingress and egress boundaries. Evidence source: CIM::Context::**, CIM::Domain::**. */
        }
        concern CON_003_InterfaceBoundaryClarity : CON_003_InterfaceBoundaryClarity_Def;

        concern def CON_004_DownstreamDeliveryExpectation_Def {
            doc /* Conceptual contract shall identify intended payload handoff and delivery outcomes. Evidence source: CIM::Domain::**, CIM::Operations::PostPayloadToAPI, CIM::Mission::SecureInteroperability. */
        }
        concern CON_004_DownstreamDeliveryExpectation : CON_004_DownstreamDeliveryExpectation_Def;

        concern def CON_005_ComplianceObligations_Def {
            doc /* Data handling and transport obligations shall be explicit at context level. Evidence source: CIM::Assumptions::**, CIM::Mission::**. */
        }
        concern CON_005_ComplianceObligations : CON_005_ComplianceObligations_Def;

        concern def CON_006_DegradedModeTransparency_Def {
            doc /* Degraded operational behavior shall be explicit for support and incident response planning. Evidence source: CIM::Operations::DegradedFlow, CIM::Domain::IntegrationError, CIM::Mission::OperationalTransparency. */
        }
        concern CON_006_DegradedModeTransparency : CON_006_DegradedModeTransparency_Def;
    }

    package Viewpoint {

        private import MDA::CIM::Viewpoint::*;
        doc /* Concrete project viewports; structured only by standard CIM packages for reuse. */

        view VPT_001_StakeholderNeedsMatrix {
            expose StakeholderCatalog::**;
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
            expose CIM::Operations::**;
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
            expose CIM::Operations::**;
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
        doc /* Trace matrix from stakeholder concerns to viewpoints/viewports and planned CIM document sections. */

        requirement CM_001 {
            doc /* STK_IntegrationEngineer -> CON_001_IngestionReliability -> CIM -> VP_001_StakeholderNeeds -> VPT_001_StakeholderNeedsMatrix -> SNRS.S1,S2 */
        }

        requirement CM_002 {
            doc /* STK_ClinicalSystemOwner -> CON_002_ClinicalSemanticPreservation -> CIM -> VP_001_StakeholderNeeds -> VPT_001_StakeholderNeedsMatrix -> SNRS.S2,S3 */
        }

        requirement CM_003 {
            doc /* STK_UpstreamHL7System -> CON_003_InterfaceBoundaryClarity -> CIM -> VP_004_InterfaceContext -> VPT_004_ExternalInterfaceContext -> EICD.S1,S2 */
        }

        requirement CM_004 {
            doc /* STK_DownstreamAPIOwner -> CON_004_DownstreamDeliveryExpectation -> CIM -> VP_004_InterfaceContext -> VPT_004_ExternalInterfaceContext -> EICD.S2,S3 */
        }

        requirement CM_005 {
            doc /* STK_SecurityCompliance -> CON_005_ComplianceObligations -> CIM/Cross -> VP_005_ComplianceAndSafety -> VPT_005_ComplianceAndSafety -> RSCM.S1,S2; SCHA.S2 */
        }

        requirement CM_006 {
            doc /* STK_OperationsEngineer -> CON_006_DegradedModeTransparency -> CIM -> VP_003_OperationalScenarios + VP_005_ComplianceAndSafety -> VPT_003_OperationalFlows + VPT_005_ComplianceAndSafety -> OSS.S2,S3; SCHA.S3 */
        }

        requirement CM_007 {
            doc /* Customer/ProjectManager/SystemsEngineer/ComplianceOfficer/OperationsOwner -> CON_001 + CON_005 + CON_006 -> CIM Gate -> VP_006_CIMGatewayReadiness -> VPT_006_CIMGatewayReadiness -> SIG_CIM_GATE.S1,S2,S3 */
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
