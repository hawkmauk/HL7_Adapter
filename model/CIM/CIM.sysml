package CIM {
    doc /* Root CIM package. Content lives in CIM_* packages (one per file); aliases preserve CIM::Domain, CIM::Actions, etc. for views and imports. */

    alias Domain for CIM_Domain;
    alias Stakeholders for CIM_Stakeholders;
    alias Context for CIM_Context;
    alias Events for CIM_Events;
    alias Actions for CIM_Actions;
    alias UseCases for CIM_UseCases;
    alias Mission for CIM_Mission;
    alias Assumptions for CIM_Assumptions;
    alias LifecycleAlignment for CIM_LifecycleAlignment;
}
