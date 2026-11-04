/**
 * Offline unit tests for quizzes (no database):  npm test
 */
import '../testing/testEnv.js';
import { test, afterEach } from 'node:test';
import assert from 'node:assert/strict';
import { installFakeDb, pgError, callController, student, lecturer, admin } from '../testing/fakeDb.js';
import {
  listQuizzes, getQuiz, createQuiz, createQuizSchema, submitAttempt, deleteQuiz,
} from './quizController.js';

let db;
afterEach(() => db?.restore());

const mcq = (questionText, options, correctOption) => ({ questionType: 'multiple_choice', questionText, options, correctOption });
const openEnded = (questionText, modelAnswer) => ({ questionType: 'open_ended', questionText, modelAnswer });

test('listQuizzes filters by course only when one is given', async () => {
  db = installFakeDb(() => ({
    rows: [{ quiz_id: 5, title: 'Week 3', source: 'manual', created_at: 'x', course_id: 1, course_code: 'DCIT 201', question_count: '4' }],
  }));
  const { body } = await callController(listQuizzes, {});
  assert.deepEqual(body.quizzes[0], { quizId: 5, title: 'Week 3', source: 'manual', createdAt: 'x', courseId: 1, courseCode: 'DCIT 201', questionCount: 4 });
  assert.doesNotMatch(db.calls[0].sql, /WHERE/);

  await callController(listQuizzes, { query: { courseId: '1' } });
  assert.match(db.calls[1].sql, /WHERE q\.course_id = \$1/);
  assert.deepEqual(db.calls[1].params, ['1']);
});

test('getQuiz never sends the answer key, even if the database row carried one', async () => {
  db = installFakeDb((sql) => (sql.includes('FROM quizzes')
    ? { rows: [{ quiz_id: 5, title: 'Week 3', source: 'manual', created_at: 'x', course_id: 1, course_code: 'DCIT 201', course_title: 'Mathematics' }] }
    : { rows: [{ question_id: 9, question_type: 'multiple_choice', question_text: '2 + 2?', options: ['3', '4'], order_index: 0, correct_option: 1, model_answer: 'four' }] }));

  const { status, body } = await callController(getQuiz, { user: student, params: { id: '5' } });

  assert.equal(status, 200);
  assert.deepEqual(body.questions, [{ questionId: 9, questionType: 'multiple_choice', questionText: '2 + 2?', options: ['3', '4'], orderIndex: 0 }]);
  assert.doesNotMatch(db.calls[1].sql, /correct_option|model_answer/, 'the key is not even selected');
});

test('getQuiz for a missing quiz is a 404', async () => {
  db = installFakeDb(() => ({ rows: [] }));
  assert.equal((await callController(getQuiz, { user: student, params: { id: '99' } })).status, 404);
});

test('createQuiz writes the quiz and its questions in order, in one transaction', async () => {
  db = installFakeDb((sql) => (sql.startsWith('INSERT INTO quizzes') ? { rows: [{ quiz_id: 12 }] } : { rowCount: 1 }));
  const { status, body } = await callController(createQuiz, {
    user: lecturer,
    body: {
      courseId: 1, title: 'Week 3', source: 'manual',
      questions: [mcq('2 + 2?', ['3', '4'], 1), openEnded('Define a set.', 'A collection of distinct objects.')],
    },
  });

  assert.equal(status, 201);
  assert.deepEqual(body, { quizId: 12 });
  assert.deepEqual(db.calls.map((c) => c.sql.split(' (')[0]), [
    'BEGIN', 'INSERT INTO quizzes', 'INSERT INTO quiz_questions', 'INSERT INTO quiz_questions', 'COMMIT',
  ]);
  const [quiz, first, second] = db.statements();
  assert.deepEqual(quiz.params, [1, 'Week 3', 'manual', 21], 'the caller is the author');
  assert.deepEqual(first.params, [12, 'multiple_choice', '2 + 2?', '["3","4"]', 1, null, 0]);
  assert.deepEqual(second.params, [12, 'open_ended', 'Define a set.', null, null, 'A collection of distinct objects.', 1]);
});

test('createQuiz rolls back when a question fails, and an unknown course is a 400', async () => {
  db = installFakeDb((sql) => {
    if (sql.startsWith('INSERT INTO quizzes')) throw pgError('23503');
    return { rowCount: 1 };
  });
  const { status, body } = await callController(createQuiz, {
    user: admin, body: { courseId: 999, title: 'Week 3', questions: [mcq('2 + 2?', ['3', '4'], 1)] },
  });

  assert.equal(status, 400);
  assert.deepEqual(body, { error: 'Unknown course' });
  assert.deepEqual(db.calls.map((c) => c.sql.split(' (')[0]), ['BEGIN', 'INSERT INTO quizzes', 'ROLLBACK']);
});

