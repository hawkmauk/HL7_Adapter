package PSM_HTTPForwarder {

    private import PIM::*;
    private import PSM::Interfaces::*;
    private import PSM::Actions::*;
    private import ScalarValues::*;
    private import CIM::Datatype::*;

    doc /* PSM HTTP Forwarder component. Refines PIM::LogicalArchitecture::HTTPForwarder. */

    part def <HTTPForwarder> 'HTTP Forwarder' :> PIM::LogicalArchitecture::HTTPForwarder {
        doc /* Refines PIM::LogicalArchitecture::HTTPForwarder. Technology binding: axios or undici (TLS, retry, timeout). HTTP client configuration: base URL, TLS settings, retry policy, timeout; request/response handling. */
        attribute baseUrl : String { doc /* Downstream REST API base URL for posting payloads. */ }
        attribute requestTimeoutMs : Integer { doc /* HTTP request timeout in milliseconds. */ }
        attribute maxRetries : Integer { doc /* Maximum retry attempts for transient failures (e.g. 503). */ }
        attribute retryBackoffMs : Integer { doc /* Initial backoff delay in milliseconds before first retry. */ }
        attribute tlsMinVersion : String { doc /* Minimum TLS version (e.g. TLSv1.2). */ }
        attribute tlsRejectUnauthorized : Integer { doc /* When non-zero, reject connections with invalid server certificates. */ }
        perform action initializeFromBinding : InitializeHTTPForwarder;
    }
}
