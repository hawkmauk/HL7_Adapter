package PSM_ErrorHandler_Actions {

    alias ErrorHandler for PSM_ErrorHandlerComponent::ErrorHandler;

    doc /* Error handler initialization action. */

    action def <InitializeErrorHandler> 'Initialize Error Handler' {
        in :> self : ErrorHandler;
        doc /* Sets this part's attributes from runtimeConfig for use at construction/bootstrap. Maps logLevel, metricsPrefix, deadLetterPath, classificationTaxonomy from runtimeConfig. */
    }
}
