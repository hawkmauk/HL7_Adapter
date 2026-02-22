package PSM_RestApiComponent_Interface {

    private import ScalarValues::*;
    private import PIM::Interfaces::*;
    private import CIM::Domain::*;
    private import PIM::Behavior::*;

    part def <RestApiIngressBinding> 'Rest Api Ingress Binding' {
        doc /* Protocol binding for REST API server. Listen port for health, metrics, admin. */

        attribute listenPort : Integer { doc /* Listen port (e.g. 3000). */ }
    }

    port def <PSM_RestApiIngressPort> 'PSM Rest Api Ingress Port' :> RestApiIngressPort {
        doc /* Adapter receives JSON payload; protocol detail in JSONIngressBinding (HTTPS, POST, application/json, TLS, auth). */
        in item ::> jsonPayload : JSONPayload;
        in attribute ::> payloadReceived : HTTP2xxSignal;
    }
}