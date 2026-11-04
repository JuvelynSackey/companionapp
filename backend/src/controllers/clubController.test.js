/**
 * Offline unit tests for clubs (no database):  npm test
 */
import '../testing/testEnv.js';
import { test, afterEach } from 'node:test';
import assert from 'node:assert/strict';
import { installFakeDb, pgError, callController, student } from '../testing/fakeDb.js';
import { listClubs, joinClub, leaveClub } from './clubController.js';

let db;
afterEach(() => db?.restore());

test('listClubs shapes rows for the app, with the member count as a number', async () => {
  db = installFakeDb(() => ({
    rows: [{ club_id: 2, name: 'Computer Science Society', description: 'Talks', member_count: '31', is_member: true }],
  }));
  const { status, body } = await callController(listClubs, { user: student });

  assert.equal(status, 200);
  assert.deepEqual(body.clubs, [{ clubId: 2, name: 'Computer Science Society', description: 'Talks', memberCount: 31, isMember: true }]);
  assert.deepEqual(db.calls[0].params, [7]);
});

test('listClubs for a guest asks about no user, so no club reads as joined', async () => {
  db = installFakeDb(() => ({ rows: [] }));
  await callController(listClubs, {});
  assert.deepEqual(db.calls[0].params, [null]);
});

test('joinClub: joining and a repeated tap both succeed, and say which', async () => {
  db = installFakeDb(() => ({ rowCount: 1 }));
  let result = await callController(joinClub, { user: student, params: { id: '2' } });
  assert.equal(result.status, 201);
  assert.deepEqual(result.body, { joined: true, alreadyMember: false });
  assert.deepEqual(db.calls[0].params, [7, '2'], 'the caller joins, nobody else');
  db.restore();

  db = installFakeDb(() => ({ rowCount: 0 }));
  result = await callController(joinClub, { user: student, params: { id: '2' } });
  assert.deepEqual(result.body, { joined: true, alreadyMember: true });
});

test('joinClub for a club that does not exist is a 404', async () => {
  db = installFakeDb(() => { throw pgError('23503'); });
  const { status, body } = await callController(joinClub, { user: student, params: { id: '999' } });
  assert.equal(status, 404);
  assert.deepEqual(body, { error: 'Club not found' });
});

test('leaveClub: 204 when the membership was removed, 404 when there was none', async () => {
  db = installFakeDb(() => ({ rowCount: 1 }));
  assert.equal((await callController(leaveClub, { user: student, params: { id: '2' } })).status, 204);
  assert.deepEqual(db.calls[0].params, [7, '2'], 'only the caller\'s own membership');
  db.restore();

  db = installFakeDb(() => ({ rowCount: 0 }));
  const { status, body } = await callController(leaveClub, { user: student, params: { id: '2' } });
  assert.equal(status, 404);
  assert.deepEqual(body, { error: 'You are not a member of that club' });
});

test('an unexpected database failure is passed on to the error handler', async () => {
  const failure = new Error('connection lost');
  db = installFakeDb(() => { throw failure; });
  assert.equal((await callController(joinClub, { user: student, params: { id: '2' } })).error, failure);
});
