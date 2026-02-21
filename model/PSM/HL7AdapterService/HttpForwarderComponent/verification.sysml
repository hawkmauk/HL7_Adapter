package PSM_HTTPForwarder_Verification {

    alias HTTPForwarder for PSM_HTTPForwarder::HTTPForwarder;
    
    private import PIM_Requirements::*;
    private import PSM_HL7Adapter::*;

    doc /* Verification cases for HTTP Forwarder component; cover SYS3.1–SYS3.5. */

    verification def TLSConfigurationTest {
        doc /* Verifies SYS3.1: Modern TLS versions and cipher configuration for outbound HTTPS. */
        subject forwarder : HTTPForwarder;
        objective { verify SYS3_1; }

        action collectData {
            doc /* Set up test server with TLS. */
        }
        action processData {
            doc /* Post payload via forwarder. */
        }
        action evaluateData {
            doc /* Assert TLS negotiation and cipher use. */
        }
    }

    verification def EndpointValidationTest {
        doc /* Verifies SYS3.2: Endpoint URL validation and server cert / mutual TLS; fail closed when identity cannot be established. */
        subject forwarder : HTTPForwarder;
        objective { verify SYS3_2; }

        action collectData {
            doc /* Use valid and invalid endpoint identities. */
        }
        action processData {
            doc /* Attempt connection. */
        }
        action evaluateData {
            doc /* Assert fail closed on invalid identity. */
        }
    }

    verification def HTTPMethodAndHeadersTest {
        doc /* Verifies SYS3.3: Specified HTTP method and headers (POST, Content-Type, auth) for posting payloads. */
        subject forwarder : HTTPForwarder;
        objective { verify SYS3_3; }

        action collectData {
            doc /* Configure method and headers. */
        }
        action processData {
            doc /* Send request. */
        }
        action evaluateData {
            doc /* Assert request matches specification. */
        }
    }

    verification def ResponseCodeHandlingTest {
        doc /* Verifies SYS3.4: HTTP response codes (2xx success, 4xx/5xx) mapped to delivery success or failure. */
        subject forwarder : HTTPForwarder;
        objective { verify SYS3_4; }

        action collectData {
            doc /* Stub server returning 2xx, 4xx, 5xx. */
        }
        action processData {
            doc /* Post and capture outcome. */
        }
        action evaluateData {
            doc /* Assert correct success/failure signals. */
        }
    }

    verification def RetryPolicyTest {
        doc /* Verifies SYS3.5: Configurable retry policy for transient failures with bounded attempts. */
        subject forwarder : HTTPForwarder;
        objective { verify SYS3_5; }

        action collectData {
            doc /* Stub server returning 503 then 200. */
        }
        action processData {
            doc /* Post and trigger retries. */
        }
        action evaluateData {
            doc /* Assert retries bounded and eventual success/failure. */
        }
    }
}
