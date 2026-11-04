/**
 * Offline unit tests for campus locations (no database):  npm test
 */
import '../testing/testEnv.js';
import { test, afterEach } from 'node:test';
import assert from 'node:assert/strict';
import { installFakeDb, callController } from '../testing/fakeDb.js';
import { listLocations, listCategories } from './locationController.js';

let db;
afterEach(() => db?.restore());

test('listLocations returns coordinates as numbers (Postgres sends NUMERIC as text)', async () => {
  db = installFakeDb(() => ({
    rows: [{ location_id: 1, name: 'Balme Library', category: 'library', description: 'Main library', latitude: '5.6505', longitude: '-0.1870' }],
  }));
  const { status, body } = await callController(listLocations, {});

  assert.equal(status, 200);
  assert.deepEqual(body.locations, [
    { locationId: 1, name: 'Balme Library', category: 'library', description: 'Main library', latitude: 5.6505, longitude: -0.187 },
  ]);
});

test('listLocations passes no filter as nulls, and a filter as query parameters', async () => {
  db = installFakeDb(() => ({ rows: [] }));
  await callController(listLocations, {});
  assert.deepEqual(db.calls[0].params, [null, null]);

  await callController(listLocations, { query: { category: 'library', search: 'balme' } });
  assert.deepEqual(db.calls[1].params, ['library', 'balme']);
  assert.match(db.calls[1].sql, /name ILIKE '%' \|\| \$2 \|\| '%'/, 'the search text is a parameter, never spliced into the SQL');
});

test('listLocations rejects an unknown category before touching the database', async () => {
  db = installFakeDb(() => ({ rows: [] }));
  const { status, body } = await callController(listLocations, { query: { category: 'nightclub' } });
  assert.equal(status, 400);
  assert.match(body.error, /^category must be one of: lecture_hall, library/);
  assert.equal(db.calls.length, 0);
});

test('listCategories lists every category the filter accepts', async () => {
  const { body } = await callController(listCategories, {});
  assert.deepEqual(body.categories, ['lecture_hall', 'library', 'laboratory', 'cafeteria', 'office', 'hostel', 'other']);

  db = installFakeDb(() => ({ rows: [] }));
  for (const category of body.categories) {
    assert.equal((await callController(listLocations, { query: { category } })).status, 200, category);
  }
});
