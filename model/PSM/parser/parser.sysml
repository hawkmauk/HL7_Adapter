package PSM_Parser {

    private import PIM::*;
    private import PSM::Interfaces::*;
    private import PSM::Actions::*;
    private import ScalarValues::*;
    private import CIM::Datatype::*;

    doc /* PSM Parser component. Refines PIM::LogicalArchitecture::Parser. */

    alias Structure for Parser_Structure;

    part def <Parser> 'Parser' :> PIM::LogicalArchitecture::Parser {
        doc /* Refines PIM::LogicalArchitecture::Parser. Technology binding: node-hl7-complete. Implementation uses HL7 segment iterator, field extractor, and validation rules engine; library-specific API in use. */
        attribute encodingFallback : String { doc /* Fallback character encoding when not specified in MSH (e.g. UTF-8). */ }
        attribute strictValidation : Integer { doc /* When non-zero, reject messages that violate structural or required-field rules. */ }
        attribute segmentWhitelist : String { doc /* Comma-separated segment IDs in scope for parsing; others may be ignored. */ }

        perform action parseMessage : ParseHL7Message;
        perform action handleIncomingMessage : HandleIncomingHL7;
        perform action initializeFromBinding : InitializeParser;

    }
}