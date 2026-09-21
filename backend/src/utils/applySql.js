/**
 * Runs one SQL file against the configured database (same env as the API).
 *
 *   npm run db:apply -- db/migrations/2026-09-ug-grading-scale.sql
 *
 * For applying a migration to an existing database without psql. Unlike
 * `npm run db:setup`, this never drops anything by itself: it runs exactly
 * the statements in the file you name.
 */
import { readFile } from 'node:fs/promises';
import path from 'node:path';
import { pool } from '../config/db.js';

const file = process.argv[2];

if (!file) {
  console.error('Usage: npm run db:apply -- <path-to-file.sql>');
  process.exit(1);
}

try {
  const sql = await readFile(path.resolve(file), 'utf8');
  await pool.query(sql);
  console.log(`Applied ${file}`);
} catch (err) {
  console.error(`Failed to apply ${file}: ${err.message}`);
  process.exitCode = 1;
} finally {
  await pool.end();
}
