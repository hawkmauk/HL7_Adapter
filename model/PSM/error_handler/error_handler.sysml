package PSM_ErrorHandler {

    private import PIM::*;
    private import PSM::Interfaces::*;
    private import PSM::Actions::*;
    private import ScalarValues::*;
    private import CIM::Datatype::*;

    doc /* PSM Error Handler component. Refines PIM::LogicalArchitecture::ErrorHandler. */

    part def <ErrorHandler> 'Error Handler' :> PIM::LogicalArchitecture::ErrorHandler {
        doc /* Refines PIM::LogicalArchitecture::ErrorHandler. Technology binding: Node.js logging (e.g. pino). Error classification taxonomy (enum or policy), structured logger, metrics collector (success/failure/retry counters), dead-letter queue or file. */
        attribute logLevel : String { doc /* Minimum log level (e.g. info, warn, error). */ }
        attribute metricsPrefix : String { doc /* Prefix for exposed metrics (e.g. hl7_adapter). */ }
        attribute deadLetterPath : String { doc /* File path or queue identifier for messages that cannot be delivered after retries. */ }
        attribute classificationTaxonomy : String { doc /* Name or path of the error classification taxonomy (e.g. ParseError, DeliveryError). */ }
        perform action initializeFromBinding : InitializeErrorHandler;
    }
}
