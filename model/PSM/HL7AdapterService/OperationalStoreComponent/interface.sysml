package PSM_OperationalStoreComponent_Interface {

    private import ScalarValues::*;

    part def <StoreBinding> 'Store Binding' {
        doc /* Binding for operational store: dialect (sqlite | postgres), path for SQLite or connectionString for PostgreSQL. */
        attribute dialect : String;
        attribute path : String [0..1];
        attribute connectionString : String [0..1];
    }
}
