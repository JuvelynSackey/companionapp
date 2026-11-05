import { z } from 'zod';
import { query } from '../config/db.js';
import { getNotificationService } from '../services/push.js';
import { possibleMatches } from '../utils/lostFoundMatch.js';

export const createLostFoundSchema = z.object({
  kind: z.enum(['lost', 'found']),
  title: z.string().trim().min(3).max(120),
  description: z.string().trim().max(1000).optional(),
  location: z.string().trim().max(160).optional(),
  // How to reach the poster (a phone number, an email, "ask at the hall
  // porters' lodge"). Free text, chosen by the poster, and only ever sent
  // to signed-in users.
  contact: z.string().trim().max(160).optional(),
});

function shape(row, user) {
  const isMine = user != null && row.posted_by === user.userId;
  return {
    itemId: row.item_id,
    kind: row.kind,
    title: row.title,
    description: row.description,
    location: row.location,
    status: row.status,
    createdAt: row.created_at,
    // Who posted it and how to reach them are for signed-in users only, so
    // a guest browsing the board learns nothing about anyone.
    postedBy: user ? row.posted_by_name : null,
    contact: user ? row.contact : null,
    isMine,
    canManage: isMine || user?.role === 'admin',
  };
}

/**
 * GET /api/lost-found - guest-readable.
 * Open items first, newest first within each group.
 */
export async function listLostFound(req, res, next) {
  try {
    const { rows } = await query(
      `SELECT i.item_id, i.kind, i.title, i.description, i.location, i.contact,
              i.status, i.created_at, i.posted_by, u.full_name AS posted_by_name
         FROM lost_found_items i
         JOIN users u ON u.user_id = i.posted_by
        ORDER BY (i.status = 'open') DESC, i.created_at DESC`
    );

    const items = rows.map((row) => shape(row, req.user));
    // Each open post lists the open posts of the other kind that may be the
    // same item (titles only; see utils/lostFoundMatch.js).
    for (const item of items) {
      item.possibleMatches = possibleMatches(item, items).map((m) => ({ itemId: m.itemId, title: m.title }));
    }
    return res.json({ items });
  } catch (err) {
    return next(err);
  }
}

/** POST /api/lost-found - any signed-in user. */
export async function createLostFound(req, res, next) {
  const { kind, title, description, location, contact } = req.body;

  try {
    const { rows } = await query(
      `INSERT INTO lost_found_items (kind, title, description, location, contact, posted_by)
       VALUES ($1, $2, $3, $4, $5, $6)
       RETURNING item_id`,
      [kind, title, description || null, location || null, contact || null, req.user.userId]
    );

    const itemId = rows[0].item_id;
    const posted = { itemId, kind, title, location: location || null, status: 'open' };

    // Open posts of the other kind that may be the same item. Their posters
    // (not the caller) get a push, in the background so posting stays fast.
    const others = await query(
      `SELECT item_id, kind, title, location, status, posted_by
         FROM lost_found_items
        WHERE status = 'open' AND kind <> $1 AND item_id <> $2`,
      [kind, itemId]
    );
    const matches = possibleMatches(
      posted,
      others.rows.map((r) => ({ itemId: r.item_id, kind: r.kind, title: r.title, location: r.location, status: r.status, postedBy: r.posted_by }))
    );
    const notify = [...new Set(matches.map((m) => m.postedBy))].filter((id) => id !== req.user.userId);
    if (notify.length > 0) {
      getNotificationService()
        .then((notifications) => notifications.notifyLostFoundMatch(notify, posted))
        .catch((err) => console.error('Lost & Found match push failed:', err));
    }

    return res.status(201).json({
      itemId,
      possibleMatches: matches.map((m) => ({ itemId: m.itemId, title: m.title })),
    });
  } catch (err) {
    return next(err);
  }
}

/**
 * Loads an item for a change only its poster or an admin may make. Sends the
 * 404/403 itself and returns null when the change must not go ahead.
 */
async function itemTheCallerMayManage(req, res) {
  const itemId = Number(req.params.id);
  if (!Number.isInteger(itemId) || itemId <= 0) {
    res.status(404).json({ error: 'Item not found' });
    return null;
  }

  const { rows } = await query('SELECT posted_by FROM lost_found_items WHERE item_id = $1', [itemId]);
  if (rows.length === 0) {
    res.status(404).json({ error: 'Item not found' });
    return null;
  }
  if (rows[0].posted_by !== req.user.userId && req.user.role !== 'admin') {
    res.status(403).json({ error: 'Only the person who posted this item can change it' });
    return null;
  }
  return itemId;
}

/** PATCH /api/lost-found/:id/returned - the poster or an admin. */
export async function markReturned(req, res, next) {
  try {
    const itemId = await itemTheCallerMayManage(req, res);
    if (itemId == null) return undefined;

    await query(`UPDATE lost_found_items SET status = 'returned' WHERE item_id = $1`, [itemId]);
    return res.status(204).send();
  } catch (err) {
    return next(err);
  }
}

/** DELETE /api/lost-found/:id - the poster or an admin. */
export async function deleteLostFound(req, res, next) {
  try {
    const itemId = await itemTheCallerMayManage(req, res);
    if (itemId == null) return undefined;

    await query('DELETE FROM lost_found_items WHERE item_id = $1', [itemId]);
    return res.status(204).send();
  } catch (err) {
    return next(err);
  }
}
