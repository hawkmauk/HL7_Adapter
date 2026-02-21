package PSM_ErrorHandler_Actions {

    alias ErrorHandler for PSM_ErrorHandler;

    private import PSM::Interfaces::*;

    doc /* Error handler initialization action. */

    action def <InitializeErrorHandler> 'Initialize Error Handler' {
        in runtimeConfig : RuntimeConfigBinding;
        in :> self : ErrorHandler::ErrorHandler;
        doc /* Sets this part's attributes from runtimeConfig for use at construction/bootstrap. Maps logLevel, metricsPrefix, deadLetterPath, classificationTaxonomy from runtimeConfig. */
    }
}