test('createQuizSchema: a question must carry the answer its type needs', () => {
  const quiz = (question) => ({ courseId: 1, title: 'Week 3', questions: [question] });
  assert.equal(createQuizSchema.safeParse(quiz(mcq('2 + 2?', ['3', '4'], 1))).success, true);
  assert.equal(createQuizSchema.safeParse(quiz(mcq('2 + 2?', ['3', '4'], 2))).success, false, 'answer index out of range');
  assert.equal(createQuizSchema.safeParse(quiz({ questionType: 'multiple_choice', questionText: '2 + 2?', options: ['3', '4'] })).success, false, 'no answer');
  assert.equal(createQuizSchema.safeParse(quiz({ questionType: 'open_ended', questionText: 'Define a set.' })).success, false, 'no model answer');
  assert.equal(createQuizSchema.safeParse({ courseId: 1, title: 'Week 3', questions: [] }).success, false, 'no questions');
});

/** A quiz with two multiple-choice questions (answers 1 and 0) and one open-ended. */
function quizWithAnswerKey() {
  return installFakeDb((sql) => {
    if (sql.startsWith('SELECT question_id')) {
      return { rows: [
        { question_id: 1, question_type: 'multiple_choice', correct_option: 1, model_answer: null },
        { question_id: 2, question_type: 'multiple_choice', correct_option: 0, model_answer: null },
        { question_id: 3, question_type: 'open_ended', correct_option: null, model_answer: 'A collection of distinct objects.' },
      ] };
    }
    if (sql.startsWith('INSERT INTO quiz_attempts ')) return { rows: [{ attempt_id: 77 }] };
    return { rowCount: 1 };
  });
}

test('submitAttempt marks multiple choice on the server; open-ended answers are not auto-marked', async () => {
  db = quizWithAnswerKey();
  const { status, body } = await callController(submitAttempt, {
    user: student,
    params: { id: '5' },
    body: { answers: [
      { questionId: 1, selectedOption: 1 },
      { questionId: 2, selectedOption: 1 },
      { questionId: 3, freeTextAnswer: 'A group of things' },
    ] },
  });

  assert.equal(status, 201);
  assert.equal(body.attemptId, 77);
  assert.equal(body.score, 50, 'one of two multiple-choice answers right');
  assert.equal(body.totalGraded, 2, 'the open-ended answer is not counted');
  assert.deepEqual(body.results, [
    { questionId: 1, isCorrect: true, correctOption: 1, modelAnswer: null },
    { questionId: 2, isCorrect: false, correctOption: 0, modelAnswer: null },
    { questionId: 3, isCorrect: null, correctOption: undefined, modelAnswer: 'A collection of distinct objects.' },
  ]);
  const attempt = db.statements().find((c) => c.sql.startsWith('INSERT INTO quiz_attempts '));
  assert.deepEqual(attempt.params, ['5', 7, 50, 2], 'saved for the caller with the same score');
});

test('submitAttempt ignores answers to questions that are not in the quiz', async () => {
  db = quizWithAnswerKey();
  const { body } = await callController(submitAttempt, {
    user: student, params: { id: '5' },
    body: { answers: [{ questionId: 1, selectedOption: 1 }, { questionId: 999, selectedOption: 0 }] },
  });
  assert.equal(body.score, 100);
  assert.deepEqual(body.results.map((r) => r.questionId), [1]);
});

test('submitAttempt with only open-ended answers has no score, rather than 0%', async () => {
  db = quizWithAnswerKey();
  const { body } = await callController(submitAttempt, {
    user: student, params: { id: '5' }, body: { answers: [{ questionId: 3, freeTextAnswer: 'A group of things' }] },
  });
  assert.equal(body.score, null);
  assert.equal(body.totalGraded, 0);
});

test('submitAttempt for a missing quiz is a 404 and saves nothing', async () => {
  db = installFakeDb(() => ({ rows: [] }));
  const { status } = await callController(submitAttempt, {
    user: student, params: { id: '99' }, body: { answers: [{ questionId: 1, selectedOption: 0 }] },
  });
  assert.equal(status, 404);
  assert.equal(db.calls.length, 1);
});

test('deleteQuiz: 204 when it existed, 404 when it did not', async () => {
  db = installFakeDb(() => ({ rowCount: 1 }));
  assert.equal((await callController(deleteQuiz, { user: admin, params: { id: '5' } })).status, 204);
  db.restore();
  db = installFakeDb(() => ({ rowCount: 0 }));
  assert.equal((await callController(deleteQuiz, { user: admin, params: { id: '5' } })).status, 404);
});
