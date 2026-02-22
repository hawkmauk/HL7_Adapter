package PSM_RestApiComponent {

    alias Actions for PSM_RestApi_Actions;
    alias Interface for PSM_RestApiComponent_Interface;
    
    private import ScalarValues::*;

    doc /* PSM Rest API component. Serves REST endpoints: GET /health (aggregate and per-component status), GET /metrics (message-flow and error counters for dashboard). Data contract: see docs/RestApi_Dashboard_Contract.md. Refines PIM::LogicalArchitecture::RestApi. */

    part def <RestApi> 'Rest Api' :> PIM::LogicalArchitecture::RestApi {
        doc /* HTTP server for REST endpoints: GET /health (component status), GET /metrics (dashboard metrics). Listens on listenPort from config. */ 
        
        attribute listenPort : Integer = 3000 { doc /* Listen port (e.g. 3000). */ }
        
        rep textualRepresentation language "TypeScript"
        /*
import type { Hl7AdapterService } from './service';
type HL7AdapterService = Hl7AdapterService;
        */
        
        perform action initializeFromBinding : Actions::InitializeRestApi;
        perform action getStatus : Actions::GetRestApiStatus;
    }
}
