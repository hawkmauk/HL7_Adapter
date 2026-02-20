package CIM_UseCases {
    doc /* CIM-level use cases derived from the HandleMessage operation and event-centric message flows. */

    private import CIM_Stakeholders::*;
    private import CIM_Context::*;
    private import CIM_Domain::*;
    private import CIM_Actions::*;
    private import CIM_Mission::*;
    private import CIM_Events::*;

    /* Core use case that orchestrates the CIM operational story. */
    use case 'Ingest and Forward Event (CIM)' {

        subject adapterService : HL7AdapterService;

        actor upstreamSystem : UpstreamHL7System;
        actor downstreamApiOwner : DownstreamAPIOwner;
        actor operationsEngineer : OperationsEngineer;

        objective {
            doc
            /* Main Success Scenario
               ---------------------
               1. upstreamSystem sends an HL7Message framed in an MLLPFrame towards adapterService
                  (Send MLLP Frame – msgMLLPFrame from upstreamSystem.msgMLLPFrameSent to
                  adapterService.msgMLLPFrameReceived).
               2. adapterService receives the MLLPFrame and unwraps it into an HL7Message for
                  further handling (Receive MLLP Frame / Handle Frame).
               3. adapterService extracts demographics and metadata and composes a JSONPayload
                  from the HL7Message (Handle HL7 Message – CreateMetadata, CreateDemographics,
                  CreateJsonPayload).
               4. adapterService sends the JSONPayload to a RESTEndpoint owned by
                  downstreamApiOwner (Send JSON Payload – JSONPayloadExchange).
               5. downstreamApiOwner receives the JSONPayload (Receive JSON Payload).
               6. No IntegrationError is raised; the event is considered successfully ingested
                  and forwarded.

               Alternate Paths
               ---------------
               A1. HL7 content variations
                   - As described in Handle HL7 Message (optional segments omitted, additional
                     non‑critical segments present), extraction still yields a clinically
                     sufficient JSONPayload.
                   - Rejoin at step 3 when JSONPayload is composed successfully.

               A2. Multiple logical REST endpoints
                   - As described in Send JSON Payload, adapterService selects among multiple
                     RESTEndpoint variants based on JSONPayload content.
                   - Rejoin at step 4 once JSONPayload is successfully posted.

               Exception Paths
               ---------------
               E1. Frame‑level failures (oversized frame, connection reset/timeout)
                   - As described in Receive MLLP Frame, adapterService records an
                     IntegrationError and does not proceed to HL7 handling.
                   - Control flows into Handle Integration Error (CIM); this scenario does not
                     rejoin the main success path.

               E2. HL7 content errors (malformed header, missing mandatory data)
                   - As described in Handle HL7 Message, a ParseError/IntegrationError is
                     raised and handled by Handle Integration Error (CIM).
                   - Scenario terminates in degraded mode; no rejoin to step 3.

               E3. Delivery failures (downstream HTTP / policy issues)
                   - As described in Send JSON Payload, a DeliveryError/IntegrationError is
                     raised and handled by Handle Integration Error (CIM).
                   - Scenario terminates in degraded mode; no rejoin to step 5. */
        }

        include 'Send MLLP Frame';
        include 'Receive MLLP Frame';
        include 'Handle HL7 Message';
        include 'Send JSON Payload';
        include 'Receive JSON Payload';
        include 'Handle Integration Error (CIM)';
    }

    /* CIM-level use cases decomposed from the main flow. */

    use case 'Send MLLP Frame' {
        doc /* Upstream HL7 system sends an MLLPFrame (containing an HL7Message) to the adapter. */
        private import CIM_Domain::*;
        private import CIM_Events::*;

        subject upstreamSystem : UpstreamHL7System {
            event occurrence msgMLLPFrameSent : MLLPFrameSent;
        }
        actor adapterService : HL7AdapterService{
            event occurrence msgMLLPFrameReceived : MLLPFrameReceived;
        }
        message msgMLLPFrame of MLLPFrame
            from upstreamSystem.msgMLLPFrameSent to adapterService.msgMLLPFrameReceived;

        first msgMLLPFrame;
        then done;

        objective {
            doc
            /* Primary scenario
               ----------------
               upstreamSystem creates an HL7Message and frames it in an MLLPFrame, then
               conceptually sends that frame towards adapterService.
               - Message flow: msgMLLPFrame of MLLPFrame from
                 upstreamSystem.msgMLLPFrameSent to adapterService.msgMLLPFrameReceived.
               - Domain: HL7Message, MLLPFrame, MessageMetadata.
               - Mission: Reliable Event Ingestion (M1).

               Alternate scenarios (still successful)
               --------------------------------------
               A1. Message with optional segments omitted
                   - HL7Message omits optional segments while still containing all mandatory content.
                   - Downstream parsing remains valid; no IntegrationError is raised.

               A2. Large but acceptable payload
                   - HL7Message size approaches, but does not exceed, the conceptual maxPayloadSize for MLLPFrame.
                   - Message is still accepted for processing at CIM level.

               A3. Multiple publishers
                   - Several UpstreamHL7System instances send HL7Message instances independently.
                   - Each message follows the same conceptual send interaction with adapterService. */
        }
    }

    use case 'Receive MLLP Frame' {

        private import CIM_Domain::*;
        private import CIM_Events::*;

        subject adapterService : HL7AdapterService{
            event occurrence msgMLLPFrameReceived : MLLPFrameReceived;
        }
        actor upstreamSystem : UpstreamHL7System {
            event occurrence msgMLLPFrameSent : MLLPFrameSent;
        }
        message msgMLLPFrame of MLLPFrame
            from upstreamSystem.msgMLLPFrameSent to adapterService.msgMLLPFrameReceived;

        action extract : CreateHL7Message;
        flow from msgMLLPFrame to extract.mllpFrame;

        first msgMLLPFrame;
        then extract;
        then done;

        objective {
            doc
            /* Primary scenario
               ----------------
               adapterService conceptually receives the MLLPFrame and unwraps it to obtain
               an HL7Message for further processing.
               - Message flow: msgMLLPFrame of MLLPFrame from
                 upstreamSystem.msgMLLPFrameSent to adapterService.msgMLLPFrameReceived.
               - Action flow: CreateHL7Message reads the received MLLPFrame
                 (flow from msgMLLPFrame to extract.mllpFrame) and creates the HL7Message.
               - Operations: ReceiveMLLPFrame (frame ingress) and ExtractHL7Message / CreateHL7Message
                 (HL7 content extraction).
               - Domain: MLLPFrame, HL7Message.

               Exception scenarios (receive stage)
               -----------------------------------
               E1. Oversized frame
                   - MLLPFrame.payloadLength exceeds the recommended maxPayloadSize.
                   - adapterService treats this as an IntegrationError case rather than proceeding to parse.

               E2. Connection reset or timeout
                   - The conceptual connection between upstreamSystem and adapterService is broken mid-transfer.
                   - The partially received HL7Message is not processed further at CIM; an IntegrationError is recorded. */
        }
    }

    use case 'Handle HL7 Message' {

        subject adapterService : HL7AdapterService {
            event occurrence msgHL7MessageCreated : Created;
        }
        part hl7Message : HL7Message;

        message hl7MessageCreated
            from hl7Message.created to adapterService.msgHL7MessageCreated;

        action extractMetadata : CreateMetadata;
        action extractDemographics : CreateDemographics;
        action composeJsonPayload : CreateJsonPayload;
        action sendError : CreateIntegrationError;

        flow from hl7MessageCreated to extractMetadata.hl7Message;
        flow from hl7MessageCreated to extractDemographics.hl7Message;
        flow from extractMetadata.'metadata' to composeJsonPayload.'metadata';
        flow from extractDemographics.demographics to composeJsonPayload.demographics;

        first hl7MessageCreated;
        then fork;
            then extractMetadata;
            then extractDemographics;
        then join;
        if extractMetadata.success and extractDemographics.success then composeJsonPayload; else sendError;
        then done;

        objective {
            doc
            /* Main Success Scenario
               ---------------------
               1. An HL7Message instance is created from a received MLLPFrame; its creation is
                  signalled to adapterService (message hl7MessageCreated from hl7Message.created
                  to adapterService.msgHL7MessageCreated).
               2. adapterService forks into two parallel extraction actions:
                  - CreateMetadata to derive MessageMetadata from the HL7Message.
                  - CreateDemographics to derive PatientDemographics from the HL7Message.
               3. Both CreateMetadata and CreateDemographics succeed, producing 'metadata' and
                  demographics outputs.
               4. adapterService composes a JSONPayload in CreateJsonPayload from metadata and
                  demographics (flows from extractMetadata.'metadata' and
                  extractDemographics.demographics).
               5. The JSONPayload is made available for subsequent sending to downstream
                  systems.

               Alternate Paths
               ---------------
               A1. Optional clinical segments omitted
                   - HL7Message lacks certain optional segments; required PatientDemographics
                     and core fields are present.
                   - Both extraction actions still succeed, though demographics may be
                     partially populated.
                   - Rejoin at step 3/4 when CreateJsonPayload has sufficient inputs.

               A2. Additional non‑critical segments present
                   - HL7Message contains extra segments not used by this adapter.
                   - These are ignored; extraction focuses on required content.
                   - Rejoin at step 3/4 with normal JSONPayload composition.

               A3. Mapping with optional JSON fields omitted
                   - Certain fields in JSONPayload are absent because corresponding HL7
                     segments were optional.
                   - Clinical meaning required for the mission is still preserved.
                   - Rejoin at step 5 with a valid but partially populated JSONPayload.

               A4. Additional derived JSON fields
                   - adapterService derives additional non‑essential (summary) fields in
                     JSONPayload.
                   - CIM records these without prescribing detailed implementation.
                   - Rejoin at step 5 with an enriched JSONPayload.

               Exception Paths
               ---------------
               E3. Malformed header or segment structure
                   - HL7Message has an invalid structure (e.g. malformed MSH, inconsistent
                     field separators).
                   - A ParseError is raised, linked to HL7Message and relevant segmentId/fieldPath.
                   - Flow proceeds to CreateIntegrationError / Handle Integration Error (CIM);
                     this path does not rejoin the main success scenario.

               E4. Missing mandatory patient data
                   - PatientDemographics lacks mandatory fields (e.g. patientId or dateOfBirth).
                   - Extraction/validation fails and records a ParseError, leading to degraded
                     handling via Handle Integration Error (CIM); no rejoin. */
        }
    }

    use case 'Send JSON Payload' {

        private import CIM_Domain::*;
        private import CIM_Events::*;

        item jsonPayload : JSONPayload;

        subject adapterService : HL7AdapterService {
            event occurrence msgJSONPayloadSent : JSONPayloadSent;
            event occurrence msgJSONPayloadCreated : Created;
        }
        actor downstreamApiOwner : DownstreamAPIOwner {
            event occurrence msgJSONPayloadReceived : JSONPayloadReceived;
        }

        message jsonPayloadCreated
            from jsonPayload.created to adapterService.msgJSONPayloadCreated;
        message JSONPayloadExchange of JSONPayload
            from adapterService.msgJSONPayloadSent to downstreamApiOwner.msgJSONPayloadReceived;

        first jsonPayloadCreated;
        then JSONPayloadExchange;
        then done;

        objective {
            doc
            /* Main Success Scenario
               ---------------------
               1. A JSONPayload instance is created by prior HL7 handling; its creation is
                  signalled to adapterService (message jsonPayloadCreated from jsonPayload.created
                  to adapterService.msgJSONPayloadCreated).
               2. adapterService prepares and sends the JSONPayload to a RESTEndpoint owned by
                  downstreamApiOwner (SendJSONPayload).
               3. The JSONPayload is received by downstreamApiOwner
                  (ReceiveJSONPayload – JSONPayloadExchange from
                  adapterService.msgJSONPayloadSent to downstreamApiOwner.msgJSONPayloadReceived).
               4. No DeliveryError or IntegrationError is raised; the handoff is considered
                  successful.

               Alternate Paths
               ---------------
               A1. Multiple logical endpoints
                   - RESTEndpoint represents a family of logical endpoints; adapterService
                     selects one based on JSONPayload content.
                   - All selected endpoints conceptually satisfy the same handoff intent.
                   - Rejoin at step 3 once JSONPayload is successfully received.

               Exception Paths
               ---------------
               E5. Downstream temporary failure (e.g. 503)
                   - RESTEndpoint responds with a temporary failure; a DeliveryError is recorded.
                   - Handling is delegated to Handle Integration Error (CIM); this scenario does
                     not rejoin the main success path.

               E6. Network or connectivity failure
                   - Conceptual network issues prevent delivery (e.g. connection reset, timeout).
                   - A DeliveryError is raised; no successful handoff occurs; flow proceeds to
                     Handle Integration Error (CIM); no rejoin.

               E7. Security or policy failure
                   - Conceptual security/policy constraints (e.g. PHIHandlingPolicy) prevent
                     forwarding.
                   - IntegrationError reflects the failure to meet M3/M4 obligations for this
                     message; flow proceeds to Handle Integration Error (CIM); no rejoin. */
        }
    }

    use case 'Receive JSON Payload' {
        doc /* Downstream API owner receives the JSONPayload that adapterService has sent. */
        private import CIM_Domain::*;
        private import CIM_Events::*;

        subject downstreamApiOwner : DownstreamAPIOwner {
            event occurrence msgJSONPayloadReceived : JSONPayloadReceived;
        }
        actor adapterService : HL7AdapterService {
            event occurrence msgJSONPayloadSent : JSONPayloadSent;
        }

        message jsonPayloadReceived of JSONPayload
            from adapterService.msgJSONPayloadSent to downstreamApiOwner.msgJSONPayloadReceived;

        first jsonPayloadReceived;
        then done;

    }

    use case 'Handle Integration Error (CIM)' {

        subject adapterService : HL7AdapterService {
            event occurrence msgIntegrationErrorCreated : Created;
        }

        actor operationsEngineer : OperationsEngineer;
        part integrationError : IntegrationError;

        message integrationErrorCreated
            from integrationError.created to adapterService.msgIntegrationErrorCreated;

        action handleIntegrationError : HandleIntegrationError;

        first integrationErrorCreated;
        then handleIntegrationError;
        then done;

        objective {
            doc
            /* Handle Integration Error (CIM) covers degraded scenarios conceptually
               described by the HandleMessage operation, including ParseError and DeliveryError.
               - Domain: IntegrationError, ParseError, DeliveryError.
               - Mission: Operational Transparency (M4).

               Example exception scenarios
               --------------------------
               E8. Accumulated retries exhausted
                   - DeliveryError.attemptCount indicates repeated unsuccessful attempts.
                   - adapterService ceases retrying and records a final IntegrationError.

               E9. Persistently malformed input
                   - HL7Message instances repeatedly fail parsing for the same structural reason.
                   - IntegrationError highlights a likely configuration or upstream data quality problem. */
        }
    }

    /* Requirement satisfaction relationships from CIM use cases to mission requirements. */

    satisfy 'M1.Reliable Event Ingestion' by 'Send MLLP Frame';
    satisfy 'M1.Reliable Event Ingestion' by 'Receive MLLP Frame';
    satisfy 'M2.Accurate Clinical Transformation' by 'Handle HL7 Message';
    satisfy 'M3.Secure Interoperability' by 'Send JSON Payload';
    satisfy 'M3.Secure Interoperability' by 'Receive JSON Payload';
    satisfy 'M4.Operational Transparency' by 'Handle Integration Error (CIM)';
}
