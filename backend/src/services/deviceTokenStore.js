import { query } from '../config/db.js';

/**
 * PostgreSQL access for device tokens and the push preference. Kept apart
 * from notificationService.js (which only needs the four functions listed
 * there) so the fan-out logic can be tested without a database.
 */

/** A user keeps their newest few; the oldest are dropped. Stops one account hoarding rows. */
export const MAX_TOKENS_PER_USER = 10;

/**
 * Saves a device token for a user. The token is unique across users, so if it
 * was registered by someone else (a shared or handed-over phone) it moves to
 * this user rather than staying with the previous one.
 */
export async function registerToken(userId, token, platform) {
  await query(
    `INSERT INTO device_tokens (user_id, token, platform)
     VALUES ($1, $2, $3)
     ON CONFLICT (token) DO UPDATE
       SET user_id = EXCLUDED.user_id, platform = EXCLUDED.platform, updated_at = now()`,
    [userId, token, platform]
  );

  await query(
    `DELETE FROM device_tokens
      WHERE user_id = $1
        AND token_id NOT IN (
          SELECT token_id FROM device_tokens WHERE user_id = $1
           ORDER BY updated_at DESC, token_id DESC
           LIMIT $2)`,
    [userId, MAX_TOKENS_PER_USER]
  );
}

/** Removes the caller's own token; someone else's is left alone. Returns whether one was removed. */
export async function unregisterToken(userId, token) {
  const { rowCount } = await query('DELETE FROM device_tokens WHERE token = $1 AND user_id = $2', [token, userId]);
  return rowCount > 0;
}

export async function countTokensForUser(userId) {
  const { rows } = await query('SELECT count(*)::int AS n FROM device_tokens WHERE user_id = $1', [userId]);
  return rows[0].n;
}

/** Every token belonging to a user who has not switched push off. */
export async function tokensForAllEnabledUsers() {
  const { rows } = await query(
    `SELECT t.token
       FROM device_tokens t
       JOIN users u ON u.user_id = t.user_id
      WHERE u.push_enabled`
  );
  return rows.map((row) => row.token);
}

/** Forgets tokens the push service reported as dead. */
export async function removeTokens(tokens) {
  if (tokens.length === 0) return 0;
  const { rowCount } = await query('DELETE FROM device_tokens WHERE token = ANY($1::text[])', [tokens]);
  return rowCount;
}

export async function getPushEnabled(userId) {
  const { rows } = await query('SELECT push_enabled FROM users WHERE user_id = $1', [userId]);
  return rows.length === 0 ? null : rows[0].push_enabled;
}

export async function setPushEnabled(userId, enabled) {
  const { rowCount } = await query('UPDATE users SET push_enabled = $2 WHERE user_id = $1', [userId, enabled]);
  return rowCount > 0;
}

/** The functions notificationService.js depends on, bundled as its `store`. */
export const deviceTokenStore = { tokensForAllEnabledUsers, removeTokens };
