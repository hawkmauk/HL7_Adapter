package PSM_RestApiComponent_Interface {

    private import ScalarValues::*;
    private import PIM::Interfaces::*;
    private import CIM::Domain::*;
    private import PIM::Behavior::*;

    part def <RestApiIngressBinding> 'Rest Api Ingress Binding' {
        doc /* Protocol binding for REST API server. Listen host and port for health, metrics, admin. */

        attribute listenHost : String [0..1] = "0.0.0.0" { doc /* Bind address (e.g. 127.0.0.1 or 0.0.0.0). */ }
        attribute listenPort : Integer { doc /* Listen port (e.g. 3000). */ }
    }

    port def <PSM_RestApiIngressPort> 'PSM Rest Api Ingress Port' :> RestApiIngressPort {
        doc /* Adapter receives JSON payload; protocol detail in JSONIngressBinding (HTTPS, POST, application/json, TLS, auth). */
        in item ::> jsonPayload : JSONPayload;
        in attribute ::> payloadReceived : HTTP2xxSignal;
    }
}