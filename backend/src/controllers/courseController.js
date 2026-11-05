import { query } from '../config/db.js';

/** GET /api/courses - the course catalog, used to populate schedule/grade pickers. */
export async function listCourses(req, res, next) {
  try {
    const { rows } = await query(
      `SELECT course_id, course_code, course_title, lecturer_name, credit_hours
         FROM courses
        ORDER BY course_code`
    );

    return res.json({
      courses: rows.map((row) => ({
        courseId: row.course_id,
        courseCode: row.course_code,
        courseTitle: row.course_title,
        // The app expects a string; a course added without one must not break it.
        lecturer: row.lecturer_name ?? '',
        creditHours: row.credit_hours,
      })),
    });
  } catch (err) {
    return next(err);
  }
}
