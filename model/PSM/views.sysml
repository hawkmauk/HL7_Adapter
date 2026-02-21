package PSM_Views {

    private import Views::*;
    private import PSM::*;
    private import PIM::*;
    private import MDA::PSM::View::*;

    package PSMDocumentBlueprints {
        doc /* PSM document: platform realization and component design. */

        view DOC_PSM_PlatformRealization : PlatformRealization_Document {
            doc /* PSM Platform Realization and Technology Selection for the HL7 Adapter. */
            expose PSM::TechnologySelection::**;
            expose PSM::PhysicalArchitecture::**;
            expose PSM::Interfaces::**;
        }
    }

    package PSMCodeBlueprints {
        doc /* PSM code-generation views: one view per target platform. */

        view DOC_PSM_TypeScriptCode : TypeScriptCode_Document {
            doc /* TypeScript/Node.js code realization for the HL7 Adapter. */
            expose PSM::PhysicalArchitecture::**;
            expose PSM::Actions::**;
            expose PIM::Behavior::**;
        }
    }
}
