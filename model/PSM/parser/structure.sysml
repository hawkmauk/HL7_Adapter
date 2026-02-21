package Parser_Structure {

    private import ScalarValues::*;

    doc /* PSM data types for the Parser and Transformer: TypeScript interfaces for MSH/PID, parsed result, and parse error. Emitted by the TypeScript generator as the parser module preamble. */

    part def <MSHFields> 'MSH Fields' {
        doc /* HL7 MSH segment fields (MSH-2 through MSH-12). */
        attribute fieldDelimiter : String;
        attribute sendingApplication : String;
        attribute sendingFacility : String;
        attribute receivingApplication : String;
        attribute receivingFacility : String;
        attribute messageType : String;
        attribute messageControlId : String;
        attribute processingId : String;
        attribute versionId : String;
    }

    part def <PIDFields> 'PID Fields' {
        doc /* HL7 PID segment fields (patient demographics). All optional. */
        attribute patientIdList : String [0..1];
        attribute patientName : String [0..1];
        attribute dateOfBirth : String [0..1];
        attribute sex : String [0..1];
        attribute patientAddress : String [0..1];
    }

    part def <ParseError> 'Parse Error' {
        doc /* Error from parse failure (message and optional segment). */
        attribute 'message' : String;
        attribute segment : String [0..1];
    }

    part def <SegmentMap> 'Segment Map' {
        doc /* Map segment id to array of segment lines. */
        rep textualRepresentation language "TypeScript"
        /*
Record<string, string[]>
        */
    }

    part def <ParsedHL7> 'Parsed HL7' {
        doc /* Result of parsing: MSH, optional PID, and segment map. */
        attribute msh : MSHFields;
        attribute pid : PIDFields [0..1];
        attribute segments : SegmentMap;
    }

    part def <ParseSuccess> 'Parse Success' {
        doc /* Successful parse result (discriminated union member). */
        attribute data : ParsedHL7;
        rep textualRepresentation language "TypeScript"
        /*
  success: true;
  data: ParsedHL7;
        */
    }

    part def <ParseFailure> 'Parse Failure' {
        doc /* Failed parse result (discriminated union member). */
        attribute error : ParseError;
        rep textualRepresentation language "TypeScript"
        /*
  success: false;
  error: ParseError;
        */
    }

    part def <ParseResult> 'Parse Result' :> ParseSuccess, ParseFailure {
        doc /* Discriminated union: success with data or failure with error. Emitted as type alias. */
    }

    part def <MappingConfigEntry> 'Mapping Config Entry' {
        doc /* Single HL7 path to JSON path mapping. */
        attribute hl7Path : String;
        attribute jsonPath : String;
    }

    part def <MappingConfig> 'Mapping Config' {
        doc /* Array of field mapping entries. */
        rep textualRepresentation language "TypeScript"
        /*
MappingConfigEntry[]
        */
    }

    part def <TransformOutput> 'Transform Output' {
        doc /* JSON shape produced by the transformer (mapped fields plus index signature). */
        rep textualRepresentation language "TypeScript"
        /*
  messageType?: string;
  messageControlId?: string;
  patientId?: string;
  patientName?: string;
  dateOfBirth?: string;
  [key: string]: unknown;
        */
    }
}
