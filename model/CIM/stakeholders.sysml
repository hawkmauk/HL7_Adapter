package CIM_Stakeholders {
    doc /* Stakeholder and actor concepts interacting with or governing the integration. */

    part def <IntegrationEngineer> 'Integration Engineer' {
        doc /* Builds, configures, and maintains the adapter and local deployment. */
    }

    part def <ClinicalSystemOwner> 'Clinical System Owner' {
        doc /* Owns the upstream HL7-producing system and data quality expectations. */
    }

    part def <UpstreamHL7System> 'Upstream HL7 System' {
        doc /* External clinical system that publishes HL7 events to the receiver. */
    }

    part def <DownstreamAPIOwner> 'Downstream API Owner' {
        doc /* Owns the HTTP API that consumes transformed event payloads. */
    }

    part def <SecurityAndComplianceOfficer> 'Security and Compliance Officer' {
        doc /* Ensures patient data handling, transport security, and compliance obligations. */
    }

    part def <OperationsEngineer> 'Operations Engineer' {
        doc /* Monitors runtime health, failures, retries, and service continuity. */
    }
}
