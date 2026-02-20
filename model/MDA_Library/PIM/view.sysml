package PIM_View {

    private import Views::*;
    private import MDA_View::*;
    private import PIM_Viewpoint::*;
    private import PIM::*;

    viewpoint logicalArchitectureViewpoint : PIM_Viewpoint::LogicalArchitectureViewpoint;
    viewpoint requirementAllocationViewpoint : PIM_Viewpoint::RequirementAllocationViewpoint;
    viewpoint pimVerificationReadinessViewpoint : PIM_Viewpoint::PIMVerificationReadinessViewpoint;
    viewpoint pimLifecycleGatewayReadinessViewpoint : PIM_Viewpoint::PIMLifecycleGatewayReadinessViewpoint;

    view def <LogicalArchitecture_Document> 'PIM Logical Architecture Specification' {
        doc /* Captures the platform-independent logical architecture, components, connectors, and responsibilities. */
        satisfy logicalArchitectureViewpoint;
        render asElementTable;

        view <OverviewSection> 'Overview' {
            doc
            /* This section provides a high-level overview of the logical architecture for the system-of-interest.
               It explains the main components, their roles, and how the architecture supports the mission.
             */
            expose PIM::LogicalArchitecture::**;
        }

        view <ComponentStructureSection> 'Component Structure' {
            doc
            /* This section describes the logical components and their internal structure in greater detail.
               It is intended to support review of decomposition, responsibilities, and cohesion.
             */
            expose PIM::LogicalArchitecture::**;
        }

        view <ConnectorsAndPortsSection> 'Connectors and Ports' {
            doc
            /* This section focuses on the logical connectors, ports, and relationships between components
               and external actors. It should clarify how information and control flow through the system.
             */
            expose PIM::Interfaces::**;
        }

        view <ResponsibilitiesSection> 'Responsibilities' {
            doc
            /* This section summarises the responsibilities of major components and how they collectively
               satisfy the PIM-level requirements.
             */
            expose PIM::Requirements::**;
        }

        view <RationaleSection> 'Design Rationale' {
            doc
            /* This section captures key architectural decisions and rationale, including trade-offs and
               alternatives considered at the PIM level.
             */
            expose PIM::Allocations::**;
        }
    }

    view def <InterfaceDesign_Document> 'PIM Interface Design Description' {
        doc /* Captures platform-independent interface definitions, message contracts, and error handling behavior. */
        satisfy logicalArchitectureViewpoint;
        render asElementTable;

        view <ContextSection> 'Interface Context' {
            doc
            /* This section explains the logical context for the interfaces, including which components
               and external actors participate in each interface boundary.
             */
            expose PIM::Interfaces::**;
        }

        view <InterfaceCatalogSection> 'Interface Catalog' {
            doc
            /* This section presents the catalog of logical interfaces, ports, and service endpoints
               defined at the PIM level, including signal-typed flow properties and complementary
               port pairs (AIM S7.5).
             */
            expose PIM::Interfaces::**;
        }

        view <ComponentStructureAndBoundaryPortsSection> 'Component Structure and Boundary Ports' {
            doc
            /* This section describes the logical components and their signal receptions. Ports
               are only on the system boundary (UpstreamHL7System, HL7AdapterService,
               DownstreamAPIOwner); the adapter composite exposes fromUpstream and toDownstream
               ports only.
             */
            expose PIM::LogicalArchitecture::**;
        }

        view <MessageContractsSection> 'Message Contracts' {
            doc
            /* This section describes the logical message contracts and data structures exchanged over
               the interfaces, independent of serialization technology.
             */
            expose PIM::DataModel::**;
        }

        view <ErrorHandlingSection> 'Error Handling' {
            doc
            /* This section explains how logical interfaces behave under error conditions, including
               timeouts, malformed data, and downstream failures.
             */
            expose PIM::Behavior::**;
        }

        view <VersioningSection> 'Versioning and Compatibility' {
            doc
            /* This section records the approach to versioning and compatibility for logical interfaces,
               including deprecation and evolution strategies.
             */
            expose PIM::Interfaces::**;
        }
    }

    view def <BehaviorDesign_Document> 'PIM Behavior and Use Case Design Document' {
        doc /* Captures PIM-level behavioral descriptions, nominal and degraded flows, and use case refinements. */
        satisfy logicalArchitectureViewpoint;
        render asTextualNotation;

        view <ScenarioOverviewSection> 'Scenario Overview' {
            doc
            /* This section introduces the main behavioral scenarios and use cases at the PIM level,
               including how they refine CIM operational scenarios.
             */
            expose PIM::Behavior::**;
            expose PIM::UseCases::**;
        }

        view <NominalFlowsSection> 'Nominal Flows' {
            doc
            /* This section focuses on primary success-oriented flows and their mapping to logical components. */
            expose PIM::UseCases::IngestAndForwardEvent::**;
        }

        view <ErrorFlowsSection> 'Error and Degraded Flows' {
            doc
            /* This section describes how the system behaves under error and degraded conditions at the PIM level. */
            expose PIM::UseCases::HandleParseFailure::**;
            expose PIM::UseCases::HandleDeliveryFailure::**;
        }

        view <StateMachinesSection> 'State Machines and Internal Behavior' {
            doc
            /* This section is reserved for state machines or other internal behavioral specifications
               associated with logical components.
             */
            expose PIM::Behavior::**;
        }
    }

    view def <Allocation_Document> 'PIM Requirements and Allocation Specification' {
        doc /* Captures PIM-level requirements, their allocations to logical elements, and traceability to CIM. */
        satisfy requirementAllocationViewpoint;
        render asElementTable;

        view <RequirementsOverviewSection> 'Requirements Overview' {
            doc
            /* This section summarises the PIM-level requirements and their relationship to CIM mission
               and stakeholder needs.
             */
            expose PIM::Requirements::**;
        }

        view <AllocationMatrixSection> 'Allocation Matrix' {
            doc
            /* This section focuses on allocations from PIM requirements to logical components, interfaces,
               and behaviors, to support coverage and impact analysis.
             */
            expose PIM::Allocations::**;
        }

        view <DesignDecisionsSection> 'Design Decisions and Assumptions' {
            doc
            /* This section records key design decisions, assumptions, and trade-offs specifically related
               to requirement satisfaction at the PIM level.
             */
            expose PIM::Allocations::**;
        }
    }

    view def <Verification_Document> 'PIM Verification Readiness and Test Intent Document' {
        doc /* Captures PIM-level verification objectives, planned test approaches, and coverage of PIM requirements. */
        satisfy pimVerificationReadinessViewpoint;
        render asElementTable;

        view <VerificationObjectivesSection> 'Verification Objectives' {
            doc
            /* This section explains the verification objectives at the PIM level and how they relate
               to PIM requirements.
             */
            expose PIM_Structure::Verification::**;
        }

        view <TestDesignSection> 'Test Design and Strategy' {
            doc
            /* This section summarises the planned test strategies, test types, and logical coverage
               focus before PSM realization.
             */
            expose PIM_Structure::Verification::**;
        }

        view <CoverageSummarySection> 'Coverage Summary' {
            doc
            /* This section provides a summary of requirement-to-test coverage and identifies any
               untested or partially tested areas at the PIM level.
             */
            expose PIM_Structure::Verification::**;
        }
    }

    view def <PIMGatewaySignoff_Document> 'PIM Gateway Readiness and Design Review Document' {
        doc /* Captures PIM gate entry criteria, design risks, and signoff evidence before entering PSM. */
        satisfy pimLifecycleGatewayReadinessViewpoint;
        render asElementTable;

        view <OverviewSection> 'Overview' {
            doc
            /* This section explains the purpose of the PIM gateway, the decision being made,
               and the scope of logical design evidence being considered.
             */
            expose PIM::LogicalArchitecture::**;
        }

        view <DesignReadinessSection> 'Design Readiness Evidence' {
            doc
            /* This section aggregates key evidence that the PIM logical design is sufficiently
               mature, including completeness of architecture, interfaces, and allocations.
             */
            expose PIM::LogicalArchitecture::**;
            expose PIM::Interfaces::**;
            expose PIM::Allocations::**;
        }

        view <RiskAndIssuesSection> 'Risks and Open Issues' {
            doc
            /* This section summarises outstanding design risks, technical debt, and open issues
               that may affect progression past the PIM gateway.
             */
            expose PIM::Requirements::**;
        }

        view <SignoffSection> 'Stakeholder Signoff' {
            doc
            /* This section is intended to host signoff records and stakeholder decisions associated
               with the PIM gateway.
             */
            expose PIM::Allocations::**;
        }
    }
}

