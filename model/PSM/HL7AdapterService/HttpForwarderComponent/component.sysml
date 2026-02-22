package PSM_HTTPForwarderComponent {

    alias Action for PSM_HTTPForwarder_Actions;
    alias Interface for PSM_HTTPForwarderComponent_Interface;
    alias InitializeHTTPForwarder for PSM_HTTPForwarder_Actions::InitializeHTTPForwarder;
    alias SendJSONPayload for PSM_HTTPForwarder_Actions::SendJSONPayload;
    alias Logger for PSM_Logging_Structure::Logger;

    private import Action::*;
    private import ScalarValues::*;

    doc /* PSM HTTP Forwarder component. Refines PIM::LogicalArchitecture::HTTPForwarder. */

    part def <HTTPForwarder> 'HTTP Forwarder' :> PIM::LogicalArchitecture::HTTPForwarder {
        doc /* Refines PIM::LogicalArchitecture::HTTPForwarder. Technology binding: axios or undici (TLS, retry, timeout). HTTP client configuration: base URL, TLS settings, retry policy, timeout; request/response handling. */
        attribute baseUrl : String { doc /* Downstream REST API base URL for posting payloads. */ }
        attribute requestTimeoutMs : Integer { doc /* HTTP request timeout in milliseconds. */ }
        attribute maxRetries : Integer { doc /* Maximum retry attempts for transient failures (e.g. 503). */ }
        attribute retryBackoffMs : Integer { doc /* Initial backoff delay in milliseconds before first retry. */ }
        attribute tlsMinVersion : String { doc /* Minimum TLS version (e.g. TLSv1.2). */ }
        attribute tlsRejectUnauthorized : Integer { doc /* When non-zero, reject connections with invalid server certificates. */ }
        attribute logger : Logger [0..1] { doc /* Supplied by adapter from shared logging facility. */ }

        perform action sendJSONPayload : PSM_HTTPForwarder_Actions::SendJSONPayload;
        perform action initializeFromBinding : InitializeHTTPForwarder;
        perform action getStatus : PSM_HTTPForwarder_Actions::GetHTTPForwarderStatus;

        rep textualRepresentation language "TypeScript"
        /*
import https from 'https';
import { URL } from 'url';
        */
    }
}
