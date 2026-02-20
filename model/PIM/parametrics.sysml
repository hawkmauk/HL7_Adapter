package PIM_Parametrics {
    doc /* Parametric constraint blocks for PIM performance validation. Binds throughput, latency, and reliability parameters to MoEs from CIM (Issue 3) and PIM requirements (Issue 8). */

    private import ScalarValues::*;
    private import NumericalFunctions::*;

    /* -----------------------------------------------------------------------
     * ThroughputConstraint: message arrival rate, processing capacity, queue
     * depth vs end-to-end throughput MoE (M1_MoE1: 99.9% ingestion success).
     * ----------------------------------------------------------------------- */

    constraint def <ThroughputConstraint> 'Throughput Constraint' {
        doc /* Relates arrival rate, service rate, and queue depth to throughput MoE. Supports CIM M1_MoE1 (99.9% ingestion success). Relevant PIM: SYS1.5 Ingestion Reliability. */
        in arrivalRate : Real;
        in serviceRate : Real;
        in queueDepth : Integer;
        in minThroughputMoE : Real;

        arrivalRate <= serviceRate and
        minThroughputMoE <= 1.0
    }

    /* -----------------------------------------------------------------------
     * LatencyConstraint: sum of per-component latencies (receive, parse,
     * transform, post) below threshold. Trace to M1_6, M2_5, SYS2.5, SYS4.3.
     * ----------------------------------------------------------------------- */

    constraint def <LatencyConstraint> 'Latency Constraint' {
        doc /* Sum of receive + parse + transform + post latencies (e.g. ms) must not exceed threshold. Supports CIM M1_6, M2_5. Relevant PIM: SYS2.5, SYS4.3. */
        in receiveLatency : Real;
        in parseLatency : Real;
        in transformLatency : Real;
        in postLatency : Real;
        in latencyThreshold : Real;

        receiveLatency + parseLatency + transformLatency + postLatency <= latencyThreshold
    }

    /* -----------------------------------------------------------------------
     * ReliabilityConstraint: retry count, failure rate, availability/observability
     * target. Trace to M1_MoE1, M4_MoE1, SYS3.5, SYS4.
     * ----------------------------------------------------------------------- */

    constraint def <ReliabilityConstraint> 'Reliability Constraint' {
        doc /* Relates retry count and failure rate to availability/observability target. Supports CIM M1_MoE1, M4_MoE1 (99% error observability). Relevant PIM: SYS3.5 Retry Policy, SYS4. */
        in retryCount : Integer;
        in failureRate : Real;
        in availabilityTarget : Real;

        failureRate <= (1.0 - availabilityTarget)
    }

    /* -----------------------------------------------------------------------
     * Analysis context: holds performance parameters and binds constraints
     * to MoE values (literals) and analysis attributes.
     * ----------------------------------------------------------------------- */

    part def <PerformanceAnalysisContext> 'Performance Analysis Context' {
        doc /* Analysis context for parametric validation. Attributes represent system-level performance parameters; bind to PIM component attributes when available (Issue 8). */

        attribute arrivalRate : Real;
        attribute serviceRate : Real;
        attribute queueDepth : Integer;
        attribute minThroughputMoE : Real = 0.999;

        attribute receiveLatency : Real;
        attribute parseLatency : Real;
        attribute transformLatency : Real;
        attribute postLatency : Real;
        attribute latencyThreshold : Real;

        attribute retryCount : Integer;
        attribute failureRate : Real;
        attribute availabilityTarget : Real = 0.99;

        constraint throughputConstraint : ThroughputConstraint {
            in arrivalRate = arrivalRate;
            in serviceRate = serviceRate;
            in queueDepth = queueDepth;
            in minThroughputMoE = minThroughputMoE;
        }

        constraint latencyConstraint : LatencyConstraint {
            in receiveLatency = receiveLatency;
            in parseLatency = parseLatency;
            in transformLatency = transformLatency;
            in postLatency = postLatency;
            in latencyThreshold = latencyThreshold;
        }

        constraint reliabilityConstraint : ReliabilityConstraint {
            in retryCount = retryCount;
            in failureRate = failureRate;
            in availabilityTarget = availabilityTarget;
        }
    }
}
