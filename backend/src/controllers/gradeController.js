import { z } from 'zod';
import { query } from '../config/db.js';

/**
 * Grade points for the scale printed in the proposal's Grades mock-up.
 * If the scale in schema.sql changes, change this to match — see
 * docs/schema-notes.md, "Open question: the grading scale".
 */
const GRADE_POINTS = {
  'A+': 4.0,
  A: 4.0,
  'B+': 3.5,
  B: 3.0,
  C: 2.0,
  F: 0.0,
};

/** Must match the DEFAULT on grades.semester in schema.sql. */
const CURRENT_SEMESTER = 'Semester 1 - 2025/2026';

export const upsertGradeSchema = z.object({
  userId: z.number().int().positive(),
  courseId: z.number().int().positive(),
  score: z.number().min(0).max(100),
  semester: z.string().trim().max(40).optional(),
});

/**
 * GPA weighted by credit hours, which is how a university actually computes
 * it — a 3-credit course should move the average more than a 2-credit one.
 */
function calculateGpa(rows) {
  let points = 0;
  let credits = 0;

  for (const row of rows) {
    const gradePoint = GRADE_POINTS[row.letter_grade];
    if (gradePoint === undefined) continue;
    points += gradePoint * row.credit_hours;
    credits += row.credit_hours;
  }

  if (credits === 0) return null;
  return Number((points / credits).toFixed(2));
}

/** GET /api/grades - the student's own results plus a summary. */
export async function listGrades(req, res, next) {
  try {
    const { rows } = await query(
      `SELECT g.grade_id, g.score, g.letter_grade, g.semester,
              c.course_code, c.course_title, c.credit_hours
         FROM grades g
         JOIN courses c ON c.course_id = g.course_id
        WHERE g.user_id = $1
        ORDER BY c.course_code`,
      [req.user.userId]
    );

    const grades = rows.map((row) => ({
      gradeId: row.grade_id,
      courseCode: row.course_code,
      courseTitle: row.course_title,
      creditHours: row.credit_hours,
      score: Number(row.score),
      letterGrade: row.letter_grade,
      semester: row.semester,
      passed: row.letter_grade !== 'F',
    }));

    const averageScore = grades.length
      ? Number((grades.reduce((sum, g) => sum + g.score, 0) / grades.length).toFixed(1))
      : null;

    return res.json({
      grades,
      summary: {
        gpa: calculateGpa(rows),
        averageScore,
        courseCount: grades.length,
      },
    });
  } catch (err) {
    return next(err);
  }
}

/**
 * POST /api/grades - admin only.
 * Upserts so re-entering a mark corrects it instead of failing on the
 * (user, course, semester) unique constraint.
 */
export async function upsertGrade(req, res, next) {
  const { userId, courseId, score, semester } = req.body;

  try {
    const { rows } = await query(
      `INSERT INTO grades (user_id, course_id, score, semester)
       VALUES ($1, $2, $3, $4)
       ON CONFLICT (user_id, course_id, semester)
       DO UPDATE SET score = EXCLUDED.score, recorded_at = now()
       RETURNING grade_id, score, letter_grade`,
      [userId, courseId, score, semester ?? CURRENT_SEMESTER]
    );

    const row = rows[0];
    return res.status(201).json({
      gradeId: row.grade_id,
      score: Number(row.score),
      letterGrade: row.letter_grade,
    });
  } catch (err) {
    if (err.code === '23503') {
      return res.status(400).json({ error: 'Unknown course or user' });
    }
    return next(err);
  }
}
