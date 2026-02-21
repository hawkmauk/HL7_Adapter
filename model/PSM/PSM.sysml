package PSM {
    doc /* PSM package: technology-specific design for the HL7 Adapter. Contains TechnologySelection (trade studies), PhysicalArchitecture (PIM components with implementation attributes), and Interfaces (protocol bindings and PSM port/interface defs). */

    alias TechnologySelection for PSM_TechnologySelection;
    alias PhysicalArchitecture for PSM_PhysicalArchitecture;
    alias Interfaces for PSM_Interfaces;
    alias Actions for PSM_Actions;

    /* Our main object */
    part hl7AdapterService : PhysicalArchitecture::HL7AdapterService;
}
