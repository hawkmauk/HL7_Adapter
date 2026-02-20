package PSM_View {

    private import Views::*;
    private import MDA_View::*;
    private import PSM_Viewpoint::*;
    private import PSM::*;

    viewpoint platformRealizationViewpoint : PSM_Viewpoint::PSMStandardViewpointCatalog::PlatformRealizationViewpoint;

    view def <PlatformRealization_Document> 'PSM Platform Realization and Technology Selection' {
        doc /* Captures technology selections (trade studies) and PSM physical architecture with technology bindings. Renders TechnologySelection and PhysicalArchitecture for the HL7 Adapter. */
        satisfy platformRealizationViewpoint;
        render asElementTable;

        view <TechnologySelectionSection> 'Technology Selection' {
            doc
            /* This section presents the technology trade studies and selection rationale:
               language/runtime, HL7 parser, HTTP client, and deployment model.
             */
            expose PSM::TechnologySelection::**;
        }

        view <PhysicalArchitectureSection> 'Physical Architecture' {
            doc
            /* This section describes the PSM components that refine PIM logical components,
               with technology bindings (e.g. Node.js/TypeScript, node-hl7-complete, axios/undici, AWS/Terraform).
             */
            expose PSM::PhysicalArchitecture::**;
        }
    }
}
