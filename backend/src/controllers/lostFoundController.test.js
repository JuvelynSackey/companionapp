/**
 * Offline unit tests for the Lost & Found board (no database):  npm test
 */
import '../testing/testEnv.js';
import { test, afterEach } from 'node:test';
import assert from 'node:assert/strict';
import { installFakeDb, callController, student, admin } from '../testing/fakeDb.js';
import {
  listLostFound, createLostFound, createLostFoundSchema, markReturned, deleteLostFound, lostFoundPhoto, photoType, MAX_PHOTO_BYTES,
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
    isMine: true, canManage: true, hasPhoto: false, possibleMatches: [],
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
  assert.deepEqual(body, { itemId: 11, possibleMatches: [] });
  assert.deepEqual(db.calls[0].params, ['found', 'Calculator', null, null, null, 7, null, null]);
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

test('the board lists, for each open post, the open posts of the other kind that may be the same item', async () => {
  const found = { ...row, item_id: 5, kind: 'found', title: 'Water bottle found', posted_by: 8, posted_by_name: 'Kofi' };
  const unrelated = { ...row, item_id: 6, kind: 'found', title: 'Calculator', posted_by: 8, posted_by_name: 'Kofi' };
  db = installFakeDb(() => ({ rows: [row, found, unrelated] }));
  const { body } = await callController(listLostFound, { user: student });

  assert.deepEqual(body.items[0].possibleMatches, [{ itemId: 5, title: 'Water bottle found' }]);
  assert.deepEqual(body.items[1].possibleMatches, [{ itemId: 4, title: 'Blue water bottle' }]);
  assert.deepEqual(body.items[2].possibleMatches, []);
});

test('posting a match returns it and pushes to the other poster only, never the caller', async () => {
  const lostByOther = { item_id: 4, kind: 'lost', title: 'Blue water bottle', location: 'Balme Library', status: 'open', posted_by: 8 };
  const lostByMe = { item_id: 3, kind: 'lost', title: 'Water bottle', location: null, status: 'open', posted_by: 7 };
  db = installFakeDb((sql) => {
    if (sql.startsWith('INSERT INTO lost_found_items')) return { rows: [{ item_id: 12 }] };
    if (sql.includes('FROM lost_found_items')) return { rows: [lostByOther, lostByMe] };
    return { rows: [] };
  });
  const { status, body } = await callController(createLostFound, {
    user: student,
    body: { kind: 'found', title: 'Water bottle', location: 'Balme Library' },
  });

  assert.equal(status, 201);
  assert.deepEqual(body.possibleMatches.map((m) => m.itemId), [4, 3], 'the shared place ranks the first one higher');
  // The push runs in the background; let it reach the token lookup.
  for (let i = 0; i < 20 && !db.calls.some((c) => c.sql.includes('ANY($1::int[])')); i++) {
    await new Promise((resolve) => setTimeout(resolve, 10));
  }
  const lookup = db.calls.find((c) => c.sql.includes('ANY($1::int[])'));
  assert.ok(lookup, "looked up the other poster's devices");
  assert.deepEqual(lookup.params, [[8]]);
});

const jpeg = Buffer.concat([Buffer.from([0xff, 0xd8, 0xff, 0xe0]), Buffer.alloc(100)]);

test('a JPEG or PNG photo is stored with its type; anything else is refused', async () => {
  db = installFakeDb(() => ({ rows: [{ item_id: 20 }] }));
  const ok = await callController(createLostFound, {
    user: student, body: { kind: 'found', title: 'Umbrella', photo: jpeg.toString('base64') },
  });
  assert.equal(ok.status, 201);
  const insert = db.calls.find((c) => c.sql.startsWith('INSERT INTO lost_found_items'));
  assert.ok(Buffer.isBuffer(insert.params[6]) && insert.params[6].equals(jpeg));
  assert.equal(insert.params[7], 'image/jpeg');

  const notImage = await callController(createLostFound, {
    user: student, body: { kind: 'found', title: 'Umbrella', photo: Buffer.from('<html>').toString('base64') },
  });
  assert.equal(notImage.status, 400);
  assert.equal(photoType(Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a, 0])), 'image/png');
});

test('a photo over 2 MB is refused', async () => {
  db = installFakeDb(() => ({ rows: [{ item_id: 21 }] }));
  const big = Buffer.concat([jpeg, Buffer.alloc(MAX_PHOTO_BYTES)]);
  const res = await callController(createLostFound, { user: student, body: { kind: 'lost', title: 'Bag', photo: big.toString('base64') } });
  assert.equal(res.status, 400);
  assert.equal(db.calls.filter((c) => c.sql.startsWith('INSERT')).length, 0);
});

test('the board says which posts have a photo, without sending the photo itself', async () => {
  db = installFakeDb(() => ({ rows: [{ ...row, has_photo: true }] }));
  const { body } = await callController(listLostFound, {});
  assert.equal(body.items[0].hasPhoto, true);
  assert.match(db.calls[0].sql, /\(i\.photo IS NOT NULL\) AS has_photo/);
  assert.doesNotMatch(db.calls[0].sql, /i\.photo,/);
});

test('the photo is served with its type, and a missing one is a 404', async () => {
  db = installFakeDb(() => ({ rows: [{ photo: jpeg, photo_type: 'image/jpeg' }] }));
  const res = await callController(lostFoundPhoto, { params: { id: '20' } });
  assert.equal(res.status, 200);
  assert.equal(res.headers['Content-Type'], 'image/jpeg');
  db.restore();
  db = installFakeDb(() => ({ rows: [{ photo: null }] }));
  assert.equal((await callController(lostFoundPhoto, { params: { id: '20' } })).status, 404);
  assert.equal((await callController(lostFoundPhoto, { params: { id: 'x' } })).status, 404);
});
