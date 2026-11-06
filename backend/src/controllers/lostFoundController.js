import { z } from 'zod';
import { query } from '../config/db.js';
import { getNotificationService } from '../services/push.js';
import { possibleMatches } from '../utils/lostFoundMatch.js';

/** At most 2 MB once decoded; base64 is a third bigger. */
export const MAX_PHOTO_BYTES = 2 * 1024 * 1024;
const MAX_PHOTO_BASE64 = Math.ceil(MAX_PHOTO_BYTES / 3) * 4;

/** 'image/jpeg' or 'image/png' from the file's first bytes, else null. */
export function photoType(bytes) {
  if (bytes.length > 3 && bytes[0] === 0xff && bytes[1] === 0xd8 && bytes[2] === 0xff) return 'image/jpeg';
  if (bytes.length > 8 && bytes.subarray(0, 8).equals(Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]))) return 'image/png';
  return null;
}

export const createLostFoundSchema = z.object({
  kind: z.enum(['lost', 'found']),
  title: z.string().trim().min(3).max(120),
  description: z.string().trim().max(1000).optional(),
  location: z.string().trim().max(160).optional(),
  // How to reach the poster (a phone number, an email, "ask at the hall
  // porters' lodge"). Free text, chosen by the poster, and only ever sent
  // to signed-in users.
  contact: z.string().trim().max(160).optional(),
  // One optional photo, base64-encoded (the app shrinks it first).
  photo: z.string().max(MAX_PHOTO_BASE64).optional(),
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
    hasPhoto: row.has_photo === true,
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
              i.status, i.created_at, i.posted_by, u.full_name AS posted_by_name,
              (i.photo IS NOT NULL) AS has_photo
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

  let photo = null;
  let type = null;
  if (req.body.photo) {
    photo = Buffer.from(req.body.photo, 'base64');
    type = photoType(photo);
    if (!type) return res.status(400).json({ error: 'The photo must be a JPEG or PNG image.' });
    if (photo.length > MAX_PHOTO_BYTES) return res.status(400).json({ error: 'The photo is too large (2 MB at most).' });
  }

  try {
    const { rows } = await query(
      `INSERT INTO lost_found_items (kind, title, description, location, contact, posted_by, photo, photo_type)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
       RETURNING item_id`,
      [kind, title, description || null, location || null, contact || null, req.user.userId, photo, type]
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

/**
 * GET /api/lost-found/:id/photo - guest-readable, like the board itself. The
 * photo shows the item, never the poster's details.
 */
export async function lostFoundPhoto(req, res, next) {
  const itemId = Number(req.params.id);
  if (!Number.isInteger(itemId) || itemId <= 0) return res.status(404).json({ error: 'Photo not found' });
  try {
    const { rows } = await query('SELECT photo, photo_type FROM lost_found_items WHERE item_id = $1', [itemId]);
    if (rows.length === 0 || !rows[0].photo) return res.status(404).json({ error: 'Photo not found' });
    res.set('Content-Type', rows[0].photo_type);
    res.set('Cache-Control', 'public, max-age=86400');
    return res.send(rows[0].photo);
  } catch (err) {
    return next(err);
  }
}
