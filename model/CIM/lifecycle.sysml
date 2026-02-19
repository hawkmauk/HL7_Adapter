package CIM_LifecycleAlignment {
    doc /* CIM lifecycle gate alignment for stakeholder consensus before progression to PIM. */

    private import MDA::Lifecycle::*;
    private import MDA::Structure::*;

    part cimConsensusMilestone : CIMConsensusGateway;
    part cimGatewayCheck : GatewayCheck;
    part cimSignoffRecord : SignoffRecord;

    part customer : Customer;
    part projectManager : ProjectManager;
    part systemsEngineer : SystemsEngineer;
    part complianceOfficer : ComplianceOfficer;
    part operationsOwner : OperationsOwner;
}
