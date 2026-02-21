package PSM_HTTPForwarder_Actions {

    alias HttpForwarder for PSM_HTTPForwarderComponent::HTTPForwarder;
    alias HTTPEgressBinding for PSM_HTTPForwarderComponent_Interface::HTTPEgressBinding;

    doc /* HTTP forwarder initialization action. */

    action def <InitializeHTTPForwarder> 'Initialize HTTP Forwarder' {
        in 'binding' : HTTPEgressBinding;
        in :> self : HttpForwarder;
        doc /* Sets this part's attributes from binding and runtimeConfig for use at construction/bootstrap. Maps baseUrl (from binding.baseUrlPattern or runtimeConfig.baseUrl), requestTimeoutMs, maxRetries, retryBackoffMs, tlsMinVersion, tlsRejectUnauthorized from binding/runtimeConfig. */
    }
}
