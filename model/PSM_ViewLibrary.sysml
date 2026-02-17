package 'PSM-ViewLibrary' {
    private import Views::*;
    private import ProjectLifecycle::StandardDocumentationFramework::StandardViewpointCatalog::*;

    package PSMStandardViewpointCatalog {
        doc /* PSM-specific viewpoint catalog specializing the abstract lifecycle documentation contract. */

        viewpoint def PlatformRealizationViewpoint :> ArchitectureAndBehaviorViewpoint {
            doc /* Covers technology-specific implementation and deployment realization details. */
        }

        viewpoint def OperationalReadinessViewpoint :> LifecycleGateReadinessViewpoint {
            doc /* Covers release readiness, operational transition, and production signoff evidence. */
        }

        viewpoint def VerificationEvidenceViewpoint :> VerificationAndComplianceViewpoint {
            doc /* Covers concrete test evidence, compliance outcomes, and residual risk posture. */
        }
    }
}
