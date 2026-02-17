package CIM_View {

    private import Views::*;
    private import MDA_View::*;
    private import CIM_Viewpoint::*;

    viewpoint stakeholderNeedsViewpoint : StakeholderNeedsViewpoint;
    viewpoint conOpsViewpoint : ConOpsViewpoint;
    viewpoint operationalScenariosViewpoint : OperationalScenariosViewpoint;
    viewpoint interfaceContextViewpoint : InterfaceContextViewpoint;
    viewpoint complianceAndSafetyViewpoint : ComplianceAndSafetyViewpoint;
    viewpoint lifecycleGatewayReadinessViewpoint : LifecycleGatewayReadinessViewpoint;

    view def <SNRS_Document> 'CIM Stakeholder Needs and Requirements Document' {
        doc /* Captures CIM-level stakeholder needs, expectations, and traceable requirements. */
        satisfy stakeholderNeedsViewpoint;
        render asElementTable;
    }

    view def <ConOps_Document> 'CIM Concept of Operations Document' {
        doc /* Captures CIM-level mission, stakeholders, context, operational scenarios, and assumptions. */
        satisfy conOpsViewpoint;
        render asTreeDiagram;
    }

    view def <OperationalScenarios_Document> 'CIM Operational Scenarios and Use Case Document' {
        doc /* Captures CIM-level nominal and degraded operational scenarios and use-case narratives. */
        satisfy operationalScenariosViewpoint;
        render asTextualNotation;
    }

    view def <EICD_Document> 'CIM External Interface Context Document' {
        doc /* Captures CIM-level external context, actors, and conceptual interface boundaries. */
        satisfy interfaceContextViewpoint;
        render asElementTable;
    }

    view def <RSCM_Document> 'CIM Regulatory and Standards Compliance Matrix' {
        doc /* Captures CIM-level regulatory, standards, and policy obligations and their context mapping. */
        satisfy complianceAndSafetyViewpoint;
        render asElementTable;
    }

    view def <SCHA_Document> 'CIM Safety Case and Hazard Analysis Summary' {
        doc /* Captures CIM-level safety case summary, key hazards, and mitigation posture. */
        satisfy complianceAndSafetyViewpoint;
        render asElementTable;
    }

    view def <GatewaySignoff_Document> 'CIM Gateway Readiness and Signoff Document' {
        doc /* Captures CIM gateway entry criteria, stakeholder consensus status, and signoff evidence. */
        satisfy lifecycleGatewayReadinessViewpoint;
        render asElementTable;
    }
}
