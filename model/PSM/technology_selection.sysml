/* Trade study recording follows Option C (parametric analysis block) per docs/PSM_TradeStudy_Guidance.md.
   Alternatives are part defs with MOE value properties; objective function is a constraint def; analysis context binds alternatives and scores. */

package PSM_TechnologySelection {
    doc /* Technology trade studies for the HL7 Adapter PSM. Each study uses a parametric pattern: alternative part defs with MOE attributes, a weighted objective constraint, and an analysis context that binds alternatives and documents selection. Criteria derived from PIM requirements (SYS1–SYS4) and Lyrebird target environment. */

    private import ScalarValues::*;
    private import NumericalFunctions::*;
    private import SequenceFunctions::*;

    /* -----------------------------------------------------------------------
     * Criterion and AssessmentCriteria for criteria-based trade studies.
     * ----------------------------------------------------------------------- */
        part def <Criterion> 'Criterion' {
            doc /* Criterion for assessing language runtime alternatives. */
            attribute name : String;
            attribute value : Real;
            attribute weight : Real;

            attribute weightedValue : Real = weight * value;
        }

        part def <AssessmentCriteria> 'Assessment Criteria' {
            doc /* Criteria for assessing language runtime alternatives. */
            part criterion[1..*] : Criterion;

            attribute criteria : Natural := size(criterion);
            attribute score : Real := sum( criterion.weightedValue );
        }


        constraint def <ScoreEqualsCriteriaSum> 'Score Equals Criteria Sum' {
            doc /* Asserts score equals the weighted sum over criteria.criterion (value * weight). */
            in score : Real;
            in criteria : AssessmentCriteria;

            criteria.score <= score and score <= criteria.score
        }

        part def <Alternative> 'Alternative' {
            doc /* One candidate alternative. Holds assessment criteria (value per criterion set per instance). */
            attribute name : String;
            part criteria : AssessmentCriteria;
        }

    package LanguageRuntimeTradeStudy {
        doc /* Trade study: language and runtime. Criteria: HL7 ecosystem; async I/O; Lyrebird alignment. */

        part def <RuntimeAssessmentCriteria> 'Runtime Assessment Criteria' :> AssessmentCriteria {
            doc /* Criteria for language runtime alternatives. Three MOEs: HL7 ecosystem; async I/O; Lyrebird alignment. Score = sum(criterion.value * criterion.weight). */
            part ::> criterion[0] : Criterion {
                attribute ::> name = "HL7 Ecosystem";
                attribute ::> weight = 0.33;
            }
            part ::> criterion[1] : Criterion {
                attribute ::> name = "Async I/O Fit";
                attribute ::> weight = 0.33;
            }
            part ::> criterion[2] : Criterion {
                attribute ::> name = "Lyrebird Alignment";
                attribute ::> weight = 0.34;
            }
        }

        part def <LanguageRuntimeAlternative> 'Language Runtime Alternative' :> Alternative {
            doc /* One candidate runtime. Holds assessment criteria (value per criterion set per instance). */
            part ::> criteria : RuntimeAssessmentCriteria;
        }

        part <NodeJsRuntime> 'Node.js Runtime' : LanguageRuntimeAlternative {
            doc /* Node.js runtime alternative. Selection winner: strong HL7 ecosystem, async I/O, Lyrebird alignment. */
            attribute ::> name = "Node.js";
            part ::> criteria {
                part ::> criterion[0] { attribute ::> value = 0.9; }
                part ::> criterion[1] { attribute ::> value = 0.95; }
                part ::> criterion[2] { attribute ::> value = 0.95; }
            }
        }

        part <GoRuntime> 'Go Runtime' : LanguageRuntimeAlternative {
            doc /* Go runtime alternative. */
            attribute ::> name = "Go";
            part ::> criteria {
                part ::> criterion[0] { attribute ::> value = 0.8; }
                part ::> criterion[1] { attribute ::> value = 0.9; }
                part ::> criterion[2] { attribute ::> value = 0.6; }
            }
        }

        part <PythonRuntime> 'Python Runtime' : LanguageRuntimeAlternative {
            doc /* Python runtime alternative. */
            attribute ::> name = "Python";
            part ::> criteria {
                part ::> criterion[0] { attribute ::> value = 0.85; }
                part ::> criterion[1] { attribute ::> value = 0.9; }
                part ::> criterion[2] { attribute ::> value = 0.5; }
            }
        }

        part def <ScoredLanguageRuntimeAlternative> 'Scored Language Runtime Alternative' {
            doc /* One alternative plus its weighted score. Score is constrained to equal alt.criteria.score (sum of criterion.value * criterion.weight). */
            part alt : LanguageRuntimeAlternative;
            attribute score : Real;
            constraint weightedScore : ScoreEqualsCriteriaSum {
                in score = score;
                in criteria = alt.criteria;
            }
        }

        part def <LanguageRuntimeTradeStudyContext> 'Language Runtime Trade Study Context' {
            doc /* Analysis context. Alternatives: Node.js/TypeScript, Python, Go. Selection: Node.js/TypeScript (max score). Rationale: aligns with Lyrebird backend and UK forward-deployment; satisfies PIM; strong npm ecosystem; TypeScript maintainability. Set same w1,w2,w3 on nodeScored, pythonScored, goScored. */
            part nodeScored : ScoredLanguageRuntimeAlternative;
            part pythonScored : ScoredLanguageRuntimeAlternative;
            part goScored : ScoredLanguageRuntimeAlternative;
        }
    }

    /* =======================================================================
     * 2. HL7 Parser Trade Study
     * ======================================================================= */

    package HL7ParserTradeStudy {
        doc /* Trade study: HL7 parser library. Criteria from PIM SYS2.1–SYS2.5: MSH parsing and header metadata; PID and patient identifier extraction; deterministic optional/repeated segments; encoding normalisation; missing-field policy. */

        part def <ParserAssessmentCriteria> 'Parser Assessment Criteria' :> AssessmentCriteria {
            doc /* Criteria for HL7 parser alternatives. Three MOEs: MSH/PID; segment/encoding; missing-field. Score = sum(criterion.value * criterion.weight). */
            part ::> criterion[0] : Criterion {
                attribute ::> name = "MSH/PID Capability";
                attribute ::> weight = 0.34;
            }
            part ::> criterion[1] : Criterion {
                attribute ::> name = "Segment/Encoding Handling";
                attribute ::> weight = 0.33;
            }
            part ::> criterion[2] : Criterion {
                attribute ::> name = "Missing-Field Policy";
                attribute ::> weight = 0.33;
            }
        }

        part def <HL7ParserAlternative> 'HL7 Parser Alternative' :> Alternative {
            doc /* One parser candidate. Holds assessment criteria (value per criterion set per instance). */
            part ::> criteria : ParserAssessmentCriteria;
        }

        part <NodeHl7Complete> 'node-hl7-complete' : HL7ParserAlternative {
            doc /* node-hl7-complete parser alternative. Selection winner. */
            attribute ::> name = "node-hl7-complete";
            part ::> criteria {
                part ::> criterion[0] { attribute ::> value = 0.95; }
                part ::> criterion[1] { attribute ::> value = 0.9; }
                part ::> criterion[2] { attribute ::> value = 0.9; }
            }
        }

        part <Hl7Standard> 'hl7-standard' : HL7ParserAlternative {
            doc /* hl7-standard (Node) parser alternative. */
            attribute ::> name = "hl7-standard";
            part ::> criteria {
                part ::> criterion[0] { attribute ::> value = 0.85; }
                part ::> criterion[1] { attribute ::> value = 0.85; }
                part ::> criterion[2] { attribute ::> value = 0.8; }
            }
        }

        part <PythonHl7Ref> 'python-hl7 (reference)' : HL7ParserAlternative {
            doc /* python-hl7 reference alternative. */
            attribute ::> name = "python-hl7";
            part ::> criteria {
                part ::> criterion[0] { attribute ::> value = 0.9; }
                part ::> criterion[1] { attribute ::> value = 0.85; }
                part ::> criterion[2] { attribute ::> value = 0.75; }
            }
        }

        part def <ScoredHL7ParserAlternative> 'Scored HL7 Parser Alternative' {
            doc /* One parser alternative plus its weighted score. Score is constrained to equal alt.criteria.score. */
            part alt : HL7ParserAlternative;
            attribute score : Real;
            constraint weightedScore : ScoreEqualsCriteriaSum {
                in score = score;
                in criteria = alt.criteria;
            }
        }

        part def <HL7ParserTradeStudyContext> 'HL7 Parser Trade Study Context' {
            doc /* Alternatives: node-hl7-complete; hl7-standard (Node); python-hl7 (reference). Selection: Node-compatible parser (e.g. node-hl7-complete). Fits chosen Node.js runtime and meets MSH/PID/segment/encoding/missing-field criteria. */
            part nodeHl7CompleteScored : ScoredHL7ParserAlternative;
            part hl7StandardScored : ScoredHL7ParserAlternative;
            part pythonHl7RefScored : ScoredHL7ParserAlternative;
        }
    }

    /* =======================================================================
     * 3. HTTP Client Trade Study
     * ======================================================================= */

    package HTTPClientTradeStudy {
        doc /* Trade study: HTTP client for downstream forwarding. Criteria from PIM SYS3.1–SYS3.5: modern TLS and ciphers; endpoint/certificate validation; configurable method and headers; 2xx/4xx/5xx handling; retry and timeout. */

        part def <HTTPClientAssessmentCriteria> 'HTTP Client Assessment Criteria' :> AssessmentCriteria {
            doc /* Criteria for HTTP client alternatives. Three MOEs: TLS/validation; config (method/headers/response); retry/timeout. Score = sum(criterion.value * criterion.weight). */
            part ::> criterion[0] : Criterion {
                attribute ::> name = "TLS/Validation";
                attribute ::> weight = 0.34;
            }
            part ::> criterion[1] : Criterion {
                attribute ::> name = "Config (Method/Headers/Response)";
                attribute ::> weight = 0.33;
            }
            part ::> criterion[2] : Criterion {
                attribute ::> name = "Retry/Timeout";
                attribute ::> weight = 0.33;
            }
        }

        part def <HTTPClientAlternative> 'HTTP Client Alternative' :> Alternative {
            doc /* One HTTP client candidate. Holds assessment criteria (value per criterion set per instance). */
            part ::> criteria : HTTPClientAssessmentCriteria;
        }

        part <AxiosClient> 'axios' : HTTPClientAlternative {
            doc /* axios HTTP client alternative. Tied selection with undici. */
            attribute ::> name = "axios";
            part ::> criteria {
                part ::> criterion[0] { attribute ::> value = 0.95; }
                part ::> criterion[1] { attribute ::> value = 0.95; }
                part ::> criterion[2] { attribute ::> value = 0.9; }
            }
        }

        part <UndiciClient> 'undici' : HTTPClientAlternative {
            doc /* undici HTTP client alternative. Tied selection with axios. */
            attribute ::> name = "undici";
            part ::> criteria {
                part ::> criterion[0] { attribute ::> value = 0.95; }
                part ::> criterion[1] { attribute ::> value = 0.9; }
                part ::> criterion[2] { attribute ::> value = 0.9; }
            }
        }

        part <NodeFetchClient> 'node-fetch' : HTTPClientAlternative {
            doc /* node-fetch with wrappers alternative. */
            attribute ::> name = "node-fetch";
            part ::> criteria {
                part ::> criterion[0] { attribute ::> value = 0.85; }
                part ::> criterion[1] { attribute ::> value = 0.8; }
                part ::> criterion[2] { attribute ::> value = 0.75; }
            }
        }

        part def <ScoredHTTPClientAlternative> 'Scored HTTP Client Alternative' {
            doc /* One HTTP client alternative plus its weighted score. Score is constrained to equal alt.criteria.score. */
            part alt : HTTPClientAlternative;
            attribute score : Real;
            constraint weightedScore : ScoreEqualsCriteriaSum {
                in score = score;
                in criteria = alt.criteria;
            }
        }

        part def <HTTPClientTradeStudyContext> 'HTTP Client Trade Study Context' {
            doc /* Alternatives: axios; undici; node-fetch with wrappers. Selection: axios or undici. Rationale: TLS, configurable retry and timeout; fits Lyrebird backend. */
            part axiosScored : ScoredHTTPClientAlternative;
            part undiciScored : ScoredHTTPClientAlternative;
            part nodeFetchScored : ScoredHTTPClientAlternative;
        }
    }

    /* =======================================================================
     * 4. Deployment Model Trade Study
     * ======================================================================= */

    package DeploymentModelTradeStudy {
        doc /* Trade study: deployment model. Criteria: operability; scaling; portability; alignment with Lyrebird infrastructure (AWS, Terraform). */

        part def <DeploymentAssessmentCriteria> 'Deployment Assessment Criteria' :> AssessmentCriteria {
            doc /* Criteria for deployment alternatives. Three MOEs: operability; scaling; Lyrebird alignment. Score = sum(criterion.value * criterion.weight). */
            part ::> criterion[0] : Criterion {
                attribute ::> name = "Operability";
                attribute ::> weight = 0.33;
            }
            part ::> criterion[1] : Criterion {
                attribute ::> name = "Scaling";
                attribute ::> weight = 0.33;
            }
            part ::> criterion[2] : Criterion {
                attribute ::> name = "Lyrebird Alignment";
                attribute ::> weight = 0.34;
            }
        }

        part def <DeploymentAlternative> 'Deployment Alternative' :> Alternative {
            doc /* One deployment option. Holds assessment criteria (value per criterion set per instance). */
            part ::> criteria : DeploymentAssessmentCriteria;
        }

        part <StandaloneDeployment> 'Standalone process' : DeploymentAlternative {
            doc /* Standalone process deployment alternative. */
            attribute ::> name = "Standalone";
            part ::> criteria {
                part ::> criterion[0] { attribute ::> value = 0.7; }
                part ::> criterion[1] { attribute ::> value = 0.5; }
                part ::> criterion[2] { attribute ::> value = 0.3; }
            }
        }

        part <ContainerDeployment> 'Container (Docker)' : DeploymentAlternative {
            doc /* Container (Docker) deployment alternative. */
            attribute ::> name = "Container";
            part ::> criteria {
                part ::> criterion[0] { attribute ::> value = 0.9; }
                part ::> criterion[1] { attribute ::> value = 0.95; }
                part ::> criterion[2] { attribute ::> value = 0.9; }
            }
        }

        part <ServerlessDeployment> 'Serverless (Lambda)' : DeploymentAlternative {
            doc /* Serverless (e.g. Lambda) deployment alternative. Selection winner: AWS Lambda/API Gateway or ECS/Fargate. */
            attribute ::> name = "Serverless";
            part ::> criteria {
                part ::> criterion[0] { attribute ::> value = 0.9; }
                part ::> criterion[1] { attribute ::> value = 0.95; }
                part ::> criterion[2] { attribute ::> value = 0.95; }
            }
        }

        part def <ScoredDeploymentAlternative> 'Scored Deployment Alternative' {
            doc /* One deployment alternative plus its weighted score. Score is constrained to equal alt.criteria.score. */
            part alt : DeploymentAlternative;
            attribute score : Real;
            constraint weightedScore : ScoreEqualsCriteriaSum {
                in score = score;
                in criteria = alt.criteria;
            }
        }

        part def <DeploymentTradeStudyContext> 'Deployment Trade Study Context' {
            doc /* Alternatives: standalone process; container (Docker); serverless (e.g. Lambda). Selection: AWS-backed (Lambda + API Gateway or ECS/Fargate) with Terraform. Rationale: matches Lyrebird stack; supports forward deployment and customer-specific config. */
            part standaloneScored : ScoredDeploymentAlternative;
            part containerScored : ScoredDeploymentAlternative;
            part serverlessScored : ScoredDeploymentAlternative;
        }
    }
}
