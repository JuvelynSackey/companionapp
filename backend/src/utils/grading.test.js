/**
 * Offline checks (no server, no database):  npm test
 *
 * Holds the pieces of the UG grading scale that live in different files to
 * docs/grading-scale-ug.json, which the smoke test (against the live API) and
 * the Flutter test (against the app's engine) also use.
 */
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import { calculateGpa, GRADE_POINTS, FAILING_LETTER } from './grading.js';

const read = (relative) => readFile(new URL(relative, import.meta.url), 'utf8');
const fixture = JSON.parse(await read('../../../docs/grading-scale-ug.json'));
const bandFor = (score) => fixture.scale.find((band) => score >= band.min);

/** Pulls `WHEN score >= N THEN 'X'` ... `ELSE 'F'` out of a SQL CASE expression. */
function scaleFromSql(sql) {
  const bands = [...sql.matchAll(/WHEN score >= (\d+) THEN '([A-Z+]+)'/g)].map((m) => ({
    min: Number(m[1]),
    letter: m[2],
  }));
  const fallback = sql.match(/ELSE '([A-Z+]+)'/);
  assert.ok(fallback, 'the CASE has an ELSE');
  return [...bands, { min: 0, letter: fallback[1] }];
}

const fixtureBands = fixture.scale.map(({ min, letter }) => ({ min, letter }));

test('schema.sql letter_grade CASE matches the fixture scale', async () => {
  assert.deepEqual(scaleFromSql(await read('../../db/schema.sql')), fixtureBands);
});

test('the migration letter_grade CASE matches the fixture scale', async () => {
  assert.deepEqual(scaleFromSql(await read('../../db/migrations/2026-09-ug-grading-scale.sql')), fixtureBands);
});

test('GRADE_POINTS has exactly the fixture letters and points', () => {
  assert.deepEqual(
    Object.entries(GRADE_POINTS).sort(),
    fixture.scale.map((b) => [b.letter, b.points]).sort(),
  );
});

test('every letter the SQL can produce has grade points (so none is silently skipped)', async () => {
  for (const { letter } of scaleFromSql(await read('../../db/schema.sql'))) {
    assert.notEqual(GRADE_POINTS[letter], undefined, `no grade points for ${letter}`);
  }
});

test('only F is failing', () => {
  assert.equal(FAILING_LETTER, 'F');
  assert.equal(fixture.scale.filter((b) => b.points === 0).map((b) => b.letter).join(), 'F');
});

for (const transcript of fixture.transcripts) {
  test(`transcript "${transcript.name}" gives GPA ${transcript.expectedGpa}`, () => {
    const rows = transcript.rows.map((r) => ({
      letter_grade: bandFor(r.score).letter,
      credit_hours: r.credits,
    }));
    assert.equal(calculateGpa(rows), transcript.expectedGpa);
  });
}

test('GPA is credit-weighted, not a plain average of the points', () => {
  // 4.0 x 3 credits + 3.0 x 2 credits = 18 / 5 = 3.6 (a plain average would be 3.5)
  assert.equal(calculateGpa([
    { letter_grade: 'A', credit_hours: 3 },
    { letter_grade: 'B', credit_hours: 2 },
  ]), 3.6);
});

test('GPA is null when there is nothing to average', () => {
  assert.equal(calculateGpa([]), null);
});

test('an unknown letter grade is an error rather than being skipped', () => {
  assert.throws(
    () => calculateGpa([{ letter_grade: 'A+', credit_hours: 3 }]),
    /No grade point defined for letter grade "A\+"/,
  );
});
