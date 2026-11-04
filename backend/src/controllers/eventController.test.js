/**
 * Offline unit tests for events (no database):  npm test
 */
import '../testing/testEnv.js';
import { test, afterEach } from 'node:test';
import assert from 'node:assert/strict';
import {
  installFakeDb, pgError, callController, student, lecturer, otherLecturer, admin,
} from '../testing/fakeDb.js';
import {
  listEvents, createEvent, createEventSchema, registerForEvent, deleteEvent, cancelRegistration,
} from './eventController.js';

let db;
afterEach(() => db?.restore());

const row = {
  event_id: 3, title: 'Freshers Fair', description: 'Stalls', event_date: '2030-05-01T14:00:00.000Z',
  location: 'Great Hall', created_by: 21, club_name: 'Debate Union', attendee_count: '12', is_registered: true,
};

test('listEvents shapes rows for the app, with the attendee count as a number', async () => {
  db = installFakeDb(() => ({ rows: [row] }));
  const { status, body } = await callController(listEvents, { user: student, query: { upcoming: 'true' } });

  assert.equal(status, 200);
  assert.deepEqual(body.events, [{
    eventId: 3, title: 'Freshers Fair', description: 'Stalls', eventDate: '2030-05-01T14:00:00.000Z',
    location: 'Great Hall', clubName: 'Debate Union', attendeeCount: 12, isRegistered: true, createdBy: 21,
  }]);
  assert.deepEqual(db.calls[0].params, [7, true], 'the caller and the upcoming filter');
});

test('listEvents for a guest asks about no user, so nothing reads as registered', async () => {
  db = installFakeDb(() => ({ rows: [] }));
  await callController(listEvents, {});
  assert.deepEqual(db.calls[0].params, [null, false]);
});

test('createEvent records the caller as the creator and blanks missing optional fields', async () => {
  db = installFakeDb(() => ({ rows: [{ event_id: 40 }] }));
  const { status, body } = await callController(createEvent, {
    user: lecturer,
    body: { title: 'Hackathon', eventDate: '2030-06-01T09:00:00Z' },
  });

  assert.equal(status, 201);
  assert.deepEqual(body, { eventId: 40 });
  assert.match(db.calls[0].sql, /^INSERT INTO events/);
  assert.deepEqual(db.calls[0].params, ['Hackathon', null, '2030-06-01T09:00:00Z', null, null, 21]);
});

test('createEvent for a club that does not exist is a 400, not a server error', async () => {
  db = installFakeDb(() => { throw pgError('23503'); });
  const { status, body, error } = await callController(createEvent, {
    user: admin, body: { title: 'Ghost club night', eventDate: '2030-06-01T09:00:00Z', clubId: 999 },
  });
  assert.equal(status, 400);
  assert.deepEqual(body, { error: 'Unknown club' });
  assert.equal(error, undefined);
});

test('createEventSchema requires a real title and a full ISO date', () => {
  assert.equal(createEventSchema.safeParse({ title: 'Hackathon', eventDate: '2030-06-01T09:00:00Z' }).success, true);
  assert.equal(createEventSchema.safeParse({ title: 'Hi', eventDate: '2030-06-01T09:00:00Z' }).success, false);
  assert.equal(createEventSchema.safeParse({ title: 'Hackathon', eventDate: '1 June 2030' }).success, false);
});

test('registerForEvent: a first RSVP and a repeated tap both succeed, and say which', async () => {
  db = installFakeDb(() => ({ rowCount: 1 }));
  let result = await callController(registerForEvent, { user: student, params: { id: '3' } });
  assert.equal(result.status, 201);
  assert.deepEqual(result.body, { registered: true, alreadyRegistered: false });
  db.restore();

  db = installFakeDb(() => ({ rowCount: 0 }));
  result = await callController(registerForEvent, { user: student, params: { id: '3' } });
  assert.deepEqual(result.body, { registered: true, alreadyRegistered: true });
  assert.match(db.calls[0].sql, /ON CONFLICT \(user_id, event_id\) DO NOTHING/);
});

test('registerForEvent for a missing event is a 404', async () => {
  db = installFakeDb(() => { throw pgError('23503'); });
  const { status } = await callController(registerForEvent, { user: student, params: { id: '999' } });
  assert.equal(status, 404);
});

/** A database holding one event, created by [creatorId]. */
function oneEventCreatedBy(creatorId) {
  return installFakeDb((sql) => (sql.startsWith('SELECT created_by') ? { rows: [{ created_by: creatorId }] } : { rowCount: 1 }));
}

test('deleteEvent: a lecturer cannot delete another lecturer\'s event, and nothing is deleted', async () => {
  db = oneEventCreatedBy(lecturer.userId);
  const { status, body } = await callController(deleteEvent, { user: otherLecturer, params: { id: '3' } });

  assert.equal(status, 403);
  assert.deepEqual(body, { error: 'You can only delete events you created' });
  assert.equal(db.calls.filter((c) => c.sql.startsWith('DELETE')).length, 0);
});

test('deleteEvent: a lecturer can delete their own event', async () => {
  db = oneEventCreatedBy(lecturer.userId);
  const { status } = await callController(deleteEvent, { user: lecturer, params: { id: '3' } });
  assert.equal(status, 204);
  assert.deepEqual(db.calls[1], { sql: 'DELETE FROM events WHERE event_id = $1', params: [3] });
});

test('deleteEvent: an admin can delete anyone\'s event', async () => {
  db = oneEventCreatedBy(lecturer.userId);
  const { status } = await callController(deleteEvent, { user: admin, params: { id: '3' } });
  assert.equal(status, 204);
});

test('deleteEvent: a missing event or a malformed id is a 404', async () => {
  db = installFakeDb(() => ({ rows: [] }));
  assert.equal((await callController(deleteEvent, { user: admin, params: { id: '3' } })).status, 404);

  for (const id of ['abc', '0', '-1', '2.5']) {
    const before = db.calls.length;
    assert.equal((await callController(deleteEvent, { user: admin, params: { id } })).status, 404, id);
    assert.equal(db.calls.length, before, `no query for id "${id}"`);
  }
});

test('cancelRegistration: 204 when an RSVP was removed, 404 when there was none', async () => {
  db = installFakeDb(() => ({ rowCount: 1 }));
  assert.equal((await callController(cancelRegistration, { user: student, params: { id: '3' } })).status, 204);
  assert.deepEqual(db.calls[0].params, [7, '3'], 'only the caller\'s own RSVP');
  db.restore();

  db = installFakeDb(() => ({ rowCount: 0 }));
  assert.equal((await callController(cancelRegistration, { user: student, params: { id: '3' } })).status, 404);
});

test('an unexpected database failure is passed on to the error handler', async () => {
  const failure = new Error('connection lost');
  db = installFakeDb(() => { throw failure; });
  const { error } = await callController(listEvents, { user: student });
  assert.equal(error, failure);
});
