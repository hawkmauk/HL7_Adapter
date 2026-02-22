package PSM_RestApi_Actions {

    alias RestApi for PSM_RestApiComponent::RestApi;
    alias HL7AdapterService for PSM_HL7AdapterService::HL7AdapterService;
    alias RestApiIngressBinding for PSM_RestApiComponent_Interface::RestApiIngressBinding;

    private import ScalarValues::*;
    private import PSM_HL7AdapterService_Structure::*;
    doc /* Rest API server actions: start HTTP server and register route handlers. */

    action def <InitializeRestApi> 'Initialize Rest Api' {
        in service : HL7AdapterService;
        in :> self : RestApi;
        doc /* Creates HTTP server, registers GET /health (aggregate + per-component status), GET /metrics (message-flow and error counters for dashboard), listens on this._config.listenPort. See dashboard data contract in RestApiComponent doc. */
        rep functionBody language "TypeScript"
        /*
  const http = require('http') as typeof import('http');
  const sendJson = (res: import('http').ServerResponse, status: number, data: object) => {
    res.writeHead(status, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify(data));
  };
  const server = http.createServer((req: import('http').IncomingMessage, res: import('http').ServerResponse) => {
    try {
      const url = req.url ?? '';
      const path = url.split('?')[0];
      if (req.method === 'GET' && path === '/health') {
        const body = {
          components: {
            errorHandler: service.errorHandler.getStatus(),
            mllpReceiver: service.mllpReceiver.getStatus(),
            parser: service.parser.getStatus(),
            transformer: service.transformer.getStatus(),
            httpForwarder: service.httpForwarder.getStatus(),
            restApi: service.restApi.getStatus(),
          },
        };
        sendJson(res, 200, body);
        return;
      }
      if (req.method === 'GET' && path === '/metrics') {
        const errorHandlerMetrics = service.errorHandler.getMetrics();
        const body = {
          components: {
            errorHandler: {
              errors_total: errorHandlerMetrics.errors_total,
              errors_parse_error: errorHandlerMetrics.errors_parse_error,
              errors_validation_error: errorHandlerMetrics.errors_validation_error,
              errors_connection_error: errorHandlerMetrics.errors_connection_error,
              errors_timeout_error: errorHandlerMetrics.errors_timeout_error,
              errors_http_client_error: errorHandlerMetrics.errors_http_client_error,
              errors_http_server_error: errorHandlerMetrics.errors_http_server_error,
              messages_received: errorHandlerMetrics.messages_received,
              messages_parsed: errorHandlerMetrics.messages_parsed,
              messages_transformed: errorHandlerMetrics.messages_transformed,
              messages_delivered: errorHandlerMetrics.messages_delivered,
            },
          },
        };
        sendJson(res, 200, body);
        return;
      }
      res.writeHead(404);
      res.end();
    } catch (err) {
      const message = err instanceof Error ? err.message : String(err);
      sendJson(res, 500, { error: message });
    }
  });
  const port = this._config.listenPort ?? 3000;
  server.listen(port, () => {
    console.log(`REST API listening on port ${port}`);
  });
  this._dispatch('StartServerSignal');
        */
    }

    action def <GetRestApiStatus> 'Get Rest Api Status' {
        in :> self : RestApi;
        out result : HL7AdapterServiceStatus;
        doc /* Return current component state for health/status endpoints. */
        rep functionBody language "TypeScript"
        /*
  result = { status: this.state };
        */
    }
}
