/**
 * Offline unit tests for students' own, self-entered results:  npm test
 */
import '../testing/testEnv.js';
import { test, afterEach } from 'node:test';
import assert from 'node:assert/strict';
import { installFakeDb, callController, student } from '../testing/fakeDb.js';
import { addMyGrade, addMyGradeSchema, deleteMyGrade, normaliseCourseCode, listGrades } from './gradeController.js';

let db;
afterEach(() => db?.restore());

const body = { courseCode: 'dcit418', courseTitle: 'Systems and Network Security', creditHours: 3, score: 77, semester: 'Semester 2 - 2025/2026' };

test('course codes are stored in the printed form', () => {
  assert.equal(normaliseCourseCode(' dcit418 '), 'DCIT 418');
  assert.equal(normaliseCourseCode('Dcit  418'), 'DCIT 418');
  assert.equal(normaliseCourseCode('UGRC 150'), 'UGRC 150');
});

test('a student records a result for themselves, marked self-reported', async () => {
  db = installFakeDb((sql) => (sql.includes('INSERT INTO courses') ? { rows: [{ course_id: 9 }] } : { rows: [{ grade_id: 31, letter_grade: 'B+' }] }));
  const res = await callController(addMyGrade, { user: student, body: { ...body, userId: 1 } });

  assert.equal(res.status, 201);
  assert.deepEqual(res.body, { gradeId: 31, letterGrade: 'B+', courseCode: 'DCIT 418' });
  const insert = db.calls.find((c) => c.sql.startsWith('INSERT INTO grades'));
  assert.deepEqual(insert.params, [7, 9, 77, 'Semester 2 - 2025/2026'], 'always the caller, whatever the body says');
  assert.match(insert.sql, /self_reported\) VALUES \(\$1, \$2, \$3, \$4, true\)/);
  assert.match(insert.sql, /WHERE grades\.self_reported/, 'never overwrites an official grade');
});

test('an official grade for the same course and semester is not overwritten (409)', async () => {
  db = installFakeDb((sql) => (sql.includes('INSERT INTO courses') ? { rows: [{ course_id: 9 }] } : { rows: [] }));
  assert.equal((await callController(addMyGrade, { user: student, body })).status, 409);
});

test('only the student\'s own self-entered results can be deleted', async () => {
  db = installFakeDb(() => ({ rows: [], rowCount: 1 }));
  assert.equal((await callController(deleteMyGrade, { user: student, params: { id: '31' } })).status, 204);
  assert.match(db.calls[0].sql, /grade_id = \$1 AND user_id = \$2 AND self_reported/);
  assert.deepEqual(db.calls[0].params, [31, 7]);
  db.restore();
  db = installFakeDb(() => ({ rows: [], rowCount: 0 }));
  assert.equal((await callController(deleteMyGrade, { user: student, params: { id: '31' } })).status, 404);
  assert.equal((await callController(deleteMyGrade, { user: student, params: { id: 'x' } })).status, 404);
});

test('the grade list says which results the student entered', async () => {
  db = installFakeDb(() => ({ rows: [{ grade_id: 1, score: 77, letter_grade: 'B+', semester: 'S', self_reported: true, course_code: 'DCIT 418', course_title: 'T', credit_hours: 3 }] }));
  const { body: out } = await callController(listGrades, { user: student });
  assert.equal(out.grades[0].selfReported, true);
});

test('the schema checks credits, marks and the course fields', () => {
  assert.equal(addMyGradeSchema.safeParse(body).success, true);
  assert.equal(addMyGradeSchema.safeParse({ ...body, creditHours: 9 }).success, false);
  assert.equal(addMyGradeSchema.safeParse({ ...body, score: 101 }).success, false);
  assert.equal(addMyGradeSchema.safeParse({ ...body, courseCode: 'X' }).success, false);
});
