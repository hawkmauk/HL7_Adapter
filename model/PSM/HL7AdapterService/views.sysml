package PSM_HL7AdapterService_Views {

    alias Verification for PSM_HL7AdapterService_Verification;

    private import Views::*;
    private import PSM::*;
    private import PIM::*;
    private import Verification::*;
    private import MDA::Lifecycle::*;
    private import MDA::Structure::*;
    private import MDA::PSM::View::*;

    package ConcernMapping {
        private import CIM::Stakeholders::*;

        doc /* PSM-level concerns with trace to stakeholders; coverage requirements reference these concerns. */

        concern def CON_PSM_001_PlatformRealization {
            doc /* Technology selection, physical architecture, and interface bindings for implementation. Evidence: PSM::TechnologySelection::**, PSM::PhysicalArchitecture::**, PSM::Interfaces::**. */
            subject hl7AdapterService : HL7AdapterService;
            stakeholder integrationEngineer : IntegrationEngineer;
            stakeholder operationsEngineer : OperationsEngineer;
        }
        concern platformRealization : CON_PSM_001_PlatformRealization;

        concern def CON_PSM_002_CodeRealization {
            doc /* Model content selected for TypeScript/code generation. Evidence: PSM::PhysicalArchitecture::**, PSM::Actions::**, PIM::Behavior::**. */
            subject hl7AdapterService : HL7AdapterService;
            stakeholder integrationEngineer : IntegrationEngineer;
        }
        concern codeRealization : CON_PSM_002_CodeRealization;

        concern def CON_PSM_003_TestRealization {
            doc /* Verification cases selected for TypeScript test generation. Evidence: Verification::**. */
            subject hl7AdapterService : HL7AdapterService;
            stakeholder integrationEngineer : IntegrationEngineer;
        }
        concern testRealization : CON_PSM_003_TestRealization;
    }

    package Viewpoint {
        doc /* Concrete project PSM viewports bound to the MDA_PSM viewpoints. */

        view VPT_PSM_001_PlatformRealization {
            satisfy platformRealizationViewpoint;
            expose PSM::TechnologySelection::**;
            expose PSM::HL7Adapter::ErrorHandler::*;
            expose PSM::HL7Adapter::Interface::*;
            render asElementTable;
        }

        view VPT_PSM_002_CodeRealization {
            satisfy codeRealizationViewpoint;
            expose PIM::Behavior::**;
        }

        view VPT_PSM_003_TestRealization {
            satisfy testRealizationViewpoint;
            expose Verification::**;
        }
    }

    package CoverageMatrix {
        doc /* PSM-level trace matrix from concerns to viewpoints/viewports and PSM documents/code views. */

        requirement CM_PSM_001 {
            doc /* platformRealization -> VPT_PSM_001_PlatformRealization -> PlatformRealization_Document. */
            satisfy ConcernMapping::platformRealization;
        }

        requirement CM_PSM_002 {
            doc /* codeRealization -> VPT_PSM_002_CodeRealization -> TypeScriptCode_Document. */
            satisfy ConcernMapping::codeRealization;
        }

        requirement CM_PSM_003 {
            doc /* testRealization -> VPT_PSM_003_TestRealization -> TypeScriptTest_Document. */
            satisfy ConcernMapping::testRealization;
        }
    }

    package PSMDocumentBlueprints {
        doc /* PSM document and code view blueprints represented as model views bound to PSM viewports. */

        view DOC_PSM_PlatformRealization : PlatformRealization_Document {
            doc /* PSM Platform Realization and Technology Selection for the HL7 Adapter. */
            expose Viewpoint::VPT_PSM_001_PlatformRealization;
            expose CoverageMatrix::CM_PSM_001;
        }

        view DOC_PSM_TypeScriptCode : TypeScriptCode_Document {
            doc /* TypeScript/Node.js code realization for the HL7 Adapter. */
            expose Viewpoint::VPT_PSM_002_CodeRealization;
            expose CoverageMatrix::CM_PSM_002;
        }

        view DOC_PSM_TypeScriptTests : TypeScriptTest_Document {
            doc /* TypeScript/Vitest test realization from verification cases. */
            expose Viewpoint::VPT_PSM_003_TestRealization;
            expose CoverageMatrix::CM_PSM_003;
        }
    }
}
