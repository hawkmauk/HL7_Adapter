package CIM_View {

    private import Views::*;
    private import MDA_View::*;
    private import CIM_Viewpoint::*;
    private import MDA_Lifecycle::*;
    private import CIM::*;

    viewpoint stakeholderNeedsViewpoint : StakeholderNeedsViewpoint;
    viewpoint conOpsViewpoint : ConOpsViewpoint;
    viewpoint operationalScenariosViewpoint : OperationalScenariosViewpoint;
    viewpoint interfaceContextViewpoint : InterfaceContextViewpoint;
    viewpoint complianceAndSafetyViewpoint : ComplianceAndSafetyViewpoint;
    viewpoint lifecycleGatewayReadinessViewpoint : LifecycleGatewayReadinessViewpoint;

    view def <SNRS_Document> 'CIM Stakeholder Needs and Requirements Document' {
        doc /* Captures CIM-level stakeholder identities, needs, and traceable requirements at the CIM level. */
        satisfy stakeholderNeedsViewpoint;
        render asElementTable;

        view <StakeholderOverviewSection> 'Stakeholder Overview' {
            doc
            /* This section introduces the key stakeholder groups for the system-of-interest
               and their roles in the problem domain. It should make clear whose outcomes,
               responsibilities, and concerns drive the requirements in this document.
             */
            expose CIM::Stakeholders::**;
        }

        view <NeedsSection> 'Stakeholder Needs' {
            doc
            /* This section summarises stakeholder needs and expectations in narrative form.
               It links the stakeholder roles introduced earlier to the outcomes they care
               about and sets the stage for formal requirements.
             */
            expose CIM::Mission::**;
        }

        view <RequirementsSection> 'Requirements' {
            doc
            /* This section captures the CIM-level requirements that respond to stakeholder
               needs. It should provide a clear, reviewable list of requirements that can
               be traced back to specific stakeholders and concerns.
             */
            expose CIM::Mission::**;
        }

        view <TraceabilitySection> 'Traceability and Coverage' {
            doc
            /* This section is intended to host traceability and coverage views that show
               how stakeholder needs are satisfied by CIM requirements and where coverage
               gaps may exist.
             */
            expose CIM::Stakeholders::**;
            expose CIM::Mission::**;
        }
    }

    view def <ConOps_Document> 'CIM Concept of Operations Document' {
        doc /* Captures CIM-level mission, stakeholders, context, operational scenarios, and assumptions. */
        satisfy conOpsViewpoint;
        render asTreeDiagram;

        view <DomainSection> 'Domain' {
            doc
            /* This section describes the problem domain in which the system-of-interest operates.
               It introduces the key domain entities, information flows, and external systems that
               shape the HL7 Adapter’s role, without committing to any particular solution design.

               Reviewers should come away with a shared mental model of:
               - What business or clinical workflows exist in the environment.
               - Which organisations, systems, and data artefacts participate in those workflows.
               - Where the system-of-interest begins and ends conceptually in that ecosystem.

               The intent is to provide enough context that subsequent sections on stakeholders,
               context, operations, and assumptions can be read with a clear understanding of
               “the world in which this adapter lives”.
             */
            expose CIM::Domain::**;
        }

        view <ContextSection> 'Context' {
            doc
            /* This section presents the black-box operational context for the system-of-interest.
               It explains how the system interacts with its environment, which external actors
               and systems connect to it, and what high-level responsibilities exist at the
               system boundary.
             */
            expose CIM::Context::**;
        }

        view <StakeholdersSection> 'Stakeholders' {
            doc
            /* This section introduces the key stakeholder groups, their roles in the domain,
               and their relationship to the system-of-interest. It should make clear whose
               needs and concerns drive the subsequent requirements and constraints.
             */
            expose CIM::Stakeholders::**;
        }

        view <OperationsSection> 'Operations' {
            doc
            /* This section summarises the operational activities and scenario flows at the CIM
               level. It should provide narrative descriptions of nominal and exceptional flows
               without prescribing detailed design or implementation behaviour.
             */
            expose CIM::Operations::**;
        }

        view <EventsSection> 'Event Taxonomy' {
            doc
            /* This section defines the conceptual domain events that tie the behaviour model to
               the structure model (AIM S2.1, S7.5). Each event is cross-referenced to the CIM
               action that produces or consumes it. Events are technology-agnostic.
             */
            expose CIM::Events::**;
        }

        view <MissionSection> 'Mission' {
            doc
            /* This section states the mission objectives, desired outcomes, and success criteria
               for the system-of-interest. It provides the “why” behind the adapter, linking the
               domain understanding and stakeholder needs to concrete mission outcomes.
             */
            expose CIM::Mission::**;
        }

        view <AssumptionsSection> 'Assumptions' {
            doc
            /* This section records key assumptions, constraints, and non-design decisions that
               influence how the concept of operations should be interpreted. It should capture
               things that must remain true in the environment for the ConOps to hold.
             */
            expose CIM::Assumptions::**;
        }
    }

    view def <OperationalScenarios_Document> 'CIM Operational Scenarios and Use Case Document' {
        doc /* Captures CIM-level nominal and degraded operational scenarios and use-case narratives. */
        satisfy operationalScenariosViewpoint;
        render asTextualNotation;

        view <ScenarioOverviewSection> 'Scenario Overview' {
            doc
            /* This section introduces the overall set of operational scenarios considered
               at the CIM level. It explains the scope of nominal and degraded flows and
               how they relate to the mission and domain context.
             */
            expose CIM::Operations::**;
        }

        view <ScenariosSection> 'Scenarios' {
            doc
            /* This section provides narrative descriptions of the primary, success-oriented
               operational flows. It should highlight the main path from event publication
               through to successful completion.
             */
            expose CIM::Operations::HandleMessage::**;
        }

        view <UseCasesSection> 'Use Cases' {
            doc
            /* This section summarises key use cases and their relationship to the documented
               scenarios. It can be used to group scenarios by stakeholder, mission outcome,
               or operational objective.
             */
            expose CIM::Operations::**;
        }
    }

    view def <EICD_Document> 'CIM External Interface Context Document' {
        doc /* Captures CIM-level external context, actors, and conceptual interface boundaries. */
        satisfy interfaceContextViewpoint;
        render asElementTable;

        view <ContextOverviewSection> 'Context Overview' {
            doc
            /* This section introduces the external context in which the system-of-interest
               operates. It explains the key external systems, organisational boundaries,
               and environments that are relevant to the interface discussion.
             */
            expose CIM::Context::**;
        }

        view <ActorsAndInterfacesSection> 'Actors and Interfaces' {
            doc
            /* This section describes the principal external actors and conceptual interfaces
               between them and the system-of-interest. It should make clear who interacts
               with the system and over which logical boundaries.
             */
            expose CIM::Stakeholders::**;
            expose CIM::Domain::RESTEndpoint::**;
        }

        view <BoundariesSection> 'Interface Boundaries' {
            doc
            /* This section focuses on the conceptual boundaries (logical, organisational,
               and technical) that separate the system-of-interest from external systems.
               It is used to clarify what is inside versus outside the adapter’s scope.
             */
            expose CIM::Context::NetworkBoundary::**;
        }

        view <InformationExchangesSection> 'Information Exchanges' {
            doc
            /* This section summarises the key information exchanges that cross the
               external interfaces, such as HL7 messages and JSON payloads. It should
               highlight what information is exchanged, in which direction, and why.
             */
            expose CIM::Domain::HL7Message::**;
            expose CIM::Domain::JSONPayload::**;
        }
    }

    view def <RSCM_Document> 'CIM Regulatory and Standards Compliance Matrix' {
        doc /* Captures CIM-level regulatory, standards, and policy obligations and their context mapping. */
        satisfy complianceAndSafetyViewpoint;
        render asElementTable;

        view <RegulatoryLandscapeSection> 'Regulatory Landscape' {
            doc
            /* This section introduces the regulatory, standards, and policy landscape that
               is relevant to the system-of-interest. It provides narrative context for why
               particular obligations matter to the adapter.
             */
            expose CIM::Assumptions::PHIHandlingPolicy::**;
        }

        view <ObligationsSection> 'Obligations and Constraints' {
            doc
            /* This section summarises the specific obligations, constraints, and policies
               that must be met. It serves as the front door to the compliance matrix.
             */
            expose CIM::Assumptions::**;
        }

        view <ContextMappingSection> 'Context Mapping' {
            doc
            /* This section explains how obligations map onto the domain, context, mission,
               and operations defined at the CIM level. It helps reviewers see where each
               regulatory concern shows up in the conceptual model.
             */
            expose CIM::Domain::**;
            expose CIM::Context::**;
            expose CIM::Mission::**;
        }

        view <ComplianceSummarySection> 'Compliance Summary' {
            doc
            /* This section provides a narrative summary of the current compliance posture,
               highlighting key strengths, open issues, and areas requiring further analysis
               or assurance as the project progresses.
             */
            expose CIM::Assumptions::**;
        }
    }

    view def <SCHA_Document> 'CIM Safety Case and Hazard Analysis Summary' {
        doc /* Captures CIM-level safety case summary, key hazards, and mitigation posture. */
        satisfy complianceAndSafetyViewpoint;
        render asElementTable;

        view <SafetyObjectivesSection> 'Safety Objectives' {
            doc
            /* This section introduces the high-level safety objectives for the system-of-interest.
               It explains what “safe enough” means in the context of the mission and domain.
             */
            expose CIM::Mission::**;
        }

        view <HazardIdentificationSection> 'Hazard Identification' {
            doc
            /* This section summarises the key hazards and unsafe conditions identified at the
               CIM level. It is intended to provide a concise overview rather than a full FMEA.
             */
            expose CIM::Assumptions::**;
        }

        view <RiskAssessmentSection> 'Risk Assessment and Mitigation' {
            doc
            /* This section discusses the risk assessment and mitigation posture associated with
               the identified hazards. It links hazards to mitigations and residual risk at the
               conceptual level.
             */
            expose CIM::Mission::**;
            expose CIM::Assumptions::**;
        }

        view <SafetyCaseSummarySection> 'Safety Case Summary' {
            doc
            /* This section provides a narrative summary of the safety case status at the CIM level,
               including key arguments, assumptions, and evidence that will need to be expanded in
               later lifecycle phases.
             */
            expose CIM::Mission::**;
        }
    }

    view def <GatewaySignoff_Document> 'CIM Gateway Readiness and Signoff Document' {
        doc /* Captures CIM gateway entry criteria, stakeholder consensus status, and signoff evidence. */
        satisfy lifecycleGatewayReadinessViewpoint;
        render asElementTable;

        view <OverviewSection> 'Overview' {
            doc
            /* This section explains the purpose of the CIM gateway, the decision being made,
               and the scope of evidence considered. It should orient reviewers to what this
               signoff represents in the overall lifecycle.
             */
            expose MDA_Lifecycle::LifecycleMilestone::**;
        }

        view <ReadinessEvidenceSection> 'Readiness Evidence' {
            doc
            /* This section aggregates the key readiness evidence associated with the CIM
               gateway, such as completed reviews, open issues, and supporting artefacts.
               It provides a concise narrative of why the team believes the gateway entry
               and exit criteria are satisfied.
             */
            expose MDA_Lifecycle::GatewayCheck::**;
            expose MDA_Lifecycle::SignoffRecord::**;
        }

        view <StakeholderSignoffSection> 'Stakeholder Signoff' {
            doc
            /* This section focuses on the stakeholders who participate in the CIM gateway,
               their roles, and their individual signoff status. It is intended to drive a
               tabular representation of stakeholders, roles, decisions, and dates.
             */
            expose MDA_Lifecycle::CIMConsensusGateway::**;
        }

        view <DecisionSection> 'Decision' {
            doc
            /* This section records the outcome of the gateway decision, including any
               conditions, follow-up actions, or reservations. It provides the durable
               narrative that explains why the gateway was approved, deferred, or rejected.
             */
            expose MDA_Lifecycle::SignoffRecord::**;
        }
    }
}
