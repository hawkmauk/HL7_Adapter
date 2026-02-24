package PSM_OperationalStore_Actions {

    alias OperationalStore for PSM_OperationalStoreComponent::OperationalStore;
    alias StoreBinding for PSM_OperationalStoreComponent_Interface::StoreBinding;

    private import ScalarValues::*;
    private import PSM_OperationalStore_Structure::*;

    doc /* Operational store CRUD and query actions. AIM S12.7–12.9. */

    action def <InitializeOperationalStore> 'Initialize Operational Store' {
        in config : StoreBinding [0..1];
        in :> self : OperationalStore;
        doc /* Open database from config (dialect, path or connectionString); create tables if not exist. Sets this._db. */
        rep functionBody language "TypeScript"
        /*
  const cfg = config ?? { dialect: this._config.dialect ?? 'sqlite', path: this._config.path, connectionString: this._config.connectionString };
  const dialect = (cfg.dialect ?? 'sqlite') as string;
  if (dialect !== 'sqlite') {
    throw new Error('Only sqlite dialect is supported in this build; use init-db script for PostgreSQL.');
  }
  const dbPath = (cfg as { path?: string }).path ?? ':memory:';
  if (dbPath !== ':memory:') {
    const fs = require('fs');
    const pathMod = require('path');
    const dir = pathMod.dirname(dbPath);
    fs.mkdirSync(dir, { recursive: true });
  }
  const Database = require('better-sqlite3');
  const db = new Database(dbPath);
  this._db = db as unknown as string;
  const d = this._db as unknown as { exec: (sql: string) => void };
  d.exec(`CREATE TABLE IF NOT EXISTS messages (message_id TEXT PRIMARY KEY, received_at TEXT NOT NULL, message_type TEXT, status TEXT NOT NULL, control_id TEXT, raw_length INTEGER)`);
  d.exec(`CREATE TABLE IF NOT EXISTS delivery_attempts (id INTEGER PRIMARY KEY AUTOINCREMENT, message_id TEXT NOT NULL, attempt INTEGER NOT NULL, status_code INTEGER, response_time_ms INTEGER, timestamp TEXT NOT NULL)`);
  d.exec(`CREATE TABLE IF NOT EXISTS errors (id INTEGER PRIMARY KEY AUTOINCREMENT, message_id TEXT NOT NULL, error_class TEXT NOT NULL, detail TEXT, timestamp TEXT NOT NULL)`);
  d.exec(`CREATE INDEX IF NOT EXISTS idx_messages_status ON messages(status)`);
  d.exec(`CREATE INDEX IF NOT EXISTS idx_messages_received_at ON messages(received_at)`);
  d.exec(`CREATE INDEX IF NOT EXISTS idx_errors_message_id ON errors(message_id)`);
  d.exec(`CREATE INDEX IF NOT EXISTS idx_errors_timestamp ON errors(timestamp)`);
  d.exec(`CREATE TABLE IF NOT EXISTS message_detail (message_id TEXT PRIMARY KEY, sending_application TEXT, sending_facility TEXT, receiving_application TEXT, receiving_facility TEXT, message_control_id TEXT, patient_id TEXT, patient_given_name TEXT, patient_family_name TEXT, patient_dob TEXT, patient_gender TEXT)`);
  this._logger.info('Operational store initialised');
        */
    }

    action def <UpdateMessageDetail> 'Update Message Detail' {
        in :> self : OperationalStore;
        in messageId : String;
        in metadata : MessageMetadataView;
        in demographics : PatientDemographicsView [0..1];
        doc /* Store metadata and demographics for a message (called after parse). */
        rep functionBody language "TypeScript"
        /*
  const db = this._db as unknown as { prepare: (sql: string) => { run: (...args: unknown[]) => void } };
  const d = demographics;
  db.prepare(`INSERT OR REPLACE INTO message_detail (message_id, sending_application, sending_facility, receiving_application, receiving_facility, message_control_id, patient_id, patient_given_name, patient_family_name, patient_dob, patient_gender) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`).run(messageId, metadata.sendingApplication ?? '', metadata.sendingFacility ?? '', metadata.receivingApplication ?? '', metadata.receivingFacility ?? '', metadata.messageControlId ?? '', d?.patientId ?? null, d?.givenName ?? null, d?.familyName ?? null, d?.dateOfBirth ?? null, d?.gender ?? null);
  db.prepare('UPDATE messages SET message_type = ?, control_id = ? WHERE message_id = ?').run(metadata.messageType ?? null, metadata.messageControlId ?? null, messageId);
        */
    }

    action def <InsertMessage> 'Insert Message' {
        in :> self : OperationalStore;
        in messageId : String;
        in receivedAt : String;
        in status : String;
        in messageType : String [0..1];
        in controlId : String [0..1];
        in rawLength : Integer [0..1];
        doc /* Insert one message row (status typically 'received'). */
        rep functionBody language "TypeScript"
        /*
  const db = this._db as unknown as { prepare: (sql: string) => { run: (...args: unknown[]) => void } };
  db.prepare('INSERT INTO messages (message_id, received_at, message_type, status, control_id, raw_length) VALUES (?, ?, ?, ?, ?, ?)').run(messageId, receivedAt, messageType ?? null, status, controlId ?? null, rawLength ?? null);
        */
    }

    action def <UpdateMessageStatus> 'Update Message Status' {
        in messageId : String;
        in status : String;
        in :> self : OperationalStore;
        doc /* Update message status (parsed, transformed, delivered, failed). */
        rep functionBody language "TypeScript"
        /*
  const db = this._db as unknown as { prepare: (sql: string) => { run: (...args: unknown[]) => void } };
  db.prepare('UPDATE messages SET status = ? WHERE message_id = ?').run(status, messageId);
        */
    }

    action def <RecordDeliveryAttempt> 'Record Delivery Attempt' {
        in :> self : OperationalStore;
        in messageId : String;
        in attempt : Integer;
        in statusCode : Integer;
        in timestamp : String;
        in responseTimeMs : Integer [0..1];
        doc /* Insert one delivery_attempts row. */
        rep functionBody language "TypeScript"
        /*
  const db = this._db as unknown as { prepare: (sql: string) => { run: (...args: unknown[]) => void } };
  db.prepare('INSERT INTO delivery_attempts (message_id, attempt, status_code, response_time_ms, timestamp) VALUES (?, ?, ?, ?, ?)').run(messageId, attempt, statusCode, responseTimeMs ?? null, timestamp);
        */
    }

    action def <RecordStoreError> 'Record Store Error' {
        in messageId : String;
        in errorClass : String;
        in detail : String;
        in timestamp : String;
        in :> self : OperationalStore;
        doc /* Insert one errors row. */
        rep functionBody language "TypeScript"
        /*
  const db = this._db as unknown as { prepare: (sql: string) => { run: (...args: unknown[]) => void } };
  db.prepare('INSERT INTO errors (message_id, error_class, detail, timestamp) VALUES (?, ?, ?, ?)').run(messageId, errorClass, detail, timestamp);
        */
    }

    action def <GetMessageStatus> 'Get Message Status' {
        in :> self : OperationalStore;
        in messageId : String;
        out result : MessageStatusQueryResult [0..1];
        doc /* Return one message row by message_id with optional metadata and demographics from message_detail, or undefined. */
        rep functionBody language "TypeScript"
        /*
  const db = this._db as unknown as { prepare: (sql: string) => { get: (...args: unknown[]) => Record<string, unknown> | undefined } };
  const row = db.prepare(`SELECT m.message_id, m.status, m.received_at, m.message_type, m.control_id, d.sending_application, d.sending_facility, d.receiving_application, d.receiving_facility, d.message_control_id, d.patient_id, d.patient_given_name, d.patient_family_name, d.patient_dob, d.patient_gender FROM messages m LEFT JOIN message_detail d ON m.message_id = d.message_id WHERE m.message_id = ?`).get(messageId);
  if (!row) { result = undefined; return; }
  const r = row as Record<string, unknown>;
  const meta = r.sending_application != null || r.sending_facility != null ? { sendingApplication: String(r.sending_application ?? ''), sendingFacility: String(r.sending_facility ?? ''), receivingApplication: String(r.receiving_application ?? ''), receivingFacility: String(r.receiving_facility ?? ''), messageType: String(r.message_type ?? ''), messageControlId: String(r.message_control_id ?? '') } : undefined;
  const demo = r.patient_id != null || r.patient_given_name != null || r.patient_family_name != null || r.patient_dob != null || r.patient_gender != null ? { patientId: r.patient_id != null ? String(r.patient_id) : undefined, givenName: r.patient_given_name != null ? String(r.patient_given_name) : undefined, familyName: r.patient_family_name != null ? String(r.patient_family_name) : undefined, dateOfBirth: r.patient_dob != null ? String(r.patient_dob) : undefined, gender: r.patient_gender != null ? String(r.patient_gender) : undefined } : undefined;
  result = { message_id: String(r.message_id), status: String(r.status), received_at: String(r.received_at), message_type: r.message_type != null ? String(r.message_type) : undefined, control_id: r.control_id != null ? String(r.control_id) : undefined, metadata: meta, demographics: demo };
        */
    }

    action def <GetMessages> 'Get Messages' {
        in :> self : OperationalStore;
        in status : String [0..1];
        in since : String [0..1];
        out result : MessageStatusQueryResult[*];
        doc /* Query messages with optional status and since filters; join message_detail for metadata and demographics. */
        rep functionBody language "TypeScript"
        /*
  const db = this._db as unknown as { prepare: (sql: string) => { all: (...args: unknown[]) => Record<string, unknown>[] } };
  let sql = 'SELECT m.message_id, m.status, m.received_at, m.message_type, m.control_id, d.sending_application, d.sending_facility, d.receiving_application, d.receiving_facility, d.message_control_id, d.patient_id, d.patient_given_name, d.patient_family_name, d.patient_dob, d.patient_gender FROM messages m LEFT JOIN message_detail d ON m.message_id = d.message_id WHERE 1=1';
  const args: unknown[] = [];
  if (status) { sql += ' AND m.status = ?'; args.push(status); }
  if (since) { sql += ' AND m.received_at >= ?'; args.push(since); }
  sql += ' ORDER BY m.received_at DESC';
  const rows = db.prepare(sql).all(...args);
  result = rows.map((r: Record<string, unknown>) => {
    const meta = r.sending_application != null || r.sending_facility != null ? { sendingApplication: String(r.sending_application ?? ''), sendingFacility: String(r.sending_facility ?? ''), receivingApplication: String(r.receiving_application ?? ''), receivingFacility: String(r.receiving_facility ?? ''), messageType: String(r.message_type ?? ''), messageControlId: String(r.message_control_id ?? '') } : undefined;
    const demo = r.patient_id != null || r.patient_given_name != null || r.patient_family_name != null || r.patient_dob != null || r.patient_gender != null ? { patientId: r.patient_id != null ? String(r.patient_id) : undefined, givenName: r.patient_given_name != null ? String(r.patient_given_name) : undefined, familyName: r.patient_family_name != null ? String(r.patient_family_name) : undefined, dateOfBirth: r.patient_dob != null ? String(r.patient_dob) : undefined, gender: r.patient_gender != null ? String(r.patient_gender) : undefined } : undefined;
    return { message_id: String(r.message_id), status: String(r.status), received_at: String(r.received_at), message_type: r.message_type != null ? String(r.message_type) : undefined, control_id: r.control_id != null ? String(r.control_id) : undefined, metadata: meta, demographics: demo };
  });
        */
    }

    action def <GetErrorHistory> 'Get Error History' {
        in :> self : OperationalStore;
        in since : String [0..1];
        in messageId : String [0..1];
        out result : ErrorRecord[*];
        doc /* Query errors with optional since and message_id filters; return list. */
        rep functionBody language "TypeScript"
        /*
  const db = this._db as unknown as { prepare: (sql: string) => { all: (...args: unknown[]) => { id: number; message_id: string; error_class: string; detail: string; timestamp: string }[] } };
  let sql = 'SELECT id, message_id, error_class, detail, timestamp FROM errors WHERE 1=1';
  const args: unknown[] = [];
  if (since) { sql += ' AND timestamp >= ?'; args.push(since); }
  if (messageId) { sql += ' AND message_id = ?'; args.push(messageId); }
  sql += ' ORDER BY timestamp DESC';
  const rows = db.prepare(sql).all(...args);
  result = rows.map((r: { id: number; message_id: string; error_class: string; detail: string; timestamp: string }) => ({ id: r.id, message_id: r.message_id, error_class: r.error_class, detail: r.detail, timestamp: r.timestamp }));
        */
    }

    action def <GetErrorCount> 'Get Error Count' {
        in :> self : OperationalStore;
        out result : Integer;
        doc /* Return total number of rows in the errors table (all time). */
        rep functionBody language "TypeScript"
        /*
  const db = this._db as unknown as { prepare: (sql: string) => { get: (...args: unknown[]) => { count: number } } };
  const row = db.prepare('SELECT COUNT(*) as count FROM errors').get();
  result = (row as { count: number }).count ?? 0;
        */
    }
}
