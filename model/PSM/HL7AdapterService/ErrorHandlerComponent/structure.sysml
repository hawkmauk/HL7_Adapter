package PSM_ErrorHandler_Structure {

    private import ScalarValues::*;

    doc /* Error handler taxonomy and structured types: classification enum, log entry, metrics, dead-letter. */

    enum def ErrorClass {
        enum ParseError;
        enum ValidationError;
        enum ConnectionError;
        enum TimeoutError;
        enum HTTPClientError;
        enum HTTPServerError;
    }

    part def <IntegrationErrorInput> 'Integration Error Input' {
        doc /* Input shape for handleIntegrationError: code, message, recoverable flag, timestamp; aligns with CIM IntegrationError. */
        attribute code : String;
        attribute messageText : String;
        attribute isRecoverable : Boolean;
        attribute occurredAt : String;
        attribute statusCode : Integer [0..1];
        attribute messageId : String [0..1];
    }

    part def <StructuredLogEntry> 'Structured Log Entry' {
        doc /* One JSON log entry for an integration error. */
        attribute timestamp : String;
        attribute error_class : ErrorClass;
        attribute component : String;
        attribute message_id : String;
        attribute detail : String;
        attribute severity : String;
    }

    part def <MetricsCounters> 'Metrics Counters' {
        doc /* In-memory counters: total errors and per-class counts. */
        attribute errors_total : Integer;
        attribute errors_parse_error : Integer;
        attribute errors_validation_error : Integer;
        attribute errors_connection_error : Integer;
        attribute errors_timeout_error : Integer;
        attribute errors_http_client_error : Integer;
        attribute errors_http_server_error : Integer;
    }

    part def <DeadLetterEntry> 'Dead Letter Entry' {
        doc /* One dead-letter record: message id and error context. */
        attribute message_id : String;
        attribute error_context : String;
    }
}
