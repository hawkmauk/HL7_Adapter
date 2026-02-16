package 'CIM-Views' {
    private import Views::*;
    private import CIM::*;

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
            doc /* External context shall clearly define HL7 ingress and REST egress boundaries. Evidence source: CIM::Context::HL7AdapterService, CIM::Context::NetworkBoundary, CIM::Domain::RESTEndpoint. */
        }
        concern CON_003_InterfaceBoundaryClarity : CON_003_InterfaceBoundaryClarity_Def;

        concern def CON_004_DownstreamDeliveryExpectation_Def {
            doc /* Conceptual contract shall identify intended JSON handoff and delivery outcomes. Evidence source: CIM::Domain::JSONPayload, CIM::Operations::PostPayloadToAPI, CIM::Mission::SecureInteroperability. */
        }
        concern CON_004_DownstreamDeliveryExpectation : CON_004_DownstreamDeliveryExpectation_Def;

        concern def CON_005_ComplianceObligations_Def {
            doc /* PHI handling and transport obligations shall be explicit at context level. Evidence source: CIM::Assumptions::PHIHandlingPolicy, CIM::Assumptions::HTTPSForwardingRequired. */
        }
        concern CON_005_ComplianceObligations : CON_005_ComplianceObligations_Def;

        concern def CON_006_DegradedModeTransparency_Def {
            doc /* Degraded operational behavior shall be explicit for support and incident response planning. Evidence source: CIM::Operations::DegradedFlow, CIM::Domain::IntegrationError, CIM::Mission::OperationalTransparency. */
        }
        concern CON_006_DegradedModeTransparency : CON_006_DegradedModeTransparency_Def;
    }

    package ViewpointDefinitions {
        doc /* Reusable CIM viewpoints that frame concern clusters for document generation. */

        viewpoint VP_001_StakeholderNeeds {
            doc /* Framing rules for stakeholder intent, mission outcomes, and concern traceability. Level: CIM. */
            frame ConcernMapping::CON_001_IngestionReliability;
            frame ConcernMapping::CON_002_ClinicalSemanticPreservation;
            frame ConcernMapping::CON_006_DegradedModeTransparency;
        }

        viewpoint VP_002_ConOps {
            doc /* Framing rules for operational context, actors, mission, and assumptions. Level: CIM. */
            frame ConcernMapping::CON_001_IngestionReliability;
            frame ConcernMapping::CON_003_InterfaceBoundaryClarity;
            frame ConcernMapping::CON_005_ComplianceObligations;
        }

        viewpoint VP_003_OperationalScenarios {
            doc /* Framing rules for nominal/degraded scenario narratives and activity sequencing. Level: CIM. */
            frame ConcernMapping::CON_001_IngestionReliability;
            frame ConcernMapping::CON_006_DegradedModeTransparency;
        }

        viewpoint VP_004_InterfaceContext {
            doc /* Framing rules for external boundaries, exchanged conceptual artifacts, and interaction responsibilities. Level: CIM. */
            frame ConcernMapping::CON_003_InterfaceBoundaryClarity;
            frame ConcernMapping::CON_004_DownstreamDeliveryExpectation;
        }

        viewpoint VP_005_ComplianceAndSafety {
            doc /* Framing rules for obligations, constraints, and safety-oriented operational concerns. Level: CIM with cross-level trace intent. */
            frame ConcernMapping::CON_005_ComplianceObligations;
            frame ConcernMapping::CON_006_DegradedModeTransparency;
        }
    }

    package Viewports {
        doc /* View instances that apply viewpoints to CIM model scope. */

        view VPT_001_StakeholderNeedsMatrix {
            doc /* Viewport for stakeholder-to-concern-to-mission mapping used in SNRS. */
            satisfy ViewpointDefinitions::VP_001_StakeholderNeeds;
            expose StakeholderCatalog::**;
            expose ConcernMapping::**;
            expose CIM::Mission::**;
            render asElementTable;
        }

        view VPT_002_ConOpsContext {
            doc /* Viewport for ConOps context with stakeholders, domain concepts, and operational setting. */
            satisfy ViewpointDefinitions::VP_002_ConOps;
            expose CIM::Stakeholders::**;
            expose CIM::Context::**;
            expose CIM::Domain::**;
            expose CIM::Assumptions::**;
            render asTreeDiagram;
        }

        view VPT_003_OperationalFlows {
            doc /* Viewport for nominal and degraded operational scenario definitions. */
            satisfy ViewpointDefinitions::VP_003_OperationalScenarios;
            expose CIM::Operations::NominalFlow;
            expose CIM::Operations::DegradedFlow;
            render asTextualNotation;
        }

        view VPT_004_ExternalInterfaceContext {
            doc /* Viewport for boundary-level ingress/egress interfaces and exchanged concepts. */
            satisfy ViewpointDefinitions::VP_004_InterfaceContext;
            expose CIM::Domain::HL7Message;
            expose CIM::Domain::MLLPFrame;
            expose CIM::Domain::JSONPayload;
            expose CIM::Domain::RESTEndpoint;
            expose CIM::Context::HL7AdapterService;
            expose CIM::Context::NetworkBoundary;
            render asElementTable;
        }

        view VPT_005_ComplianceAndSafety {
            doc /* Viewport for assumptions, constraints, and degraded operations relevant to compliance and hazard posture. */
            satisfy ViewpointDefinitions::VP_005_ComplianceAndSafety;
            expose CIM::Assumptions::**;
            expose CIM::Mission::OperationalTransparency;
            expose CIM::Operations::DegradedFlow;
            expose CIM::Domain::IntegrationError;
            expose CIM::Domain::ParseError;
            expose CIM::Domain::DeliveryError;
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
    }

    package CIMDocumentBlueprints {
        doc /* CIM document composition blueprints represented as model views bound to viewports. */

        view DOC_CIM_SNRS {
            doc /* Stakeholder Needs and Requirements Specification. Audience: engineering + clinical ownership. Sections: S1 Scope and Stakeholders, S2 Needs and Mission Outcomes, S3 Concern Traceability, S4 Acceptance Checks. */
            satisfy ViewpointDefinitions::VP_001_StakeholderNeeds;
            expose Viewports::VPT_001_StakeholderNeedsMatrix;
            expose CoverageMatrix::CM_001;
            expose CoverageMatrix::CM_002;
            render asElementTable;
        }

        view DOC_CIM_ConOps {
            doc /* Concept of Operations. Audience: cross-functional stakeholders. Sections: S1 Mission and Goals, S2 Operational Context, S3 Actors and Interactions, S4 Assumptions and Constraints. */
            satisfy ViewpointDefinitions::VP_002_ConOps;
            expose Viewports::VPT_002_ConOpsContext;
            expose CIM::Mission::**;
            render asTreeDiagram;
        }

        view DOC_CIM_OperationalScenarios {
            doc /* Operational Scenarios and Use Case Specification. Audience: engineering + operations. Sections: S1 Nominal Scenario, S2 Degraded Scenario, S3 Operational Responsibilities, S4 Acceptance Checks. */
            satisfy ViewpointDefinitions::VP_003_OperationalScenarios;
            expose Viewports::VPT_003_OperationalFlows;
            render asTextualNotation;
        }

        view DOC_CIM_EICD {
            doc /* External Interface Context Document. Audience: upstream/downstream system owners. Sections: S1 Boundary Definition, S2 Exchanged Concepts, S3 Interaction Expectations, S4 Assumptions. */
            satisfy ViewpointDefinitions::VP_004_InterfaceContext;
            expose Viewports::VPT_004_ExternalInterfaceContext;
            render asElementTable;
        }

        view DOC_CIM_RSCM {
            doc /* Regulatory and Standards Compliance Matrix (context-level obligations). Audience: compliance and governance. Sections: S1 Obligation Catalog, S2 Constraint Mapping, S3 Traceability to Mission/Operations. */
            satisfy ViewpointDefinitions::VP_005_ComplianceAndSafety;
            expose Viewports::VPT_005_ComplianceAndSafety;
            render asElementTable;
        }

        view DOC_CIM_SCHA {
            doc /* Safety Case and Hazard Analysis Summary (concept/operational). Audience: safety and operations. Sections: S1 Hazard Context, S2 Safety-Relevant Constraints, S3 Degraded Outcome Summary, S4 Open Risks/Gaps. */
            satisfy ViewpointDefinitions::VP_005_ComplianceAndSafety;
            expose Viewports::VPT_005_ComplianceAndSafety;
            expose CIM::Operations::DegradedFlow;
            render asElementTable;
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
    }
}
