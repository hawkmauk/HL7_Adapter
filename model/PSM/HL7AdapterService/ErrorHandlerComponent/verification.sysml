package PSM_ErrorHandler_Verification {

    alias ErrorHandler for PSM_ErrorHandler::ErrorHandler;

    private import PIM_Requirements::*;

    doc /* Verification cases for Error Handler component; cover SYS4.1–SYS4.5. */

    verification def ErrorClassificationTest {
        doc /* Verifies SYS4.1: Integration errors classified into parse, delivery, configuration, data-quality. */
        subject errorHandler : ErrorHandler;
        objective { verify SYS4_1; }

        action collectData {
            doc /* Create errors of each category. */
        }
        action processData {
            doc /* Pass errors to handler. */
        }
        action evaluateData {
            doc /* Assert classification matches taxonomy. */
        }
    }

    verification def StructuredLogFormatTest {
        doc /* Verifies SYS4.2: Structured logs with stable field names (correlation IDs, message IDs, error codes). */
        subject errorHandler : ErrorHandler;
        objective { verify SYS4_2; }

        action collectData {
            doc /* Trigger error handling paths. */
        }
        action processData {
            doc /* Emit logs. */
        }
        action evaluateData {
            doc /* Assert log structure and required fields. */
        }
    }

    verification def MetricsCountersTest {
        doc /* Verifies SYS4.3: Metrics (success/failure/retry counts, throughput, latency) exposed for monitoring. */
        subject errorHandler : ErrorHandler;
        objective { verify SYS4_3; }

        action collectData {
            doc /* Generate success and failure events. */
        }
        action processData {
            doc /* Record metrics. */
        }
        action evaluateData {
            doc /* Assert counters and values. */
        }
    }

    verification def HealthCheckEndpointTest {
        doc /* Verifies SYS4.4: Health-check endpoint or signal indicating operational readiness. */
        subject errorHandler : ErrorHandler;
        objective { verify SYS4_4; }

        action collectData {
            doc /* Configure health-check. */
        }
        action processData {
            doc /* Query health endpoint. */
        }
        action evaluateData {
            doc /* Assert readiness signal. */
        }
    }

    verification def AlertingHooksTest {
        doc /* Verifies SYS4.5: Integration with alerting workflows (thresholds on error rates, latency, connectivity). */
        subject errorHandler : ErrorHandler;
        objective { verify SYS4_5; }

        action collectData {
            doc /* Set thresholds and trigger conditions. */
        }
        action processData {
            doc /* Exercise alerting hooks. */
        }
        action evaluateData {
            doc /* Assert hooks invoked as specified. */
        }
    }
}
