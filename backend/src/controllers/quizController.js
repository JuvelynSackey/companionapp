import { z } from 'zod';
import { query, withTransaction } from '../config/db.js';

const questionSchema = z
  .object({
    questionType: z.enum(['multiple_choice', 'open_ended']),
    questionText: z.string().trim().min(3),
    options: z.array(z.string().trim().min(1)).min(2).max(6).optional(),
    correctOption: z.number().int().min(0).optional(),
    modelAnswer: z.string().trim().min(1).optional(),
  })
  .refine(
    (q) => q.questionType !== 'multiple_choice' || (q.options && q.correctOption !== undefined && q.correctOption < q.options.length),
    { message: 'multiple_choice questions require options and a correctOption index within range' }
  )
  .refine((q) => q.questionType !== 'open_ended' || Boolean(q.modelAnswer), {
    message: 'open_ended questions require a modelAnswer',
  });

export const createQuizSchema = z.object({
  courseId: z.number().int().positive(),
  title: z.string().trim().min(3).max(160),
  source: z.enum(['manual', 'past_paper']).default('manual'),
  questions: z.array(questionSchema).min(1).max(50),
});

export const submitAttemptSchema = z.object({
  answers: z
    .array(
      z.object({
        questionId: z.number().int().positive(),
        selectedOption: z.number().int().min(0).optional(),
        freeTextAnswer: z.string().trim().optional(),
      })
    )
    .min(1),
});

function questionShapeNoAnswer(row) {
  return {
    questionId: row.question_id,
    questionType: row.question_type,
    questionText: row.question_text,
    options: row.options,
    orderIndex: row.order_index,
  };
}

/** GET /api/quizzes?courseId= */
export async function listQuizzes(req, res, next) {
  const { courseId } = req.query;

  try {
    const params = [];
    let where = '';
    if (courseId) {
      params.push(courseId);
      where = 'WHERE q.course_id = $1';
    }

    const { rows } = await query(
      `SELECT q.quiz_id, q.title, q.source, q.created_at,
              c.course_id, c.course_code,
              COUNT(qq.question_id) AS question_count
         FROM quizzes q
         JOIN courses c ON c.course_id = q.course_id
         LEFT JOIN quiz_questions qq ON qq.quiz_id = q.quiz_id
         ${where}
        GROUP BY q.quiz_id, c.course_id, c.course_code
        ORDER BY q.created_at DESC`,
      params
    );

    return res.json({
      quizzes: rows.map((row) => ({
        quizId: row.quiz_id,
        title: row.title,
        source: row.source,
        createdAt: row.created_at,
        courseId: row.course_id,
        courseCode: row.course_code,
        questionCount: Number(row.question_count),
      })),
    });
  } catch (err) {
    return next(err);
  }
}

/**
 * GET /api/quizzes/:id
 * Answer key deliberately stripped here (no correctOption/modelAnswer) —
 * see submitAttempt, the only place that reveals it.
 */
export async function getQuiz(req, res, next) {
  try {
    const { rows: quizRows } = await query(
      `SELECT q.quiz_id, q.title, q.source, q.created_at, c.course_id, c.course_code, c.course_title
         FROM quizzes q
         JOIN courses c ON c.course_id = q.course_id
        WHERE q.quiz_id = $1`,
      [req.params.id]
    );

    if (quizRows.length === 0) {
      return res.status(404).json({ error: 'Quiz not found' });
    }

    const { rows: questionRows } = await query(
      `SELECT question_id, question_type, question_text, options, order_index
         FROM quiz_questions
        WHERE quiz_id = $1
        ORDER BY order_index, question_id`,
      [req.params.id]
    );

    const quiz = quizRows[0];
    return res.json({
      quizId: quiz.quiz_id,
      title: quiz.title,
      source: quiz.source,
      createdAt: quiz.created_at,
      courseId: quiz.course_id,
      courseCode: quiz.course_code,
      courseTitle: quiz.course_title,
      questions: questionRows.map(questionShapeNoAnswer),
    });
  } catch (err) {
    return next(err);
  }
}

/**
 * POST /api/quizzes - lecturer/admin only.
 * Manual authoring and past-paper-derived quizzes hit this same endpoint —
 * by the time a submission reaches the backend it's just structured data
 * regardless of origin (see mobile's import_past_paper_screen.dart, which
 * does PDF text extraction + AI structuring entirely client-side and only
 * ever sends the final, human-reviewed question set here).
 */
