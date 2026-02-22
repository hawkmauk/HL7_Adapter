package PSM_RestApiComponent {

    alias Actions for PSM_RestApi_Actions;
    alias Interface for PSM_RestApiComponent_Interface;
    alias Logger for PSM_Logging_Structure::Logger;
    
    private import ScalarValues::*;

    doc /* PSM Rest API component. Serves REST endpoints: GET /health (aggregate and per-component status), GET /metrics (message-flow and error counters for dashboard). Data contract: see docs/RestApi_Dashboard_Contract.md. Refines PIM::LogicalArchitecture::RestApi. */

    part def <RestApi> 'Rest Api' :> PIM::LogicalArchitecture::RestApi {
        doc /* HTTP server for REST endpoints: GET /health (component status), GET /metrics (dashboard metrics). Listens on listenHost and listenPort from config. */ 
        
        attribute listenHost : String [0..1] = "0.0.0.0" { doc /* Bind address (e.g. 127.0.0.1 or 0.0.0.0). */ }
        attribute listenPort : Integer = 3000 { doc /* Listen port (e.g. 3000). */ }
        attribute logger : Logger [0..1] { doc /* Supplied by adapter from shared logging facility. */ }
        
        rep textualRepresentation language "TypeScript"
        /*
import type { Hl7AdapterService } from './service';
type HL7AdapterService = Hl7AdapterService;
        */
        
        perform action initializeFromBinding : Actions::InitializeRestApi;
        perform action getStatus : Actions::GetRestApiStatus;
    }
}
