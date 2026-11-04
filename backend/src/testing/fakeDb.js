/**
 * Offline stand-ins for controller unit tests: a scripted database in place
 * of the shared pool, and Express-like req/res objects. No PostgreSQL needed.
 */
import { pool } from '../config/db.js';

/**
 * Routes every query (including those inside withTransaction) to
 * [respond](sql, params), which returns { rows, rowCount } or throws (e.g. an
 * error with a Postgres `code`). SQL is passed with whitespace collapsed so
 * tests can match on short fragments. Returns the recorded calls; call
 * restore() when done.
 */
export function installFakeDb(respond = () => ({ rows: [] })) {
  const calls = [];
  const original = { query: pool.query, connect: pool.connect };

  const run = async (text, params = []) => {
    const sql = text.replace(/\s+/g, ' ').trim();
    calls.push({ sql, params });
    const result = (await respond(sql, params)) ?? {};
    const rows = result.rows ?? [];
    return { rows, rowCount: result.rowCount ?? rows.length };
  };

  pool.query = run;
  pool.connect = async () => ({ query: run, release() {} });

  return {
    calls,
    /** The statements that ran, minus transaction bookkeeping. */
    statements: () => calls.filter((c) => !/^(BEGIN|COMMIT|ROLLBACK)$/.test(c.sql)),
    restore() {
      pool.query = original.query;
      pool.connect = original.connect;
    },
  };
}

/** A Postgres error as pg reports it, e.g. 23503 (foreign key violation). */
export function pgError(code) {
  return Object.assign(new Error(`pg error ${code}`), { code });
}

/**
 * Runs a controller with a fake request and returns what it sent. `error` is
 * whatever it passed to next() (an unexpected failure the app's error
 * handler would turn into a 500).
 */
export async function callController(handler, req = {}) {
  const res = {
    statusCode: 200,
    body: undefined,
    status(code) {
      this.statusCode = code;
      return this;
    },
    json(body) {
      this.body = body;
      return this;
    },
    send(body) {
      this.body = body;
      return this;
    },
  };
  let error;
  await handler({ params: {}, query: {}, body: {}, ...req }, res, (err) => {
    error = err;
  });
  return { status: res.statusCode, body: res.body, error };
}

export const student = { userId: 7, role: 'student' };
export const lecturer = { userId: 21, role: 'lecturer' };
export const otherLecturer = { userId: 22, role: 'lecturer' };
export const admin = { userId: 1, role: 'admin' };
