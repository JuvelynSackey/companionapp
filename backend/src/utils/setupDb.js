/**
 * Creates the schema and loads demo data.
 *
 *   npm run db:setup
 *
 * Safe to re-run: schema.sql drops the tables before recreating them.
 * That also means it wipes existing data, so never point it at anything
 * you care about.
 */
import { readFile } from 'node:fs/promises';
import { fileURLToPath } from 'node:url';
import path from 'node:path';
import bcrypt from 'bcryptjs';
import { pool } from '../config/db.js';

const here = path.dirname(fileURLToPath(import.meta.url));
const dbDir = path.resolve(here, '../../db');

const DEMO_USERS = [
  {
    fullName: 'Ekow Juvelyn Sackey',
    email: 'student@ug.edu.gh',
    password: 'student123',
    role: 'student',
  },
  {
    fullName: 'Campus Administrator',
    email: 'admin@ug.edu.gh',
    password: 'admin123',
    role: 'admin',
  },
];

async function run() {
  console.log('Applying schema...');
  const schema = await readFile(path.join(dbDir, 'schema.sql'), 'utf8');
  await pool.query(schema);

  console.log('Creating demo users...');
  for (const user of DEMO_USERS) {
    const hash = await bcrypt.hash(user.password, 12);
    await pool.query(
      `INSERT INTO users (full_name, email, password_hash, role)
       VALUES ($1, $2, $3, $4)`,
      [user.fullName, user.email, hash, user.role]
    );
    console.log(`  ${user.role.padEnd(7)} ${user.email}  (password: ${user.password})`);
  }

  console.log('Loading demo data...');
  const seed = await readFile(path.join(dbDir, 'seed.sql'), 'utf8');
  await pool.query(seed);

  console.log('\nDatabase ready.');
}

run()
  .catch((err) => {
    console.error('\nSetup failed:', err.message);
    process.exitCode = 1;
  })
  .finally(() => pool.end());
