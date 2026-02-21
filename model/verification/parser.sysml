package VER_Parser {
    private import PIM_Requirements::*;
    private import PSM_PhysicalArchitecture::*;

    doc /* Verification cases for Parser component; cover SYS2.1–SYS2.5. */

    verification def MSHParsingTest {
        doc /* Verifies SYS2.1: MSH segment parsing and required header fields to internal metadata. */
        subject parser : Parser;
        objective { verify SYS2_1; }

        action collectData {
            doc /* Provide HL7 messages with valid and invalid MSH. */
        }
        action processData {
            doc /* Invoke parser on messages. */
        }
        action evaluateData {
            doc /* Assert MSH fields mapped correctly to metadata. */
        }
    }

    verification def PIDExtractionTest {
        doc /* Verifies SYS2.2: PID and required patient identifiers extracted deterministically. */
        subject parser : Parser;
        objective { verify SYS2_2; }

        action collectData {
            doc /* Provide messages with PID segments. */
        }
        action processData {
            doc /* Parse and extract demographics. */
        }
        action evaluateData {
            doc /* Assert PID data extracted for JSON mapping. */
        }
    }

    verification def SegmentIterationTest {
        doc /* Verifies SYS2.3: Optional and repeated segments handled deterministically; in-scope segments specified. */
        subject parser : Parser;
        objective { verify SYS2_3; }

        action collectData {
            doc /* Provide messages with optional and repeated segments. */
        }
        action processData {
            doc /* Parse and iterate segments. */
        }
        action evaluateData {
            doc /* Assert deterministic handling and segment scope. */
        }
    }

    verification def CharacterEncodingTest {
        doc /* Verifies SYS2.4: Character encodings normalized to canonical JSON (e.g. UTF-8) without corruption. */
        subject parser : Parser;
        objective { verify SYS2_4; }

        action collectData {
            doc /* Provide messages with different encodings. */
        }
        action processData {
            doc /* Parse with encoding fallback. */
        }
        action evaluateData {
            doc /* Assert correct UTF-8 output and no corruption. */
        }
    }

    verification def MissingFieldPolicyTest {
        doc /* Verifies SYS2.5: Consistent policy for missing or malformed required fields (null, defaults, or reject). */
        subject parser : Parser;
        objective { verify SYS2_5; }

        action collectData {
            doc /* Provide messages with missing or malformed required fields. */
        }
        action processData {
            doc /* Parse and apply policy. */
        }
        action evaluateData {
            doc /* Assert policy applied and surfaced to operators. */
        }
    }
}
