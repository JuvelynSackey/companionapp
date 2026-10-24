/**
 * Tests the real SQL behind linking/creating a user from a verified Google
 * identity, against the configured database:   npm run test:db
 *
 * Not part of `npm test` (which needs no database). It creates throwaway
 * users and removes them when it finishes. Each test uses its own pool
 * connection via the shared `pool`, closed once at the very end (see after()).
 */
import { test, after } from 'node:test';
import assert from 'node:assert/strict';
import bcrypt from 'bcryptjs';
import { pool } from '../config/db.js';
import { findOrCreateGoogleUser } from './googleUserStore.js';

const stamp = Date.now();
let n = 0;
const nextEmail = (label) => `gtest-${label}-${stamp}-${n++}@ug.edu.gh`;
const nextGoogleUid = (label) => `gtest-uid-${label}-${stamp}-${n++}`;

async function createPasswordUser(email) {
  const { rows } = await pool.query(
    `INSERT INTO users (full_name, email, password_hash) VALUES ($1, $2, $3) RETURNING user_id`,
    ['Existing Password User', email, await bcrypt.hash('whatever123', 4)]
  );
  return rows[0].user_id;
}

async function rowFor(userId) {
  const { rows } = await pool.query(
    'SELECT user_id, full_name, email, role, password_hash, google_uid FROM users WHERE user_id = $1',
    [userId]
  );
  return rows[0];
}

after(async () => {
  await pool.query('DELETE FROM users WHERE email LIKE $1', [`gtest-%-${stamp}-%@ug.edu.gh`]);
  await pool.end();
});

test('no existing account: creates one, Google-only (no password), always as a student', async () => {
  const email = nextEmail('new');
  const googleUid = nextGoogleUid('new');

  const user = await findOrCreateGoogleUser({ googleUid, email, name: 'Ama Mensah' });

  assert.equal(user.email, email);
  assert.equal(user.full_name, 'Ama Mensah');
  assert.equal(user.role, 'student', 'never trust a role from the identity — there is not one, but assert it anyway');

  const row = await rowFor(user.user_id);
  assert.equal(row.password_hash, null, 'Google-only: no password yet');
  assert.equal(row.google_uid, googleUid);
});

test('an existing password account with the same email is linked, not duplicated', async () => {
  const email = nextEmail('link');
  const googleUid = nextGoogleUid('link');
  const existingId = await createPasswordUser(email);

  const user = await findOrCreateGoogleUser({ googleUid, email, name: 'Someone Else Entirely' });

  assert.equal(user.user_id, existingId, 'the same row, not a new one');
  assert.equal(user.full_name, 'Existing Password User', 'the existing name is kept, not overwritten by the Google profile');

  const row = await rowFor(existingId);
  assert.equal(row.google_uid, googleUid, 'now linked');
  assert.notEqual(row.password_hash, null, 'the password still works too — linking adds a login method, it does not remove one');

  const { rows } = await pool.query('SELECT count(*)::int AS n FROM users WHERE LOWER(email) = LOWER($1)', [email]);
  assert.equal(rows[0].n, 1, 'still exactly one account for this email');
});

test('matching is case-insensitive, same as every other email lookup in this app', async () => {
  const email = nextEmail('case');
  const existingId = await createPasswordUser(email);

  const user = await findOrCreateGoogleUser({
    googleUid: nextGoogleUid('case'),
    email: email.toUpperCase(),
    name: 'X',
  });

  assert.equal(user.user_id, existingId);
});

test('calling it again with the same already-linked identity is a no-op, not an error', async () => {
  const email = nextEmail('idempotent');
  const googleUid = nextGoogleUid('idempotent');

  const first = await findOrCreateGoogleUser({ googleUid, email, name: 'Kojo' });
  const second = await findOrCreateGoogleUser({ googleUid, email, name: 'Kojo' });

  assert.equal(second.user_id, first.user_id);
  const { rows } = await pool.query('SELECT count(*)::int AS n FROM users WHERE google_uid = $1', [googleUid]);
  assert.equal(rows[0].n, 1);
});

test('the same Google account cannot end up linked to two different users', async () => {
  const googleUid = nextGoogleUid('conflict');
  const firstEmail = nextEmail('conflict-a');
  const secondEmail = nextEmail('conflict-b');

  await findOrCreateGoogleUser({ googleUid, email: firstEmail, name: 'First' });
  await createPasswordUser(secondEmail); // a second, unrelated account to try linking onto

  await assert.rejects(
    () => findOrCreateGoogleUser({ googleUid, email: secondEmail, name: 'Second' }),
    (err) => err.code === '23505' // unique_violation — the controller turns this into a 409
  );

  const { rows } = await pool.query('SELECT count(*)::int AS n FROM users WHERE google_uid = $1', [googleUid]);
  assert.equal(rows[0].n, 1, 'still linked to only the first account');
});

test('a missing display name falls back to something, not null, in the database', async () => {
  // findOrCreateGoogleUser trusts its caller for the name fallback (that is
  // googleIdTokenVerifier.js's job); this just checks a plain string is
  // accepted and stored as given, full_name being NOT NULL in the schema.
  const email = nextEmail('noname');
  const user = await findOrCreateGoogleUser({ googleUid: nextGoogleUid('noname'), email, name: email.split('@')[0] });

  assert.equal(user.full_name, email.split('@')[0]);
});
