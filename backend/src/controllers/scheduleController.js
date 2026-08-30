import { z } from 'zod';
import { query } from '../config/db.js';

const DAY_NAMES = ['', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

export const createScheduleSchema = z.object({
  courseId: z.number().int().positive(),
  dayOfWeek: z.number().int().min(1).max(7),
  startTime: z.string().regex(/^\d{2}:\d{2}$/, 'Use HH:MM, 24-hour'),
  endTime: z.string().regex(/^\d{2}:\d{2}$/, 'Use HH:MM, 24-hour'),
  room: z.string().trim().max(80).optional(),
});

function shapeEntry(row) {
  return {
    scheduleId: row.schedule_id,
    courseCode: row.course_code,
    courseTitle: row.course_title,
    lecturer: row.lecturer_name,
    dayOfWeek: row.day_of_week,
    dayName: DAY_NAMES[row.day_of_week],
    startTime: row.start_time,
    endTime: row.end_time,
    room: row.room,
  };
}

const SELECT_SCHEDULE = `
  SELECT s.schedule_id, s.day_of_week, s.room,
         to_char(s.start_time, 'HH24:MI') AS start_time,
         to_char(s.end_time,   'HH24:MI') AS end_time,
         c.course_code, c.course_title, c.lecturer_name
    FROM schedules s
    JOIN courses c ON c.course_id = s.course_id
   WHERE s.user_id = $1`;

/**
 * GET /api/schedule            -> the student's full week
 * GET /api/schedule?day=5      -> a single day
 */
export async function listSchedule(req, res, next) {
  const dayParam = req.query.day;

  try {
    let rows;

    if (dayParam !== undefined) {
      const day = Number(dayParam);
      if (!Number.isInteger(day) || day < 1 || day > 7) {
        return res.status(400).json({ error: 'day must be an integer from 1 (Monday) to 7' });
      }
      ({ rows } = await query(
        `${SELECT_SCHEDULE} AND s.day_of_week = $2 ORDER BY s.start_time`,
        [req.user.userId, day]
      ));
    } else {
      ({ rows } = await query(
        `${SELECT_SCHEDULE} ORDER BY s.day_of_week, s.start_time`,
        [req.user.userId]
      ));
    }

    return res.json({ schedule: rows.map(shapeEntry) });
  } catch (err) {
    return next(err);
  }
}

/** GET /api/schedule/today - drives the dashboard's "Today's classes" card. */
export async function listToday(req, res, next) {
  // PostgreSQL's ISODOW gives 1=Monday..7=Sunday, matching day_of_week.
  try {
    const { rows } = await query(
      `${SELECT_SCHEDULE}
         AND s.day_of_week = EXTRACT(ISODOW FROM CURRENT_DATE)
       ORDER BY s.start_time`,
      [req.user.userId]
    );

    return res.json({ schedule: rows.map(shapeEntry) });
  } catch (err) {
    return next(err);
  }
}

/** POST /api/schedule - admin only, per the proposal's "Update schedules". */
export async function createScheduleEntry(req, res, next) {
  const { courseId, dayOfWeek, startTime, endTime, room } = req.body;
  const targetUserId = req.body.userId ?? req.user.userId;

  if (endTime <= startTime) {
    return res.status(400).json({ error: 'endTime must be after startTime' });
  }

  try {
    const { rows } = await query(
      `INSERT INTO schedules (user_id, course_id, day_of_week, start_time, end_time, room)
       VALUES ($1, $2, $3, $4, $5, $6)
       RETURNING schedule_id`,
      [targetUserId, courseId, dayOfWeek, startTime, endTime, room ?? null]
    );

    return res.status(201).json({ scheduleId: rows[0].schedule_id });
  } catch (err) {
    if (err.code === '23503') {
      return res.status(400).json({ error: 'Unknown course or user' });
    }
    if (err.code === '23505') {
      return res.status(409).json({ error: 'That class is already on the timetable' });
    }
    return next(err);
  }
}

/** DELETE /api/schedule/:id */
export async function deleteScheduleEntry(req, res, next) {
  try {
    const { rowCount } = await query(
      'DELETE FROM schedules WHERE schedule_id = $1',
      [req.params.id]
    );

    if (rowCount === 0) {
      return res.status(404).json({ error: 'Schedule entry not found' });
    }

    return res.status(204).send();
  } catch (err) {
    return next(err);
  }
}
