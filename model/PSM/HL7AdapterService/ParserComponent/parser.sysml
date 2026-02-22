package PSM_ParserComponent {

    private import ScalarValues::*;

    alias Structure for PSM_Parser_Structure;
    alias Actions for PSM_Parser_Actions;

    private import Actions::*;

    doc /* PSM Parser component. Refines PIM::LogicalArchitecture::Parser. */

    part def <Parser> 'Parser' :> PIM::LogicalArchitecture::Parser {
        doc /* Refines PIM::LogicalArchitecture::Parser. Technology binding: node-hl7-complete. Implementation uses HL7 segment iterator, field extractor, and validation rules engine; library-specific API in use. */
        attribute encodingFallback : String { doc /* Fallback character encoding when not specified in MSH (e.g. UTF-8). */ }
        attribute strictValidation : Integer { doc /* When non-zero, reject messages that violate structural or required-field rules. */ }
        attribute segmentWhitelist : String { doc /* Comma-separated segment IDs in scope for parsing; others may be ignored. */ }

        perform action parseMessage : ParseHL7Message;
        perform action handleIncomingMessage : HandleIncomingHL7;
        perform action initializeFromBinding : InitializeParser;
        perform action getStatus : Actions::GetParserStatus;

    }
}