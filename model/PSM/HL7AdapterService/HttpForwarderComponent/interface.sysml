package PSM_HTTPForwarderComponent_Interface {

    /* =======================================================================
     * HTTP Egress Binding
     * HTTPS URL pattern, method POST, Content-Type application/json, TLS, auth.
     * Technology: axios/undici. Refs: SYS3.1–SYS3.5.
     * ======================================================================= */

    private import ScalarValues::*;
    private import PIM::Interfaces::*;
    private import CIM::Domain::*;
    private import PIM::Behavior::*;

    part def <HTTPEgressBinding> 'JSON Egress Binding' {
        doc /* Protocol binding for HTTP egress to downstream API. HTTPS, POST, application/json; TLS and optional API key or OAuth. */

        attribute baseUrlPattern : String { doc /* Downstream REST base URL (e.g. https://api.example.com/v1). */ }
        attribute httpMethod : String = "POST" { doc /* HTTP method for posting payloads. */ }
        attribute contentType : String = "application/json" { doc /* Content-Type header value. */ }

        attribute tlsMinVersion : String = "TLSv1.2" { doc /* Minimum TLS version. */ }
        attribute tlsRejectUnauthorized : Integer = 1 { doc /* 1 = reject invalid server certificates. */ }

        attribute authenticationKind : String = "none" { doc /* none | apiKey | oauth2. */ }
        attribute apiKeyHeaderName : String { doc /* Header name for API key (e.g. X-API-Key). */ }
        attribute oauthTokenEndpoint : String { doc /* OAuth2 token endpoint URL when authenticationKind = oauth2. */ }

        attribute requestTimeoutMs : Integer = 30000 { doc /* HTTP request timeout (ms). */ }
        attribute maxRetries : Integer = 3 { doc /* Max retry attempts for transient failures. */ }
        attribute retryBackoffMs : Integer = 1000 { doc /* Initial backoff before first retry (ms). */ }
    }

    port def <PSM_JSONEgressPort> 'PSM JSON Egress Port' :> JSONEgressPort {
        doc /* Adapter sends JSON to downstream; protocol detail in HTTPEgressBinding (HTTPS, POST, application/json, TLS, auth). */
        out item ::> jsonPayload : JSONPayload;
        out attribute ::> payloadSent : SendJSONRequestedSignal;
        out attribute ::> deliverySuccess : HTTP2xxSignal;
        out attribute ::> deliveryFailure : HTTP5xxOrNetworkErrorSignal;
    }
}