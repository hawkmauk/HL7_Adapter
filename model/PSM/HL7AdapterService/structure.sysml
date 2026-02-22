package PSM_HL7AdapterService_Structure {

    private import ScalarValues::*;

    doc /* PSM HL7 Adapter Service data types: status, metrics. */

    part def <HL7AdapterServiceStatus> 'HL7 Adapter Service Status' {
        doc /* Current component status (ready | degraded) and optional last error message for health/status endpoints. */
        attribute status : String;
        attribute lastError : String [0..1];
    }
}