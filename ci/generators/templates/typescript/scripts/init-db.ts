#!/usr/bin/env npx ts-node
/**
 * Initialize operational store schema (messages, delivery_attempts, errors).
 * Copied to the TypeScript output by the generator (see ci/generators/templates/typescript/).
 * Usage (from the TypeScript output directory, e.g. out/typescript):
 *   npx ts-node scripts/init-db.ts [path]
 *   path: SQLite file path (default: ./data/store.db or env STORE_PATH)
 * For PostgreSQL, use the adapter's config with dialect: 'postgres' and run the service once
 * (it creates tables on first initialize), or run equivalent DDL in your migration tool.
 */
import * as fs from 'fs';
import * as path from 'path';

const dbPath = process.argv[2] || process.env.STORE_PATH || path.join(process.cwd(), 'data', 'store.db');

function main(): void {
  const Database = require('better-sqlite3');
  const dir = path.dirname(dbPath);
  if (dir !== '.') {
    fs.mkdirSync(dir, { recursive: true });
  }
  const db = new Database(dbPath);
  db.exec(`
    CREATE TABLE IF NOT EXISTS messages (
      message_id TEXT PRIMARY KEY,
      received_at TEXT NOT NULL,
      message_type TEXT,
      status TEXT NOT NULL,
      control_id TEXT,
      raw_length INTEGER
    );
    CREATE TABLE IF NOT EXISTS delivery_attempts (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      message_id TEXT NOT NULL,
      attempt INTEGER NOT NULL,
      status_code INTEGER,
      response_time_ms INTEGER,
      timestamp TEXT NOT NULL
    );
    CREATE TABLE IF NOT EXISTS errors (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      message_id TEXT NOT NULL,
      error_class TEXT NOT NULL,
      detail TEXT,
      timestamp TEXT NOT NULL
    );
    CREATE INDEX IF NOT EXISTS idx_messages_status ON messages(status);
    CREATE INDEX IF NOT EXISTS idx_messages_received_at ON messages(received_at);
    CREATE INDEX IF NOT EXISTS idx_errors_message_id ON errors(message_id);
    CREATE INDEX IF NOT EXISTS idx_errors_timestamp ON errors(timestamp);
  `);
  db.close();
  console.log(`Schema initialized at ${dbPath}`);
}

main();
