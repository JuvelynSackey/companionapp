import { z } from 'zod';
import { query } from '../config/db.js';

export const createAnnouncementSchema = z.object({
  title: z.string().trim().min(3).max(160),
  message: z.string().trim().min(1),
  category: z.enum(['general', 'academic', 'emergency']).default('general'),
});

export const updateSyncCursorSchema = z.object({
  lastSyncedAnnouncementId: z.number().int().min(0),
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

/**
 * GET /api/announcements/sync-cursor
 * Server-side (not per-device) high-water mark for AnnouncementPushBridge —
 * see the column comment on users.last_synced_announcement_id in schema.sql
 * for why this lives on the server instead of local device storage.
 */
export async function getSyncCursor(req, res, next) {
  try {
    const { rows } = await query(
      'SELECT last_synced_announcement_id FROM users WHERE user_id = $1',
      [req.user.userId]
    );

    if (rows.length === 0) {
      return res.status(404).json({ error: 'User not found' });
    }

    return res.json({ lastSyncedAnnouncementId: rows[0].last_synced_announcement_id });
  } catch (err) {
    return next(err);
  }
}

/**
 * PUT /api/announcements/sync-cursor
 * Only ever moves forward — a stale client re-sending an older id (e.g. a
 * slow device that queued a request before a newer one landed) can't roll
 * the shared cursor backward and cause an already-seen announcement to be
 * re-notified.
 */
export async function updateSyncCursor(req, res, next) {
  const { lastSyncedAnnouncementId } = req.body;

  try {
    const { rows } = await query(
      `UPDATE users
          SET last_synced_announcement_id = GREATEST(last_synced_announcement_id, $1)
        WHERE user_id = $2
        RETURNING last_synced_announcement_id`,
      [lastSyncedAnnouncementId, req.user.userId]
    );

    if (rows.length === 0) {
      return res.status(404).json({ error: 'User not found' });
    }

    return res.json({ lastSyncedAnnouncementId: rows[0].last_synced_announcement_id });
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
