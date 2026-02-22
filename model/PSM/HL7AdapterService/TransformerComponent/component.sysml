package PSM_TransformerComponent {

    alias Actions for PSM_Transformer_Actions;
    alias Logger for PSM_Logging_Structure::Logger;
    private import Actions::*;

    private import ScalarValues::*;
    
    doc /* PSM Transformer component. Refines PIM::LogicalArchitecture::Transformer. */

    part def <Transformer> 'Transformer' :> PIM::LogicalArchitecture::Transformer {
        doc /* Refines PIM::LogicalArchitecture::Transformer. Technology binding: TypeScript/JavaScript (object to JSON). Field mapping configuration, JSON serialization strategy, optional schema validation. */
        attribute mappingConfigPath : String { doc /* Path or name of the field-mapping configuration (HL7 to JSON). */ }
        attribute jsonPrettyPrint : Integer { doc /* When non-zero, serialize JSON with indentation for readability. */ }
        attribute schemaValidateOutput : Integer { doc /* When non-zero, validate output JSON against a schema before forwarding. */ }
        attribute logger : Logger [0..1] { doc /* Supplied by adapter from shared logging facility. */ }

        perform action transformPayload : TransformToJSON;
        perform action handleTransformRequest : HandleTransformRequest;
        perform action initializeFromBinding : InitializeTransformer;
        perform action getStatus : Actions::GetStatus;
    }
}
