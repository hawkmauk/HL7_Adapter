package PSM_Views {

    private import Views::*;
    private import PSM::*;
    private import MDA::PSM::View::*;

    package PSMDocumentBlueprints {
        doc /* PSM document: platform realization and component design. */

        view DOC_PSM_PlatformRealization : PlatformRealization_Document {
            doc /* PSM Platform Realization and Technology Selection for the HL7 Adapter. */
            expose PSM::TechnologySelection::**;
            expose PSM::PhysicalArchitecture::**;
        }
    }
}
