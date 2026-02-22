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
  this._logger.info('Operational store initialised');
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
        doc /* Return one message row by message_id, or undefined. */
        rep functionBody language "TypeScript"
        /*
  const db = this._db as unknown as { prepare: (sql: string) => { get: (...args: unknown[]) => { message_id: string; status: string; received_at: string; message_type?: string; control_id?: string } | undefined } };
  const row = db.prepare('SELECT message_id, status, received_at, message_type, control_id FROM messages WHERE message_id = ?').get(messageId);
  result = row ? { message_id: row.message_id, status: row.status, received_at: row.received_at, message_type: row.message_type, control_id: row.control_id } : undefined;
        */
    }

    action def <GetMessages> 'Get Messages' {
        in :> self : OperationalStore;
        in status : String [0..1];
        in since : String [0..1];
        out result : MessageStatusQueryResult[*];
        doc /* Query messages with optional status and since filters; return list. */
        rep functionBody language "TypeScript"
        /*
  const db = this._db as unknown as { prepare: (sql: string) => { all: (...args: unknown[]) => { message_id: string; status: string; received_at: string; message_type?: string; control_id?: string }[] } };
  let sql = 'SELECT message_id, status, received_at, message_type, control_id FROM messages WHERE 1=1';
  const args: unknown[] = [];
  if (status) { sql += ' AND status = ?'; args.push(status); }
  if (since) { sql += ' AND received_at >= ?'; args.push(since); }
  sql += ' ORDER BY received_at DESC';
  const rows = db.prepare(sql).all(...args);
  result = rows.map((r: { message_id: string; status: string; received_at: string; message_type?: string; control_id?: string }) => ({ message_id: r.message_id, status: r.status, received_at: r.received_at, message_type: r.message_type, control_id: r.control_id }));
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
}
