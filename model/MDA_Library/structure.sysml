package MDA_Structure {

    part def <System> System;
    part def <Stakeholder> Stakeholder;

    doc /* Cross-project governance stakeholders for lifecycle decisions and signoff. */

    part def <Customer> Customer :> Stakeholder {
        doc /* Funding or sponsoring stakeholder who accepts delivered value and outcomes. */
    }

    part def <ProjectManager> 'Project Manager' :> Stakeholder {
        doc /* Accountable for schedule, scope, risks, and gate readiness coordination. */
    }

    part def <SystemsEngineer> 'Systems Engineer' :> Stakeholder {
        doc /* Owns model coherence, stakeholder concern coverage, and architectural traceability. */
    }

    part def <TechnicalLead> 'Technical Lead' :> Stakeholder {
        doc /* Ensures technical feasibility and alignment of logical and implementation solutions. */
    }

    part def <QualityAssuranceLead> 'Quality Assurance Lead' :> Stakeholder {
        doc /* Assures verification coverage, test quality, and release confidence evidence. */
    }

    part def <ComplianceOfficer> 'Compliance Officer' :> Stakeholder {
        doc /* Verifies regulatory, privacy, and policy obligations are represented and satisfied. */
    }

    part def <OperationsOwner> 'Operations Owner' :> Stakeholder {
        doc /* Confirms operational supportability, monitoring readiness, and service transition fit. */
    }
}
