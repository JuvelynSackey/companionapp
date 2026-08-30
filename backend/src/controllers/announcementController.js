import { z } from 'zod';
import { query } from '../config/db.js';

export const createAnnouncementSchema = z.object({
  title: z.string().trim().min(3).max(160),
  message: z.string().trim().min(1),
  category: z.enum(['general', 'academic', 'emergency']).default('general'),
});

function shape(row) {
  return {
    announcementId: row.announcement_id,
    title: row.title,
    message: row.message,
    category: row.category,
    postedBy: row.posted_by_name,
    datePosted: row.date_posted,
  };
}

/**
 * GET /api/announcements?limit=20
 * Newest first — the dashboard shows only the most recent few.
 */
export async function listAnnouncements(req, res, next) {
  const limit = Math.min(Number(req.query.limit) || 20, 100);

  try {
    const { rows } = await query(
      `SELECT a.announcement_id, a.title, a.message, a.category, a.date_posted,
              u.full_name AS posted_by_name
         FROM announcements a
         LEFT JOIN users u ON u.user_id = a.posted_by
        ORDER BY a.date_posted DESC
        LIMIT $1`,
      [limit]
    );

    return res.json({ announcements: rows.map(shape) });
  } catch (err) {
    return next(err);
  }
}

/** POST /api/announcements - admin only. */
export async function createAnnouncement(req, res, next) {
  const { title, message, category } = req.body;

  try {
    const { rows } = await query(
      `INSERT INTO announcements (title, message, category, posted_by)
       VALUES ($1, $2, $3, $4)
       RETURNING announcement_id, date_posted`,
      [title, message, category, req.user.userId]
    );

    // TODO (Module 3): fan out a Firebase Cloud Messaging push here so the
    // alert reaches devices, not just the in-app feed.
    return res.status(201).json({
      announcementId: rows[0].announcement_id,
      datePosted: rows[0].date_posted,
    });
  } catch (err) {
    return next(err);
  }
}

/** DELETE /api/announcements/:id - admin only. */
export async function deleteAnnouncement(req, res, next) {
  try {
    const { rowCount } = await query(
      'DELETE FROM announcements WHERE announcement_id = $1',
      [req.params.id]
    );

    if (rowCount === 0) {
      return res.status(404).json({ error: 'Announcement not found' });
    }

    return res.status(204).send();
  } catch (err) {
    return next(err);
  }
}
