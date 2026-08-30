import { query } from '../config/db.js';

/**
 * GET /api/dashboard
 *
 * The dashboard mock-up shows four things at once: counts, today's classes,
 * recent announcements and upcoming events. Serving them from one endpoint
 * means the app opens with a single round trip instead of four — which
 * matters on campus wifi, and shows up directly in the "Speed" evaluation
 * metric from proposal section 2.6.
 */
export async function getDashboard(req, res, next) {
  const userId = req.user.userId;

  try {
    const [classes, announcements, events] = await Promise.all([
      query(
        `SELECT s.schedule_id, s.room,
                to_char(s.start_time, 'HH24:MI') AS start_time,
                to_char(s.end_time,   'HH24:MI') AS end_time,
                c.course_title, c.lecturer_name,
                (CURRENT_TIME BETWEEN s.start_time AND s.end_time) AS in_progress
           FROM schedules s
           JOIN courses c ON c.course_id = s.course_id
          WHERE s.user_id = $1
            AND s.day_of_week = EXTRACT(ISODOW FROM CURRENT_DATE)
          ORDER BY s.start_time`,
        [userId]
      ),
      query(
        `SELECT announcement_id, title, message, category, date_posted
           FROM announcements
          ORDER BY date_posted DESC
          LIMIT 3`
      ),
      query(
        `SELECT event_id, title, event_date, location
           FROM events
          WHERE event_date >= now()
          ORDER BY event_date
          LIMIT 3`
      ),
    ]);

    return res.json({
      stats: {
        classesToday: classes.rowCount,
        announcements: announcements.rowCount,
        upcomingEvents: events.rowCount,
      },
      todaysClasses: classes.rows.map((row) => ({
        scheduleId: row.schedule_id,
        courseTitle: row.course_title,
        lecturer: row.lecturer_name,
        room: row.room,
        startTime: row.start_time,
        endTime: row.end_time,
        inProgress: row.in_progress,
      })),
      announcements: announcements.rows.map((row) => ({
        announcementId: row.announcement_id,
        title: row.title,
        message: row.message,
        category: row.category,
        datePosted: row.date_posted,
      })),
      upcomingEvents: events.rows.map((row) => ({
        eventId: row.event_id,
        title: row.title,
        eventDate: row.event_date,
        location: row.location,
      })),
    });
  } catch (err) {
    return next(err);
  }
}
