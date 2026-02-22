package PSM_LoggingComponent {

    alias Action for PSM_Logging_Actions;
    alias Structure for PSM_Logging_Structure;

    private import ScalarValues::*;

    doc /* PSM Logging component. Shared logging facility for state-transition and adapter logging. Refines PIM::LogicalArchitecture::Logging. */

    part def <Logging> 'Logging' :> PIM::LogicalArchitecture::Logging {
        doc /* Provides getLogger(componentName) returning a pino child logger; attachTo(emitter, componentName) for transition logging. */
        attribute logLevel : String = "info" { doc /* Log level: debug | info | warn | error. */ }
        attribute format : String [0..1] = "json" { doc /* Output format: json | text. */ }

        rep textualRepresentation language "TypeScript"
        /*
import pino from 'pino';
import { EventEmitter } from 'events';
        */

        rep classMembers language "TypeScript"
        /*
private _root!: pino.Logger;
        */

        perform action initialize : Action::InitializeLogging;
        perform action getLogger : Action::GetLogger;
        perform action attachTo : Action::AttachTo;
    }
}
