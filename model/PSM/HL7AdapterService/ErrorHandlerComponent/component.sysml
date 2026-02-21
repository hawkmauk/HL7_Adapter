package PSM_ErrorHandlerComponent {

    alias Actions for PSM_ErrorHandler_Actions;

    private import ScalarValues::*;

    doc /* PSM Error Handler component. Refines PIM::LogicalArchitecture::ErrorHandler. */

    part def <ErrorHandler> 'Error Handler' :> PIM::LogicalArchitecture::ErrorHandler {
        doc /* Refines PIM::LogicalArchitecture::ErrorHandler. Technology binding: Node.js logging (e.g. pino). Error classification taxonomy (enum or policy), structured logger, metrics collector (success/failure/retry counters), dead-letter queue or file. */
        attribute logLevel : String { doc /* Minimum log level (e.g. info, warn, error). */ }
        attribute metricsPrefix : String { doc /* Prefix for exposed metrics (e.g. hl7_adapter). */ }
        attribute deadLetterPath : String { doc /* File path or queue identifier for messages that cannot be delivered after retries. */ }
        attribute classificationTaxonomy : String { doc /* Name or path of the error classification taxonomy (e.g. ParseError, DeliveryError). */ }
        perform action initializeFromBinding : Actions::InitializeErrorHandler;
        perform action handleIntegrationError : Actions::HandleIntegrationError;
        perform action getStatus : Actions::GetStatus;
        rep classMembers language "TypeScript"
        /*
  private _metrics: { errors_total: number; errors_by_class: Partial<Record<ErrorClass, number>> } = { errors_total: 0, errors_by_class: {} };
  private _lastError: string | null = null;
        */
    }
}
