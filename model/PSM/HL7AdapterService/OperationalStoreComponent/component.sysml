package PSM_OperationalStoreComponent {

    alias Actions for PSM_OperationalStore_Actions;
    alias Structure for PSM_OperationalStore_Structure;
    alias Logger for PSM_Logging_Structure::Logger;

    private import ScalarValues::*;

    doc /* PSM Operational Store component. Persists message lifecycle, delivery attempts, and errors; provides queryable audit (AIM S12). Refines PIM::LogicalArchitecture::OperationalStore. */

    part def <OperationalStore> 'Operational Store' :> PIM::LogicalArchitecture::OperationalStore {
        doc /* Technology binding: SQLite (local dev/tests) or PostgreSQL (production). Schema: messages, delivery_attempts, errors. */
        attribute dialect : String = "sqlite" { doc /* Database dialect: sqlite | postgres. */ }
        attribute path : String [0..1] = "./data/adapter.db" { doc /* SQLite file path (e.g. ./data/store.db). */ }
        attribute connectionString : String [0..1] { doc /* PostgreSQL connection string (when dialect is postgres). */ }
        attribute logger : Logger [0..1] { doc /* Supplied by adapter from shared logging facility. */ }
        attribute _db : String [0..1] { doc /* Database connection handle (set by initializeFromBinding). */ }

        perform action initializeFromBinding : Actions::InitializeOperationalStore;
        perform action insertMessage : Actions::InsertMessage;
        perform action updateMessageStatus : Actions::UpdateMessageStatus;
        perform action updateMessageDetail : Actions::UpdateMessageDetail;
        perform action recordDeliveryAttempt : Actions::RecordDeliveryAttempt;
        perform action recordStoreError : Actions::RecordStoreError;
        perform action getMessageStatus : Actions::GetMessageStatus;
        perform action getMessages : Actions::GetMessages;
        perform action getErrorHistory : Actions::GetErrorHistory;
    }
}
