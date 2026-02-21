package PSM_View {

    private import Views::*;
    private import MDA_View::*;
    private import PSM_Viewpoint::*;
    private import PSM::*;

    viewpoint platformRealizationViewpoint : PSM_Viewpoint::PSMStandardViewpointCatalog::PlatformRealizationViewpoint;
    viewpoint codeRealizationViewpoint : PSM_Viewpoint::PSMStandardViewpointCatalog::CodeRealizationViewpoint;

    view def <TypeScriptCode_Document> 'TypeScript Code Realization' {
        doc /* Selects PSM components, actions, and PIM behavior for Node.js/TypeScript code generation. */
        satisfy codeRealizationViewpoint;
        render asTypeScriptApplication;
    }

    view def <PlatformRealization_Document> 'PSM Platform Realization and Technology Selection' {
        doc /* Captures technology selections and PSM physical architecture with implementation attributes. */
        satisfy platformRealizationViewpoint;
        render asElementTable;

        view <TechnologySelectionSection> 'Technology Selection' {
            doc /* Technology trade studies and selection rationale. */
            expose PSM::TechnologySelection::**;
        }

        view <PhysicalArchitectureSection> 'Physical Architecture' {
            doc /* PSM components refining PIM with technology bindings and implementation-specific attributes (config, library types). */
            expose PSM::PhysicalArchitecture::**;
        }

        view <InterfaceBindingsSection> 'Interface Bindings' {
            doc /* PSM interface bindings: MLLP ingress, HTTP egress, runtime config; protocol parameters with types and defaults; PSM port/interface defs refining PIM. */
            expose PSM::Interfaces::**;
        }
    }
}
