package PSM_Transformer {

    private import PIM::*;
    private import PSM::Interfaces::*;
    private import PSM::Actions::*;
    private import ScalarValues::*;
    private import CIM::Datatype::*;

    doc /* PSM Transformer component. Refines PIM::LogicalArchitecture::Transformer. */

    part def <Transformer> 'Transformer' :> PIM::LogicalArchitecture::Transformer {
        doc /* Refines PIM::LogicalArchitecture::Transformer. Technology binding: TypeScript/JavaScript (object to JSON). Field mapping configuration, JSON serialization strategy, optional schema validation. */
        attribute mappingConfigPath : String { doc /* Path or name of the field-mapping configuration (HL7 to JSON). */ }
        attribute jsonPrettyPrint : Integer { doc /* When non-zero, serialize JSON with indentation for readability. */ }
        attribute schemaValidateOutput : Integer { doc /* When non-zero, validate output JSON against a schema before forwarding. */ }

        perform action transformPayload : TransformToJSON;
        perform action handleTransformRequest : HandleTransformRequest;
        perform action initializeFromBinding : InitializeTransformer;
    }
}
