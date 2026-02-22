package PSM_RestApi_Verification {

    alias RestApi for PSM_RestApiComponent::RestApi;

    private import PIM_Requirements::*;
    private import PSM_HL7AdapterService::*;

    action actCreateAdapterInitializeAndQueryHealthMetricsAndUnknownRoute {
        doc /* Create adapter with RestApi on fixed port, start server, GET /health and /metrics and /unknown. */
        rep functionBody language "vitest"
            /*
const operationalStoreConfig = { ...defaultOperationalStoreConfig, dialect: 'sqlite', path: ':memory:' };
const config = { logging: defaultLoggingConfig, errorHandler: defaultErrorHandlerConfig, httpForwarder: defaultHttpForwarderConfig, mllpReceiver: defaultMllpReceiverConfig, operationalStore: operationalStoreConfig, parser: defaultParserConfig, restApi: { ...defaultRestApiConfig, listenHost: '127.0.0.1', listenPort: 38473 }, transformer: defaultTransformerConfig };
adapter = new Hl7AdapterService(config.logging, config.errorHandler, config.httpForwarder, config.mllpReceiver, config.operationalStore, config.parser, config.restApi, config.transformer);
adapter.initialize(config);
const base = `http://${config.restApi.listenHost}:${config.restApi.listenPort}`;
await new Promise((r) => setTimeout(r, 100));
const healthRes = await fetch(`${base}/health`);
const metricsRes = await fetch(`${base}/metrics`);
expect(healthRes.status).toBe(200);
const health = await healthRes.json();
expect(health).toHaveProperty('status');
expect(['ready', 'degraded']).toContain(health.status);
expect(health).toHaveProperty('components');
expect(health.components).toHaveProperty('errorHandler');
expect(health.components).toHaveProperty('restApi');
expect(metricsRes.status).toBe(200);
const metrics = await metricsRes.json();
expect(metrics).toHaveProperty('components');
expect(metrics.components).toHaveProperty('errorHandler');
const eh = metrics.components.errorHandler;
expect(eh).toHaveProperty('errors_total');
expect(eh).toHaveProperty('messages_received');
expect(eh).toHaveProperty('messages_delivered');
const notFoundRes = await fetch(`${base}/unknown`);
expect(notFoundRes.status).toBe(404);
            */
    }
    
    action assertHealth200MetricsShapeAndNotFound404 {
        doc /* Assertions inlined in act step: health 200 and shape, metrics 200 and counters, unknown route 404. */
    }

    verification def RestApiHealthMetricsTest {
        doc /* Create adapter, start server, GET /health, /metrics, /unknown; assert response shapes and 404. */
        subject adapter : HL7AdapterService;
        objective { verify SYS4_4; }

        action actCreateAdapterInitializeAndQueryHealthMetricsAndUnknownRoute {
            doc /* Create adapter with RestApi on fixed port, start server, GET /health and /metrics and /unknown. */
            rep functionBody language "vitest"
            /*
const operationalStoreConfig = { ...defaultOperationalStoreConfig, dialect: 'sqlite', path: ':memory:' };
const config = { logging: defaultLoggingConfig, errorHandler: defaultErrorHandlerConfig, httpForwarder: defaultHttpForwarderConfig, mllpReceiver: defaultMllpReceiverConfig, operationalStore: operationalStoreConfig, parser: defaultParserConfig, restApi: { ...defaultRestApiConfig, listenHost: '127.0.0.1', listenPort: 38473 }, transformer: defaultTransformerConfig };
adapter = new Hl7AdapterService(config.logging, config.errorHandler, config.httpForwarder, config.mllpReceiver, config.operationalStore, config.parser, config.restApi, config.transformer);
adapter.initialize(config);
const base = `http://${config.restApi.listenHost}:${config.restApi.listenPort}`;
await new Promise((r) => setTimeout(r, 100));
const healthRes = await fetch(`${base}/health`);
const metricsRes = await fetch(`${base}/metrics`);
expect(healthRes.status).toBe(200);
const health = await healthRes.json();
expect(health).toHaveProperty('status');
expect(['ready', 'degraded']).toContain(health.status);
expect(health).toHaveProperty('components');
expect(health.components).toHaveProperty('errorHandler');
expect(health.components).toHaveProperty('restApi');
expect(metricsRes.status).toBe(200);
const metrics = await metricsRes.json();
expect(metrics).toHaveProperty('components');
expect(metrics.components).toHaveProperty('errorHandler');
const eh = metrics.components.errorHandler;
expect(eh).toHaveProperty('errors_total');
expect(eh).toHaveProperty('messages_received');
expect(eh).toHaveProperty('messages_delivered');
const notFoundRes = await fetch(`${base}/unknown`);
expect(notFoundRes.status).toBe(404);
            */
        }
    }
}