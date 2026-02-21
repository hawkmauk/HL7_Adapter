package PSM_HTTPForwarder_Actions {

    private import ScalarValues::*;

    alias HttpForwarder for PSM_HTTPForwarderComponent::HTTPForwarder;
    alias HTTPEgressBinding for PSM_HTTPForwarderComponent_Interface::HTTPEgressBinding;

    doc /* HTTP forwarder actions: initialize from binding, send JSON payload with retry and timeout. */

    action def <InitializeHTTPForwarder> 'Initialize HTTP Forwarder' {
        in 'binding' : HTTPEgressBinding;
        in :> self : HttpForwarder;
        doc /* Sets this part's attributes from binding and runtimeConfig for use at construction/bootstrap. Maps baseUrl (from binding.baseUrlPattern or runtimeConfig.baseUrl), requestTimeoutMs, maxRetries, retryBackoffMs, tlsMinVersion, tlsRejectUnauthorized from binding/runtimeConfig. */
    }

    action def <SendJSONPayload> 'Send JSON Payload' :> CIM::Actions::SendJSONPayload {
        in jsonPayload : String;
        out attribute success : Boolean;
        in :> self : HttpForwarder;
        doc /* POST the JSON payload (string) to the configured baseUrl. Uses requestTimeoutMs, maxRetries, retryBackoffMs, tlsRejectUnauthorized. Retries on 502/503/504 and network errors with exponential backoff; no retry on 4xx. On 2xx dispatches HTTP2xxSignal and emits deliverySuccess; on failure dispatches HTTP5xxOrNetworkErrorSignal or ForwarderMaxRetriesExceededSignal and emits deliveryFailed. */

        rep functionBody language "TypeScript"
        /*
  const url = this._config.baseUrl;
  const timeoutMs = this._config.requestTimeoutMs;
  const maxRetries = this._config.maxRetries;
  const backoffMs = this._config.retryBackoffMs;
  let attempt = 0;
  let lastError: Error | undefined;
  while (attempt <= maxRetries) {
    try {
      const controller = new AbortController();
      const timeoutId = setTimeout(() => controller.abort(), timeoutMs);
      const opts: RequestInit = {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: jsonPayload,
        signal: controller.signal,
      };
      const res = await fetch(url, opts);
      clearTimeout(timeoutId);
      if (res.ok) {
        this._dispatch('HTTP2xxSignal');
        this.emit('deliverySuccess', { status: res.status });
        return;
      }
      if (res.status >= 400 && res.status < 500) {
        this._dispatch('HTTP5xxOrNetworkErrorSignal');
        this.emit('deliveryFailed', { status: res.status, message: await res.text() });
        return;
      }
      lastError = new Error(`HTTP ${res.status}`);
      if (attempt === maxRetries) break;
      await new Promise((r) => setTimeout(r, backoffMs * Math.pow(2, attempt)));
      attempt++;
    } catch (err) {
      lastError = err instanceof Error ? err : new Error(String(err));
      if (attempt === maxRetries) break;
      await new Promise((r) => setTimeout(r, backoffMs * Math.pow(2, attempt)));
      attempt++;
    }
  }
  this._dispatch('ForwarderMaxRetriesExceededSignal');
  this.emit('deliveryFailed', { message: lastError?.message ?? 'Max retries exceeded' });
        */
    }
}
