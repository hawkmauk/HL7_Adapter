package CIM_Domain {
    doc /* Domain ontology for a local HL7 to HTTPS integration context. */
    private import ScalarValues::*;
    private import CIM_Events::*;
    private import CIM_Datatype::*;

    part def <Observable> 'Observable' {
        doc /* Observable part that can be observed by the system. */
        event occurrence created : Created;
    }

    part def <Configuration> 'Configuration' {
        doc /* Configuration of a service or component. */

        attribute configuration : String;
    }

    part def <HL7DeliveryConfirmation> 'HL7 Delivery Confirmation' {
        doc /* Conceptual representation of a confirmation of HL7 delivery to the adapter listener. */

        attribute controlId : String;
        attribute sentTimestamp : String;

    }

    part def <HL7Message> 'HL7 Message' :> 'Observable' {
        doc /* Conceptual representation of an inbound HL7 message (any version) in the integration context. */

        attribute messageType : String;
        attribute triggerEvent : String;
        attribute controlId : String;
        attribute sentTimestamp : String;
        attribute rawMessage : SensitiveData;

    }

    part def <MLLPFrame> 'MLLP Frame' :> 'Observable' {
        doc /* Transport framing envelope used to delimit HL7 payloads on TCP streams. */

        attribute startDelimiter : String;
        attribute endDelimiter : String;
        attribute payloadLength : Integer;

    }

    part def <PatientDemographics> 'Patient Demographics' {
        doc /* Conceptual patient data extracted from HL7 segments, such as PID content. */

        attribute patientId : String;
        attribute givenName : SensitiveData;
        attribute familyName : SensitiveData;
        attribute dateOfBirth : String;
        attribute gender : String;

    }

    part def <MessageMetadata> 'Message Metadata' {
        doc /* Conceptual metadata extracted from MSH fields, including trigger event type. */

        attribute sendingApplication : String;
        attribute sendingFacility : String;
        attribute receivingApplication : String;
        attribute receivingFacility : String;
        attribute sequenceNumber : String;

    }

    part def <JSONPayload> 'JSON Payload' :> 'Observable' {
        doc /* Structured payload produced from HL7 content and posted to a REST endpoint. */

        attribute payloadType : String;
        attribute schemaVersion : String;
        attribute body : SensitiveData;

    }

    part def <RESTEndpoint> 'REST Endpoint' {
        doc /* Conceptual HTTP interface that receives transformed clinical event payloads. */

        attribute name : String;
        attribute resourcePath : String;
        attribute purpose : String;
        attribute interactionStyle : String;

    }

    part def <IntegrationError> 'Integration Error' :> 'Observable' {
        doc /* Any recoverable or non-recoverable operational issue during receive, parse, map, or forward. */

        attribute code : String;
        attribute messageText : String;
        attribute isRecoverable : Boolean;
        attribute occurredAt : String;

    }

    part def <ParseError> 'Parse Error' :> 'Integration Error' {
        doc /* Error caused by malformed HL7 structure or missing required fields. */

        attribute segmentId : String;
        attribute fieldPath : String;

    }

    part def <DeliveryError> 'Delivery Error' :> 'Integration Error' {
        doc /* Error caused by network, API availability, or unsuccessful HTTP response. */

        attribute statusCode : Integer;
        attribute endpointName : String;
        attribute attemptCount : Integer;

    }
}
