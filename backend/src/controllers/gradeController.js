import { z } from 'zod';
import { query } from '../config/db.js';
import { calculateGpa, isPassing } from '../utils/grading.js';

/** Must match the DEFAULT on grades.semester in schema.sql. */
const CURRENT_SEMESTER = 'Semester 1 - 2025/2026';

export const upsertGradeSchema = z.object({
  userId: z.number().int().positive(),
  courseId: z.number().int().positive(),
  score: z.number().min(0).max(100),
  semester: z.string().trim().max(40).optional(),
});

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
      passed: isPassing(row.letter_grade),
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
