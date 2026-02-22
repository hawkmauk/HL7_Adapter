package PSM_RestApi_Actions {

    alias RestApi for PSM_RestApiComponent::RestApi;
    alias HL7AdapterService for PSM_HL7AdapterService::HL7AdapterService;
    alias RestApiIngressBinding for PSM_RestApiComponent_Interface::RestApiIngressBinding;

    private import ScalarValues::*;

    doc /* Rest API server actions: start HTTP server and register route handlers. */

    action def <InitializeRestApi> 'Initialize Rest Api' {
        in 'binding' : RestApiIngressBinding;
        in service : HL7AdapterService;
        in :> self : RestApi;
        doc /* Creates HTTP server, registers GET /health (service.errorHandler.getStatus()), listens on this._config.listenPort. */
        rep functionBody language "TypeScript"
        /*
  const http = require('http') as typeof import('http');
  const server = http.createServer((req: import('http').IncomingMessage, res: import('http').ServerResponse) => {
    if (req.method === 'GET' && req.url === '/health') {
      const errorHandlerStatus = service.errorHandler.getStatus();
      const body = JSON.stringify({
        status: errorHandlerStatus.status,
        components: { errorHandler: errorHandlerStatus },
      });
      res.writeHead(200, { 'Content-Type': 'application/json' });
      res.end(body);
      return;
    }
    res.writeHead(404);
    res.end();
  });
  const port = this._config.listenPort ?? 3000;
  server.listen(port, () => {
    console.log(`REST API listening on port ${port}`);
  });
  this._dispatch('StartServerSignal');
        */
    }
}
