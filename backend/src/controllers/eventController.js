import { z } from 'zod';
import { query } from '../config/db.js';

export const createEventSchema = z.object({
  title: z.string().trim().min(3).max(160),
  description: z.string().trim().optional(),
  eventDate: z.string().datetime({ offset: true }),
  location: z.string().trim().max(160).optional(),
  clubId: z.number().int().positive().nullable().optional(),
});

function shape(row) {
  return {
    eventId: row.event_id,
    title: row.title,
    description: row.description,
    eventDate: row.event_date,
    location: row.location,
    clubName: row.club_name,
    attendeeCount: Number(row.attendee_count),
    isRegistered: row.is_registered,
    // The user id of whoever created the event (null if that account was deleted).
    // Lets the app show a delete button to a lecturer on their own events only;
    // the server still enforces this in deleteEvent.
    createdBy: row.created_by,
  };
}

/**
 * GET /api/events?upcoming=true
 * `is_registered` is computed per caller so the RSVP button in the mock-up
 * can render the right state without a second request.
 */
export async function listEvents(req, res, next) {
  const upcomingOnly = req.query.upcoming === 'true';

  try {
    const { rows } = await query(
      `SELECT e.event_id, e.title, e.description, e.event_date, e.location, e.created_by,
              c.name AS club_name,
              COUNT(r.user_id) AS attendee_count,
              BOOL_OR(r.user_id = $1) AS is_registered
         FROM events e
         LEFT JOIN clubs c ON c.club_id = e.club_id
         LEFT JOIN event_registrations r ON r.event_id = e.event_id
        WHERE ($2::boolean IS NOT TRUE OR e.event_date >= now())
        GROUP BY e.event_id, c.name
        ORDER BY e.event_date`,
      [req.user.userId, upcomingOnly]
    );

    return res.json({ events: rows.map(shape) });
  } catch (err) {
    return next(err);
  }
}

/** POST /api/events - lecturer or admin. */
export async function createEvent(req, res, next) {
  const { title, description, eventDate, location, clubId } = req.body;

  try {
    const { rows } = await query(
      `INSERT INTO events (title, description, event_date, location, club_id, created_by)
       VALUES ($1, $2, $3, $4, $5, $6)
       RETURNING event_id`,
      [title, description ?? null, eventDate, location ?? null, clubId ?? null, req.user.userId]
    );

    return res.status(201).json({ eventId: rows[0].event_id });
  } catch (err) {
    if (err.code === '23503') {
      return res.status(400).json({ error: 'Unknown club' });
    }
    return next(err);
  }
}

/**
 * POST /api/events/:id/register - the RSVP button.
 * ON CONFLICT DO NOTHING makes a double tap harmless rather than a 500.
 */
export async function registerForEvent(req, res, next) {
  try {
    const { rowCount } = await query(
      `INSERT INTO event_registrations (user_id, event_id)
       VALUES ($1, $2)
       ON CONFLICT (user_id, event_id) DO NOTHING`,
      [req.user.userId, req.params.id]
    );

    return res.status(201).json({
      registered: true,
      alreadyRegistered: rowCount === 0,
    });
  } catch (err) {
    if (err.code === '23503') {
      return res.status(404).json({ error: 'Event not found' });
    }
    return next(err);
  }
}

/**
 * DELETE /api/events/:id - lecturer or admin (role gate is on the route).
 * An admin may delete any event; a lecturer only the events they created, so
 * one lecturer cannot remove another's (or an admin's) event. RSVPs go with
 * it via ON DELETE CASCADE.
 */
export async function deleteEvent(req, res, next) {
  const eventId = Number(req.params.id);

  if (!Number.isInteger(eventId) || eventId <= 0) {
    return res.status(404).json({ error: 'Event not found' });
  }

  try {
    const { rows } = await query('SELECT created_by FROM events WHERE event_id = $1', [eventId]);

    if (rows.length === 0) {
      return res.status(404).json({ error: 'Event not found' });
    }

    const isOwner = rows[0].created_by === req.user.userId;
    if (req.user.role !== 'admin' && !isOwner) {
      return res.status(403).json({ error: 'You can only delete events you created' });
    }

    await query('DELETE FROM events WHERE event_id = $1', [eventId]);
    return res.status(204).send();
  } catch (err) {
    return next(err);
  }
}

/** DELETE /api/events/:id/register - cancel an RSVP. */
export async function cancelRegistration(req, res, next) {
  try {
    const { rowCount } = await query(
      'DELETE FROM event_registrations WHERE user_id = $1 AND event_id = $2',
      [req.user.userId, req.params.id]
    );

    if (rowCount === 0) {
      return res.status(404).json({ error: 'You are not registered for that event' });
    }

    return res.status(204).send();
  } catch (err) {
    return next(err);
  }
}
