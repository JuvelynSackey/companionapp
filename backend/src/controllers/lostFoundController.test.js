/**
 * Offline unit tests for the Lost & Found board (no database):  npm test
 */
import '../testing/testEnv.js';
import { test, afterEach } from 'node:test';
import assert from 'node:assert/strict';
import { installFakeDb, callController, student, admin } from '../testing/fakeDb.js';
import {
  listLostFound, createLostFound, createLostFoundSchema, markReturned, deleteLostFound,
} from './lostFoundController.js';

let db;
afterEach(() => db?.restore());

const otherStudent = { userId: 8, role: 'student' };
const row = {
  item_id: 4, kind: 'lost', title: 'Blue water bottle', description: 'Has a UG sticker', location: 'Balme Library',
  contact: '024 000 0000', status: 'open', created_at: '2026-11-04T10:00:00.000Z', posted_by: 7, posted_by_name: 'Ama Owusu',
};

test('a signed-in user sees who posted an item and how to reach them, and which are theirs', async () => {
  db = installFakeDb(() => ({ rows: [row] }));
  const { status, body } = await callController(listLostFound, { user: student });

  assert.equal(status, 200);
  assert.deepEqual(body.items, [{
    itemId: 4, kind: 'lost', title: 'Blue water bottle', description: 'Has a UG sticker', location: 'Balme Library',
    status: 'open', createdAt: '2026-11-04T10:00:00.000Z', postedBy: 'Ama Owusu', contact: '024 000 0000',
    isMine: true, canManage: true,
  }]);
  assert.match(db.calls[0].sql, /ORDER BY \(i\.status = 'open'\) DESC, i\.created_at DESC/, 'open items first, newest first');
});

test('a guest sees the items but no names or contact details', async () => {
  db = installFakeDb(() => ({ rows: [row] }));
  const { body } = await callController(listLostFound, {});
  const [item] = body.items;

  assert.equal(item.title, 'Blue water bottle');
  assert.equal(item.postedBy, null);
  assert.equal(item.contact, null);
  assert.equal(item.isMine, false);
  assert.equal(item.canManage, false);
});

test('someone else\'s item can be managed by an admin but not by another student', async () => {
  db = installFakeDb(() => ({ rows: [row] }));
  assert.equal((await callController(listLostFound, { user: otherStudent })).body.items[0].canManage, false);
  assert.equal((await callController(listLostFound, { user: admin })).body.items[0].canManage, true);
});

test('posting records the caller as the poster and blanks empty optional fields', async () => {
  db = installFakeDb(() => ({ rows: [{ item_id: 11 }] }));
  const { status, body } = await callController(createLostFound, {
    user: student,
    // Whatever the client says, the poster is the signed-in user.
    body: { kind: 'found', title: 'Calculator', location: '', posted_by: 1 },
  });

  assert.equal(status, 201);
  assert.deepEqual(body, { itemId: 11 });
  assert.deepEqual(db.calls[0].params, ['found', 'Calculator', null, null, null, 7]);
});

test('the schema requires a kind and a real title, and limits the free text', () => {
  assert.equal(createLostFoundSchema.safeParse({ kind: 'lost', title: 'Keys' }).success, true);
  assert.equal(createLostFoundSchema.safeParse({ kind: 'stolen', title: 'Keys' }).success, false);
  assert.equal(createLostFoundSchema.safeParse({ kind: 'lost', title: 'K' }).success, false);
  assert.equal(createLostFoundSchema.safeParse({ kind: 'lost', title: 'Keys', description: 'x'.repeat(1001) }).success, false);
});

/** A board holding one item, posted by [posterId]. */
function oneItemPostedBy(posterId) {
  return installFakeDb((sql) => (sql.startsWith('SELECT posted_by') ? { rows: [{ posted_by: posterId }] } : { rowCount: 1 }));
}

for (const [name, handler, statement] of [
  ['marking returned', markReturned, /^UPDATE lost_found_items SET status = 'returned'/],
  ['removing', deleteLostFound, /^DELETE FROM lost_found_items/],
]) {
  test(`${name}: only the poster or an admin, and another student changes nothing`, async () => {
    db = oneItemPostedBy(student.userId);
    const refused = await callController(handler, { user: otherStudent, params: { id: '4' } });
    assert.equal(refused.status, 403);
    assert.equal(db.calls.filter((c) => statement.test(c.sql)).length, 0);
    db.restore();

    for (const user of [student, admin]) {
      db = oneItemPostedBy(student.userId);
      const { status } = await callController(handler, { user, params: { id: '4' } });
      assert.equal(status, 204, user.role);
      assert.equal(db.calls.filter((c) => statement.test(c.sql)).length, 1);
      db.restore();
    }
  });

  test(`${name}: a missing item or a malformed id is a 404`, async () => {
    db = installFakeDb(() => ({ rows: [] }));
    assert.equal((await callController(handler, { user: admin, params: { id: '4' } })).status, 404);
    const before = db.calls.length;
    assert.equal((await callController(handler, { user: admin, params: { id: 'abc' } })).status, 404);
    assert.equal(db.calls.length, before, 'no query for a malformed id');
  });
}
