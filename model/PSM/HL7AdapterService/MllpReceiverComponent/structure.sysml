package PSM_MLLPReceiver_Structure {

    private import ScalarValues::*;
    private import CIM::Datatype::*;

    doc /* MLLP-specific data types (parse result, etc.). */

    part def <ParseMllpResult> 'Parse MLLP Result' {
        doc /* Result of parsing one MLLP frame from a buffer. */
        attribute payload[*] : Buffer;
        attribute success : Boolean;
        attribute error[*] : String;
        attribute consumed : Integer;
    }
}
