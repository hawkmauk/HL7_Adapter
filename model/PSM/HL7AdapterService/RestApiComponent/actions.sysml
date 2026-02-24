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
  const corsHeaders: Record<string, string> = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'GET, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type, Accept',
  };
  const sendJson = (res: import('http').ServerResponse, status: number, data: object) => {
    res.writeHead(status, { ...corsHeaders, 'Content-Type': 'application/json' });
    res.end(JSON.stringify(data));
  };
  const server = http.createServer((req: import('http').IncomingMessage, res: import('http').ServerResponse) => {
    try {
      if (req.method === 'OPTIONS') {
        res.writeHead(204, { ...corsHeaders, 'Content-Length': '0' });
        res.end();
        return;
      }
      const url = req.url ?? '';
      const path = url.split('?')[0];
      if (req.method === 'GET' && path === '/health') {
        const errorHandlerStatus = service.errorHandler.getStatus();
        const status = errorHandlerStatus.status === 'degraded' ? 'degraded' : 'ready';
        const body = {
          status,
          components: {
            errorHandler: errorHandlerStatus,
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
        const errorsStoredTotal = service.operationalStore.getErrorCount();
        const body = {
          errors_stored_total: errorsStoredTotal,
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
      if (req.method === 'GET' && path.startsWith('/messages/')) {
        const id = path.slice('/messages/'.length).split('/')[0];
        if (id) {
          const one = service.operationalStore.getMessageStatus(id);
          if (one) { sendJson(res, 200, one); return; }
          res.writeHead(404, corsHeaders); res.end(); return;
        }
      }
      if (req.method === 'GET' && path === '/messages') {
        const u = new URL(url, 'http://localhost');
        const status = u.searchParams.get('status') ?? undefined;
        const since = u.searchParams.get('since') ?? undefined;
        const list = service.operationalStore.getMessages(status, since);
        sendJson(res, 200, list);
        return;
      }
      if (req.method === 'GET' && path === '/errors') {
        const u = new URL(url, 'http://localhost');
        const since = u.searchParams.get('since') ?? undefined;
        const messageId = u.searchParams.get('message_id') ?? undefined;
        const list = service.operationalStore.getErrorHistory(since, messageId);
        sendJson(res, 200, list);
        return;
      }
      res.writeHead(404, corsHeaders);
      res.end();
    } catch (err) {
      const message = err instanceof Error ? err.message : String(err);
      sendJson(res, 500, { error: message });
    }
  });
  const port = this._config.listenPort ?? 3000;
  const host = (this._config.listenHost && this._config.listenHost.trim()) || '0.0.0.0';
  server.listen(port, host, () => {
    console.log(`REST API listening on ${host}:${port}`);
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
