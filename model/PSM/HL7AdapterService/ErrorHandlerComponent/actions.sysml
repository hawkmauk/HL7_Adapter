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
  this._metrics.errors_by_class[classified] = (this._metrics.errors_by_class[classified] ?? 0) + 1;
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
}
