package CIM_Actions {
    doc /* High-level operational activities and scenarios, kept technology-agnostic at CIM level. */

    private import ScalarValues::*;
    private import CIM_Domain::*;
    private import CIM_Events::*;
    private import CIM_Datatype::*;

    action def <SendMLLPFrame> 'Send MLLP Frame' {
        doc /* Upstream actor publishes a framed HL7 event to the adapter listener. */
        in mllpFrame : MLLPFrame;
        out attribute success : Boolean;
    }

    action def <ReceiveMLLPFrame> 'Receive MLLP Frame' {
        doc /* Adapter accepts inbound framed data from a TCP connection. */
        in buffer : Buffer;
        in maxPayloadSize : Integer;
        out mllpFrame : MLLPFrame;
    }

    action def <CreateHL7Message> 'Create HL7 Message' {
        doc /* Extract the HL7 message from the MLLP frame. */
        in mllpFrame : MLLPFrame;
        out hl7Message : HL7Message;
        out attribute success : Boolean;
    }

    action def <CreateMetadata> 'Create Metadata' {
        doc /* Adapter maps selected HL7 fields into a stable JSON representation. */
        in hl7Message : HL7Message;
        out 'metadata' : MessageMetadata;
        out attribute success : Boolean;
    }

    action def <CreateDemographics> 'Create Demographics' {
        doc /* Extract the demographics from the HL7 message. */
        in hl7Message : HL7Message;
        out demographics : PatientDemographics;
        out attribute success : Boolean;
    }

    action def <CreateJsonPayload> 'Create JSON Payload' {
        doc /* Transform the HL7 message into a JSON payload. */
        in 'metadata' : MessageMetadata;
        in demographics : PatientDemographics;
        out jsonPayload : JSONPayload;
        out attribute success : Boolean;
    }

    action def <SendJSONPayload> 'Send JSON Payload' {
        doc /* Send the JSON payload to the downstream API. */
        in jsonPayload : JSONPayload;
        out attribute success : Boolean;
    }

    action def <ReceiveJSONPayload> 'Receive JSON Payload' {
        doc /* Receive the JSON payload from the downstream API. */
        out jsonPayload : JSONPayload;
        out attribute success : Boolean;
    }

    action def <CreateIntegrationError> 'Create Integration Error' {
        doc /* Adapter handles an integration error. */
        out integrationError : IntegrationError;
    }

    action def <HandleIntegrationError> 'Handle Integration Error' {
        doc /* Adapter handles an integration error. */
        in integrationError : IntegrationError;
    }

    /* Coarse-grained CIM-level flow for ingestion and forwarding. */
    action def <HandleFrame> 'Handle Frame' {

        doc /* Main CIM-level flow from publish through receive, parse, transform, and post.
           Detailed protocol-specific behavior and error handling are refined in PIM behavior. */

        in mllpFrame : MLLPFrame;

        action extract : CreateHL7Message;
        action sendError : CreateIntegrationError;

        flow from mllpFrame to extract.mllpFrame;

        first start;
        then extract;
        if extract.success then done; else sendError;

        out attribute success : Boolean = extract.success;
    }

    action def <HandleMessage> 'Handle Message' {
        doc /* Main CIM-level flow from publish through receive, parse, transform, and post. */

        in hl7message : HL7Message;

        action createMetadata : CreateMetadata;
        action createDemographics : CreateDemographics;
        action createJsonPayload : CreateJsonPayload;
        action createIntegrationError : CreateIntegrationError;

        flow from hl7message to createMetadata.hl7Message;
        flow from hl7message to createDemographics.hl7Message;
        flow from createMetadata.'metadata' to createJsonPayload.'metadata';
        flow from createDemographics.demographics to createJsonPayload.demographics;

        first hl7message;
        then fork;
            then createMetadata;
            then createDemographics;
        then join;
        if createMetadata.success and createDemographics.success then createJsonPayload; else createIntegrationError;
        then done;

        out attribute success : Boolean = createMetadata.success and createDemographics.success;
    }

    action def <HandleJsonPayload> 'Handle Json Payload' {
        doc /* Downstream API owner receives the JSON payload. */

        in jsonPayload : JSONPayload;
    }

}