export async function createQuiz(req, res, next) {
  const { courseId, title, source, questions } = req.body;

  try {
    const quizId = await withTransaction(async (client) => {
      const { rows } = await client.query(
        `INSERT INTO quizzes (course_id, title, source, created_by)
         VALUES ($1, $2, $3, $4)
         RETURNING quiz_id`,
        [courseId, title, source ?? 'manual', req.user.userId]
      );
      const newQuizId = rows[0].quiz_id;

      let orderIndex = 0;
      for (const question of questions) {
        await client.query(
          `INSERT INTO quiz_questions
             (quiz_id, question_type, question_text, options, correct_option, model_answer, order_index)
           VALUES ($1, $2, $3, $4, $5, $6, $7)`,
          [
            newQuizId,
            question.questionType,
            question.questionText,
            question.questionType === 'multiple_choice' ? JSON.stringify(question.options) : null,
            question.questionType === 'multiple_choice' ? question.correctOption : null,
            question.modelAnswer ?? null,
            orderIndex++,
          ]
        );
      }

      return newQuizId;
    });

    return res.status(201).json({ quizId });
  } catch (err) {
    if (err.code === '23503') {
      return res.status(400).json({ error: 'Unknown course' });
    }
    return next(err);
  }
}

/**
 * POST /api/quizzes/:id/attempts - any authenticated user.
 * Grades multiple_choice answers server-side; open_ended answers are never
 * auto-graded (isCorrect: null), just returned alongside the model answer
 * for the student to self-mark. This response is the only place the answer
 * key is revealed.
 */
export async function submitAttempt(req, res, next) {
  const quizId = req.params.id;
  const { answers } = req.body;

  try {
    const { rows: questionRows } = await query(
      `SELECT question_id, question_type, correct_option, model_answer
         FROM quiz_questions
        WHERE quiz_id = $1`,
      [quizId]
    );

    if (questionRows.length === 0) {
      return res.status(404).json({ error: 'Quiz not found' });
    }

    const questionsById = new Map(questionRows.map((q) => [q.question_id, q]));

    const graded = answers
      .filter((answer) => questionsById.has(answer.questionId))
      .map((answer) => {
        const question = questionsById.get(answer.questionId);
        const isMcq = question.question_type === 'multiple_choice';
        return {
          questionId: answer.questionId,
          selectedOption: answer.selectedOption ?? null,
          freeTextAnswer: answer.freeTextAnswer ?? null,
          isCorrect: isMcq ? answer.selectedOption === question.correct_option : null,
          isMcq,
          correctOption: question.correct_option,
          modelAnswer: question.model_answer,
        };
      });

    const mcqAnswers = graded.filter((g) => g.isMcq);
    const gradedCount = mcqAnswers.length;
    const correctCount = mcqAnswers.filter((g) => g.isCorrect).length;
    const score = gradedCount > 0 ? Number(((correctCount / gradedCount) * 100).toFixed(2)) : null;

    const attemptId = await withTransaction(async (client) => {
      const { rows } = await client.query(
        `INSERT INTO quiz_attempts (quiz_id, user_id, score, total_graded)
         VALUES ($1, $2, $3, $4)
         RETURNING attempt_id`,
        [quizId, req.user.userId, score, gradedCount]
      );
      const newAttemptId = rows[0].attempt_id;

      for (const g of graded) {
        await client.query(
          `INSERT INTO quiz_attempt_answers (attempt_id, question_id, selected_option, free_text_answer, is_correct)
           VALUES ($1, $2, $3, $4, $5)`,
          [newAttemptId, g.questionId, g.selectedOption, g.freeTextAnswer, g.isCorrect]
        );
      }

      return newAttemptId;
    });

    return res.status(201).json({
      attemptId,
      score,
      totalGraded: gradedCount,
      results: graded.map((g) => ({
        questionId: g.questionId,
        isCorrect: g.isCorrect,
        correctOption: g.isMcq ? g.correctOption : undefined,
        modelAnswer: g.modelAnswer,
      })),
    });
  } catch (err) {
    return next(err);
  }
}

/** DELETE /api/quizzes/:id - admin only. */
export async function deleteQuiz(req, res, next) {
  try {
    const { rowCount } = await query('DELETE FROM quizzes WHERE quiz_id = $1', [req.params.id]);

    if (rowCount === 0) {
      return res.status(404).json({ error: 'Quiz not found' });
    }

    return res.status(204).send();
  } catch (err) {
    return next(err);
  }
}
