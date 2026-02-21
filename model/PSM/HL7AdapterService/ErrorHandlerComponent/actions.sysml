package PSM_ErrorHandler_Actions {

    alias ErrorHandler for PSM_ErrorHandlerComponent::ErrorHandler;

    private import PSM_ErrorHandler_Structure::*;

    doc /* Error handler initialization and handle-integration-error actions. */

    action def <InitializeErrorHandler> 'Initialize Error Handler' {
        in :> self : ErrorHandler;
        doc /* Sets this part's attributes from runtimeConfig for use at construction/bootstrap. Maps logLevel, metricsPrefix, deadLetterPath, classificationTaxonomy from runtimeConfig. */
    }

    action def <HandleIntegrationError> 'Handle Integration Error' {
        in integrationError : IntegrationErrorInput;
        in :> self : ErrorHandler;
        doc /* Classify error, write structured log, update metrics, append dead-letter, then dispatch EscalationCompletedSignal or RequiresEscalationSignal. */
        rep functionBody language "TypeScript"
        /*
  const err = integrationError;
  let classified: ErrorClass = ErrorClass.ParseError;
  if (err.code === 'PARSE_ERROR' || err.code?.startsWith('PARSE_')) classified = ErrorClass.ParseError;
  else if (err.code === 'VALIDATION_ERROR' || err.code?.startsWith('VALIDATION_')) classified = ErrorClass.ValidationError;
  else if (err.code === 'CONNECTION_ERROR' || err.code?.startsWith('CONNECTION_')) classified = ErrorClass.ConnectionError;
  else if (err.code === 'TIMEOUT' || err.code?.startsWith('TIMEOUT')) classified = ErrorClass.TimeoutError;
  else if (err.statusCode != null && err.statusCode >= 400 && err.statusCode < 500) classified = ErrorClass.HTTPClientError;
  else if (err.statusCode != null && err.statusCode >= 500) classified = ErrorClass.HTTPServerError;
  const logEntry: StructuredLogEntry = {
    timestamp: err.occurredAt ?? new Date().toISOString(),
    error_class: classified,
    component: 'ErrorHandler',
    message_id: err.messageId ?? '',
    detail: err.messageText ?? '',
    severity: err.isRecoverable ? 'warn' : 'error',
  };
  logger.info(logEntry, 'integration error');
  this._metrics.errors_total = (this._metrics.errors_total ?? 0) + 1;
  if (classified === ErrorClass.ParseError) this._metrics.errors_parse_error = (this._metrics.errors_parse_error ?? 0) + 1;
  else if (classified === ErrorClass.ValidationError) this._metrics.errors_validation_error = (this._metrics.errors_validation_error ?? 0) + 1;
  else if (classified === ErrorClass.ConnectionError) this._metrics.errors_connection_error = (this._metrics.errors_connection_error ?? 0) + 1;
  else if (classified === ErrorClass.TimeoutError) this._metrics.errors_timeout_error = (this._metrics.errors_timeout_error ?? 0) + 1;
  else if (classified === ErrorClass.HTTPClientError) this._metrics.errors_http_client_error = (this._metrics.errors_http_client_error ?? 0) + 1;
  else if (classified === ErrorClass.HTTPServerError) this._metrics.errors_http_server_error = (this._metrics.errors_http_server_error ?? 0) + 1;
  if (this._config.deadLetterPath) {
    const fs = require('fs');
    const dlEntry: DeadLetterEntry = { message_id: logEntry.message_id, error_context: JSON.stringify(logEntry) };
    try { fs.appendFileSync(this._config.deadLetterPath, JSON.stringify(dlEntry) + '\n'); } catch (_) {}
  }
      if (err.isRecoverable) this._dispatch('EscalationCompletedSignal');
  else this._dispatch('RequiresEscalationSignal');
  this._lastError = err.messageText ?? null;
        */
    }

    action def <GetStatus> 'Get Status' {
        in :> self : ErrorHandler;
        doc /* Return current component status (ready | degraded) and optional last error message for health/status endpoints. */
        rep functionBody language "TypeScript"
        /*
  return { status: this._lastError ? 'degraded' as const : 'ready' as const, lastError: this._lastError ?? undefined };
        */
    }

    action def <GetMetrics> 'Get Metrics' {
        out result : ErrorHandlerMetrics;
        in :> self : ErrorHandler;
        doc /* Return a snapshot of error and message-flow metrics for monitoring and tests. */
        rep functionBody language "TypeScript"
        /*
  return { ...this._metrics };
        */
    }

    action def <RecordMessageReceived> 'Record Message Received' {
        in :> self : ErrorHandler;
        doc /* Increment messages_received (call when MLLP frame is received successfully). */
        rep functionBody language "TypeScript"
        /*
  this._metrics.messages_received = (this._metrics.messages_received ?? 0) + 1;
        */
    }

    action def <RecordMessageParsed> 'Record Message Parsed' {
        in :> self : ErrorHandler;
        doc /* Increment messages_parsed (call when HL7 message is parsed successfully). */
        rep functionBody language "TypeScript"
        /*
  this._metrics.messages_parsed = (this._metrics.messages_parsed ?? 0) + 1;
        */
    }

    action def <RecordMessageTransformed> 'Record Message Transformed' {
        in :> self : ErrorHandler;
        doc /* Increment messages_transformed (call when HL7 is transformed to JSON successfully). */
        rep functionBody language "TypeScript"
        /*
  this._metrics.messages_transformed = (this._metrics.messages_transformed ?? 0) + 1;
        */
    }

    action def <RecordMessageDelivered> 'Record Message Delivered' {
        in :> self : ErrorHandler;
        doc /* Increment messages_delivered (call when JSON payload is delivered with 2xx). */
        rep functionBody language "TypeScript"
        /*
  this._metrics.messages_delivered = (this._metrics.messages_delivered ?? 0) + 1;
        */
    }
}
