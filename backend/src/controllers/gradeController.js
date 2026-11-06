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
      `SELECT g.grade_id, g.score, g.letter_grade, g.semester, g.self_reported,
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
      selfReported: row.self_reported === true,
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

/** "dcit418", "Dcit 418" -> "DCIT 418", the printed form used everywhere. */
export function normaliseCourseCode(raw) {
  const code = raw.trim().replace(/\s+/g, ' ').toUpperCase();
  const match = /^([A-Z]+) ?(\d+[A-Z]?)$/.exec(code);
  return match ? `${match[1]} ${match[2]}` : code;
}

export const addMyGradeSchema = z.object({
  courseCode: z.string().trim().min(3).max(20),
  courseTitle: z.string().trim().min(2).max(160),
  creditHours: z.number().int().min(1).max(6),
  score: z.number().min(0).max(100),
  semester: z.string().trim().min(3).max(40),
});

/**
 * POST /api/grades/mine - any signed-in user records one of their own
 * results. Stored as self_reported, so it is never mistaken for an official
 * grade, and it can never overwrite one (that answers 409).
 */
export async function addMyGrade(req, res, next) {
  const { courseTitle, creditHours, score, semester } = req.body;
  const courseCode = normaliseCourseCode(req.body.courseCode);

  try {
    // Reuse the course if it exists; the shared course record is not changed.
    const course = await query(
      `WITH inserted AS (
         INSERT INTO courses (course_code, course_title, lecturer_name, credit_hours)
         VALUES ($1, $2, '', $3)
         ON CONFLICT (course_code) DO NOTHING
         RETURNING course_id
       )
       SELECT course_id FROM inserted
       UNION ALL
       SELECT course_id FROM courses WHERE course_code = $1
       LIMIT 1`,
      [courseCode, courseTitle, creditHours]
    );
    const courseId = course.rows[0].course_id;

    const { rows } = await query(
      `INSERT INTO grades (user_id, course_id, score, semester, self_reported)
       VALUES ($1, $2, $3, $4, true)
       ON CONFLICT (user_id, course_id, semester)
       DO UPDATE SET score = EXCLUDED.score, recorded_at = now()
       WHERE grades.self_reported
       RETURNING grade_id, letter_grade`,
      [req.user.userId, courseId, score, semester]
    );
    if (rows.length === 0) {
      return res.status(409).json({ error: 'There is already an official grade for this course and semester.' });
    }
    return res.status(201).json({ gradeId: rows[0].grade_id, letterGrade: rows[0].letter_grade, courseCode });
  } catch (err) {
    return next(err);
  }
}

/** DELETE /api/grades/mine/:id - only the student's own self-entered results. */
export async function deleteMyGrade(req, res, next) {
  const gradeId = Number(req.params.id);
  if (!Number.isInteger(gradeId) || gradeId <= 0) return res.status(404).json({ error: 'Result not found' });
  try {
    const { rowCount } = await query(
      'DELETE FROM grades WHERE grade_id = $1 AND user_id = $2 AND self_reported',
      [gradeId, req.user.userId]
    );
    return rowCount === 0 ? res.status(404).json({ error: 'Result not found' }) : res.status(204).send();
  } catch (err) {
    return next(err);
  }
}
