package PIM_Allocations {
    doc /* Satisfy links from PIM requirements to logical blocks. SYS3.1 satisfy link references 'SYS3.1.TLS Configuration'. PIM sub-requirements refine CIM sub-requirements (#refinement dependency, ModelingMetadata). */

    private import ModelingMetadata::*;
    private import PIM::Requirements::*;
    private import PIM::LogicalArchitecture::*;
    private import CIM::Mission::*;

    part def AllocationScope;

    part allocationScope : AllocationScope {
        part adapter : HL7AdapterService;

        satisfy requirement 'SYS1.Reliable Event Ingestion' by adapter;
        satisfy requirement 'SYS1.1.MLLP Framing Validation' by adapter.mllpReceiver;
        satisfy requirement 'SYS1.2.Connection Lifecycle' by adapter.mllpReceiver;
        satisfy requirement 'SYS1.3.Backpressure Handling' by adapter.mllpReceiver;
        satisfy requirement 'SYS1.4.ACK Generation' by adapter.mllpReceiver;
        satisfy requirement 'SYS1.5.Ingestion Reliability' by adapter.mllpReceiver;

        satisfy requirement 'SYS2.Accurate Clinical Transformation' by adapter.parser;
        satisfy requirement 'SYS2.1.MSH Parsing' by adapter.parser;
        satisfy requirement 'SYS2.2.PID Extraction' by adapter.parser;
        satisfy requirement 'SYS2.3.Segment Iteration' by adapter.parser;
        satisfy requirement 'SYS2.4.Character Encoding Handling' by adapter.parser;
        satisfy requirement 'SYS2.5.Missing-Field Default Policy' by adapter.parser;

        satisfy requirement 'SYS3.Secure Interoperability' by adapter.httpForwarder;
        satisfy requirement 'SYS3.1.TLS Configuration' by adapter.httpForwarder;
        satisfy requirement 'SYS3.2.Endpoint URL Validation' by adapter.httpForwarder;
        satisfy requirement 'SYS3.3.HTTP Method and Headers' by adapter.httpForwarder;
        satisfy requirement 'SYS3.4.Response Code Handling' by adapter.httpForwarder;
        satisfy requirement 'SYS3.5.Retry Policy' by adapter.httpForwarder;
        satisfy requirement 'SYS3.6.Regional Compliance Profile' by adapter;

        satisfy requirement 'SYS4.Operational Transparency' by adapter.errorHandler;
        satisfy requirement 'SYS4.1.Error Classification Taxonomy' by adapter.errorHandler;
        satisfy requirement 'SYS4.2.Structured Log Format' by adapter.errorHandler;
        satisfy requirement 'SYS4.3.Metrics Counters' by adapter.errorHandler;
        satisfy requirement 'SYS4.4.Health-Check Endpoint' by adapter.errorHandler;
        satisfy requirement 'SYS4.5.Alerting Hooks' by adapter.errorHandler;

        satisfy requirement 'SYS5.Operational Data Store' by adapter.operationalStore;
        satisfy requirement 'SYS5.1.Message Lifecycle Persistence' by adapter.operationalStore;
        satisfy requirement 'SYS5.2.Queryable Message Status' by adapter.restApi;
        satisfy requirement 'SYS5.3.Queryable Error History' by adapter.restApi;
    }

    /* PIM sub-requirement refines CIM sub-requirement (refinement = design-level detailing of mission requirement). */

    #refinement dependency 'SYS1.1.MLLP Framing Validation' to 'M1.3.Framing Validation';
    #refinement dependency 'SYS1.2.Connection Lifecycle' to 'M1.2.Connection Handling';
    #refinement dependency 'SYS1.3.Backpressure Handling' to 'M1.4.Backpressure and Flow Control';
    #refinement dependency 'SYS1.4.ACK Generation' to 'M1.5.Acknowledgement Behavior';
    #refinement dependency 'SYS1.5.Ingestion Reliability' to 'M1.1.Ingestion Reliability';

    #refinement dependency 'SYS2.1.MSH Parsing' to 'M2.1.Field Mapping Accuracy';
    #refinement dependency 'SYS2.2.PID Extraction' to 'M2.1.Field Mapping Accuracy';
    #refinement dependency 'SYS2.3.Segment Iteration' to 'M2.2.Segment and Optional Field Handling';
    #refinement dependency 'SYS2.4.Character Encoding Handling' to 'M2.3.Character Encoding and Normalization';
    #refinement dependency 'SYS2.5.Missing-Field Default Policy' to 'M2.4.Missing-Field Policy';

    #refinement dependency 'SYS3.1.TLS Configuration' to 'M3.1.TLS Protection';
    #refinement dependency 'SYS3.2.Endpoint URL Validation' to 'M3.2.Endpoint Authentication';
    #refinement dependency 'SYS3.3.HTTP Method and Headers' to 'M3.2.Endpoint Authentication';
    #refinement dependency 'SYS3.4.Response Code Handling' to 'M3.Secure Interoperability';
    #refinement dependency 'SYS3.5.Retry Policy' to 'M3.Secure Interoperability';
    #refinement dependency 'SYS3.6.Regional Compliance Profile' to 'M3.3.PHI Minimization and Regional Compliance';

    #refinement dependency 'SYS4.1.Error Classification Taxonomy' to 'M4.1.Error Classification';
    #refinement dependency 'SYS4.2.Structured Log Format' to 'M4.2.Structured Logging';
    #refinement dependency 'SYS4.3.Metrics Counters' to 'M4.3.Metrics and Health Signals';
    #refinement dependency 'SYS4.4.Health-Check Endpoint' to 'M4.3.Metrics and Health Signals';
    #refinement dependency 'SYS4.5.Alerting Hooks' to 'M4.4.Alerting Hooks';

    #refinement dependency 'SYS5.Operational Data Store' to 'M3.4.Audit Logging';
    #refinement dependency 'SYS5.1.Message Lifecycle Persistence' to 'M3.4.Audit Logging';
    #refinement dependency 'SYS5.2.Queryable Message Status' to 'M3.4.Audit Logging';
    #refinement dependency 'SYS5.3.Queryable Error History' to 'M4.Operational Transparency';
}
