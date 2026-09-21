/**
 * Tests the real SQL behind device tokens and the push preference, against the
 * configured database:   npm run test:db
 *
 * Not part of `npm test` (which needs no database). It creates two throwaway
 * users and removes them, and everything they own, when it finishes.
 */
import { test, before, after } from 'node:test';
import assert from 'node:assert/strict';
import { pool } from '../config/db.js';
import {
  registerToken, unregisterToken, countTokensForUser, tokensForAllEnabledUsers, removeTokens,
  getPushEnabled, setPushEnabled, MAX_TOKENS_PER_USER,
} from './deviceTokenStore.js';

const stamp = Date.now();
const email = (name) => `db-test-${name}-${stamp}@ug.edu.gh`;
const token = (name) => `dbtest-${stamp}-${name}-`.padEnd(40, 'x');
let alice;
let bob;

async function createUser(name) {
  const { rows } = await pool.query(
    `INSERT INTO users (full_name, email, password_hash) VALUES ($1, $2, 'not-a-real-hash') RETURNING user_id`,
    [`DB Test ${name}`, email(name)]
  );
  return rows[0].user_id;
}

before(async () => {
  alice = await createUser('alice');
  bob = await createUser('bob');
});

after(async () => {
  // device_tokens rows go with their users (ON DELETE CASCADE).
  await pool.query('DELETE FROM users WHERE email LIKE $1', [`db-test-%-${stamp}@ug.edu.gh`]);
  await pool.end();
});

test('a registered token is counted, and registering it again does not duplicate it', async () => {
  await registerToken(alice, token('a1'), 'android');
  await registerToken(alice, token('a1'), 'android');
  assert.equal(await countTokensForUser(alice), 1);
});

test('the same token registered by another user moves to them', async () => {
  await registerToken(alice, token('shared'), 'android');
  await registerToken(bob, token('shared'), 'ios');

  const { rows } = await pool.query('SELECT user_id, platform FROM device_tokens WHERE token = $1', [token('shared')]);
  assert.equal(rows.length, 1, 'still exactly one row');
  assert.equal(rows[0].user_id, bob);
  assert.equal(rows[0].platform, 'ios', 'and the platform is updated');
});

test('unregistering removes only the caller\'s own token', async () => {
  await registerToken(alice, token('mine'), 'android');

  assert.equal(await unregisterToken(bob, token('mine')), false, 'not bob\'s to remove');
  assert.equal(await unregisterToken(alice, token('mine')), true);
  assert.equal(await unregisterToken(alice, token('mine')), false, 'already gone');
});

test('the fan-out list includes users with push on and excludes users who switched it off', async () => {
  await registerToken(alice, token('on'), 'android');
  await registerToken(bob, token('off'), 'android');
  await setPushEnabled(bob, false);

  const sendable = await tokensForAllEnabledUsers();

  assert.ok(sendable.includes(token('on')));
  assert.ok(!sendable.includes(token('off')), 'bob turned push off');

  await setPushEnabled(bob, true);
  assert.ok((await tokensForAllEnabledUsers()).includes(token('off')), 'and back on');
});

test('the preference defaults to on, and reads null for a user that does not exist', async () => {
  assert.equal(await getPushEnabled(alice), true);
  assert.equal(await getPushEnabled(-1), null);
  assert.equal(await setPushEnabled(-1, false), false);
});

test('an account keeps only its newest 10 tokens', async () => {
  // The literal 10 is deliberate: the policy is "10", not "whatever the constant says".
  assert.equal(MAX_TOKENS_PER_USER, 10);
  const carol = await createUser('carol');
  for (let i = 0; i < 13; i++) await registerToken(carol, token(`carol${i}`), 'android');

  assert.equal(await countTokensForUser(carol), 10);
  const { rows } = await pool.query('SELECT token FROM device_tokens WHERE user_id = $1', [carol]);
  const kept = rows.map((r) => r.token);
  assert.ok(!kept.includes(token('carol0')), 'the oldest was dropped');
  assert.ok(!kept.includes(token('carol2')), 'so were the next two oldest');
  assert.ok(kept.includes(token('carol3')) && kept.includes(token('carol12')), 'the newest 10 (3..12) were kept');
});

test('removeTokens deletes exactly the ones named, and nothing for an empty list', async () => {
  await registerToken(alice, token('rm1'), 'android');
  await registerToken(alice, token('rm2'), 'android');
  await registerToken(alice, token('keep'), 'android');

  assert.equal(await removeTokens([token('rm1'), token('rm2'), token('does-not-exist')]), 2);
  assert.equal(await removeTokens([]), 0);
  assert.ok((await tokensForAllEnabledUsers()).includes(token('keep')));
});

test('deleting a user removes their tokens with them', async () => {
  const dave = await createUser('dave');
  await registerToken(dave, token('dave1'), 'android');

  await pool.query('DELETE FROM users WHERE user_id = $1', [dave]);

  assert.ok(!(await tokensForAllEnabledUsers()).includes(token('dave1')));
});
