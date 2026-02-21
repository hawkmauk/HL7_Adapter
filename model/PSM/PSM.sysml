package PSM {
    doc /* PSM package: technology-specific design for the HL7 Adapter. Contains TechnologySelection (trade studies), PhysicalArchitecture (PIM components with implementation attributes), and Interfaces (protocol bindings and PSM port/interface defs). */

    alias TechnologySelection for PSM_TechnologySelection;
    alias HL7Adapter for PSM_HL7AdapterService;
    alias HL7AdapterService for PSM_HL7AdapterService::HL7AdapterService;

    /* Our main object */
    part hl7AdapterService : HL7AdapterService;
}
