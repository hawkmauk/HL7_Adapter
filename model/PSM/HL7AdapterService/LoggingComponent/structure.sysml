package PSM_Logging_Structure {

    private import ScalarValues::*;

    doc /* Logging component structure: Logger type alias for pino.Logger. */

    part def <Logger> 'Logger' {
        doc /* Type alias for pino child logger (used as return type of getLogger). */
        rep textualRepresentation language "TypeScript"
        /*
pino.Logger
        */
    }

    part def <EventEmitterRef> 'Event Emitter Ref' {
        doc /* Reference to Node EventEmitter (for attachTo emitter param). */
        rep textualRepresentation language "TypeScript"
        /*
import('events').EventEmitter
        */
    }
}
