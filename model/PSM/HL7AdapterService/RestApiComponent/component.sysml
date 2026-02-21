package PSM_RestApiComponent {

    alias Actions for PSM_RestApi_Actions;

    private import ScalarValues::*;

    doc /* PSM Rest API component. Serves REST endpoints (health, future metrics/admin). Refines PIM::LogicalArchitecture::RestApi. */

    part def <RestApi> 'Rest Api' :> PIM::LogicalArchitecture::RestApi {
        doc /* HTTP server for REST endpoints: GET /health (component status), future GET /metrics etc. */ 
        attribute 'port' : Integer { doc /* Listen port (e.g. 3000). */ }
        rep textualRepresentation language "TypeScript"
        /*
import type { Hl7AdapterService } from './service';
type HL7AdapterService = Hl7AdapterService;
        */
        perform action initialize : Actions::StartRestApiServer;
    }
}
