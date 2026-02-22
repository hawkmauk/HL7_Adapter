package PSM_OperationalStore_Structure {

    private import ScalarValues::*;

    doc /* Operational store schema types derived from CIM domain (HL7Message, MLLPFrame, IntegrationError, DeliveryError). AIM S12.2–12.4. */

    part def <MessageRecord> 'Message Record' {
        doc /* One row in messages table: message_id (PK), received_at, message_type, status, optional control_id, raw_length. */
        attribute message_id : String;
        attribute received_at : String;
        attribute message_type : String;
        attribute status : String;
        attribute control_id : String [0..1];
        attribute raw_length : Integer [0..1];
    }

    part def <DeliveryAttemptRecord> 'Delivery Attempt Record' {
        doc /* One row in delivery_attempts table: id (PK), message_id (FK), attempt, status_code, response_time_ms, timestamp. */
        attribute id : Integer;
        attribute message_id : String;
        attribute attempt : Integer;
        attribute status_code : Integer;
        attribute response_time_ms : Integer [0..1];
        attribute timestamp : String;
    }

    part def <ErrorRecord> 'Error Record' {
        doc /* One row in errors table: id (PK), message_id (FK), error_class, detail, timestamp. */
        attribute id : Integer;
        attribute message_id : String;
        attribute error_class : String;
        attribute detail : String;
        attribute timestamp : String;
    }

    part def <MessageStatusQueryResult> 'Message Status Query Result' {
        doc /* Result shape for getMessageStatus / getMessages: message_id, status, received_at, message_type, control_id, delivery_attempts (optional). */
        attribute message_id : String;
        attribute status : String;
        attribute received_at : String;
        attribute message_type : String [0..1];
        attribute control_id : String [0..1];
    }
}
