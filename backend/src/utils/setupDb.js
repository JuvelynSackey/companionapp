/**
 * Creates the schema and loads demo data.
 *
 *   npm run db:setup
 *
 * Safe to re-run: schema.sql drops the tables before recreating them.
 * That also means it wipes existing data, so never point it at anything
 * you care about.
 *
 * On a hosted database (DATABASE_URL set, or NODE_ENV=production):
 *  - it refuses to run if the database already has users, unless given --wipe;
 *  - the three accounts get random passwords instead of the well-known local
 *    ones. They are written to seed-credentials.local.txt (git-ignored) and
 *    not printed, so they never end up in logs.
 */
import { randomBytes } from 'node:crypto';
import { writeFile } from 'node:fs/promises';
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
  {
    fullName: 'Dr. Abena Owusu',
    email: 'lecturer@ug.edu.gh',
    password: 'lecturer123',
    role: 'lecturer',
  },
];

const hosted = Boolean(process.env.DATABASE_URL) || process.env.NODE_ENV === 'production';
const credentialsFile = path.resolve(here, '../../seed-credentials.local.txt');

async function existingUserCount() {
  const { rows } = await pool.query("SELECT to_regclass('public.users') AS t");
  if (!rows[0].t) return 0;
  const count = await pool.query('SELECT COUNT(*)::int AS n FROM users');
  return count.rows[0].n;
}

async function run() {
  if (hosted) {
    const users = await existingUserCount();
    if (users > 0 && !process.argv.includes('--wipe')) {
      throw new Error(
        `This hosted database already has ${users} user(s). Setup would delete everything. ` +
          'Re-run with --wipe only if that is really intended.'
      );
    }
    for (const user of DEMO_USERS) user.password = randomBytes(12).toString('base64url');
  }

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
    console.log(`  ${user.role.padEnd(8)} ${user.email}` + (hosted ? '' : `  (password: ${user.password})`));
  }
  if (hosted) {
    const lines = DEMO_USERS.map((u) => `${u.role}\t${u.email}\t${u.password}`);
    await writeFile(credentialsFile, lines.join('\n') + '\n', { mode: 0o600 });
    console.log(`  Passwords written to ${credentialsFile} (not printed).`);
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
