package PSM_Transformer_Actions {

    alias Transformer for PSM_TransformerComponent::Transformer;

    private import ScalarValues::*;
    private import PSM::HL7Adapter::Parser::Structure::*;
    private import PSM_HL7AdapterService_Structure::*;
    doc /* Transformer action definitions (transform to JSON, handle request, initialize). */

    action def <TransformToJSON> 'Transform To JSON' {
        in parsed : ParsedHL7;
        in jsonPrettyPrint : Integer;
        in schemaValidateOutput : Integer;
        out result : String;
        doc /* Pure transform: map parsed HL7 to output JSON string. Optional schema check. */

        rep functionBody language "TypeScript"
        /*
  const out: TransformOutput = {};
  if (parsed.msh) {
    out.messageType = parsed.msh.messageType;
    out.messageControlId = parsed.msh.messageControlId;
  }
  if (parsed.pid) {
    out.patientId = parsed.pid.patientIdList;
    out.patientName = parsed.pid.patientName;
    out.dateOfBirth = parsed.pid.dateOfBirth;
  }
  if (schemaValidateOutput && !out.messageType && !out.messageControlId) {
    throw new Error('Schema validation failed: messageType or messageControlId required');
  }
  result = jsonPrettyPrint ? JSON.stringify(out, null, 2) : JSON.stringify(out);
        */
    }

    action def <HandleTransformRequest> 'Handle Transform Request' {
        in :> self : Transformer;
        in parsed : ParsedHL7;
        doc /* Transform parsed message, dispatch HL7TransformerCompleteSignal or HL7TransformerFailedSignal and emit transformComplete. */

        rep textualRepresentation language "TypeScript"
        /*
  try {
    const jsonStr = transformPayload(
      parsed,
      this._config.jsonPrettyPrint,
      this._config.schemaValidateOutput,
    );
    this._dispatch('HL7TransformerCompleteSignal');
    this.emit('transformComplete', jsonStr);
  } catch (err) {
    this._dispatch('HL7TransformerFailedSignal');
    this.emit('transformFailed', err instanceof Error ? err.message : String(err));
  }
        */
    }

    action def <InitializeTransformer> 'Initialize Transformer' {
        in :> self : Transformer;
        doc /* Sets this part's attributes from runtimeConfig for use at construction/bootstrap. Maps mappingConfigPath, jsonPrettyPrint, schemaValidateOutput from runtimeConfig. */
    }

    action def <GetStatus> 'Get Status' {
        in :> self : Transformer;
        out result : HL7AdapterServiceStatus;
        doc /* Return current component state for health/status endpoints. */
        rep functionBody language "TypeScript"
        /*
  result = { status: this.state };
        */
    }
}
