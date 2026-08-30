import pg from 'pg';
import { config } from './env.js';

const { Pool } = pg;

/**
 * A single shared connection pool. Opening a connection per request would
 * exhaust PostgreSQL's connection limit under any real load, so every query
 * in the app goes through this pool.
 */
export const pool = new Pool({
  host: config.db.host,
  port: config.db.port,
  database: config.db.database,
  user: config.db.user,
  password: config.db.password,
  max: 10,
  idleTimeoutMillis: 30_000,
  // Managed Postgres hosts (Render, etc.) require SSL; local dev Postgres
  // typically doesn't support it, so this only kicks in in production.
  ssl: config.nodeEnv === 'production' ? { rejectUnauthorized: false } : false,
});

pool.on('error', (err) => {
  console.error('Unexpected error on idle PostgreSQL client', err);
});

/** Convenience wrapper so callers do not have to manage clients. */
export function query(text, params) {
  return pool.query(text, params);
}

/**
 * Runs a set of queries inside a transaction, rolling back if any of them
 * throw. Used where two tables must change together (e.g. registering for an
 * event and decrementing a capacity).
 */
export async function withTransaction(callback) {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    const result = await callback(client);
    await client.query('COMMIT');
    return result;
  } catch (err) {
    await client.query('ROLLBACK');
    throw err;
  } finally {
    client.release();
  }
}
