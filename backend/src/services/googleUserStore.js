import { query } from '../config/db.js';

/**
 * Finds the user for a verified Google identity, or creates one. Pure SQL —
 * no Firebase here — so it is tested against a real database (see
 * googleUserStore.integration.js / `npm run test:db`), the same way
 * deviceTokenStore.js is.
 *
 * - An existing account (matched by lower-cased email, same rule every other
 *   lookup in this app uses) is linked the first time: its google_uid is set,
 *   so a student who registered with a password can also sign in with Google
 *   afterwards, and either of their login methods keeps working.
 * - No matching account creates one: full_name from the Google profile,
 *   google_uid set, password_hash left null, role always 'student' — the
 *   same rule self-registration uses; a client can never grant itself an
 *   elevated role.
 *
 * `identity` is `{ googleUid, email, name }` from googleIdTokenVerifier.js.
 * Returns the full user row (not yet shaped for the client — the caller
 * shapes it with authController.js's publicUser, same as every other
 * sign-in path).
 */
export async function findOrCreateGoogleUser({ googleUid, email, name }) {
  const { rows: existingRows } = await query(
    `SELECT user_id, full_name, email, role, google_uid
       FROM users
      WHERE LOWER(email) = LOWER($1)`,
    [email]
  );

  if (existingRows.length > 0) {
    const existing = existingRows[0];
    if (existing.google_uid === googleUid) return existing; // already linked, nothing to do

    // Linking: UPDATE, not INSERT. The google_uid UNIQUE constraint still
    // protects against the same Google account ending up on two rows (a
    // concurrent request, or ever reusing a UID) — that update fails with
    // Postgres error 23505, which the controller turns into a 409.
    const { rows } = await query(
      `UPDATE users SET google_uid = $2
        WHERE user_id = $1
        RETURNING user_id, full_name, email, role`,
      [existing.user_id, googleUid]
    );
    return rows[0];
  }

  const { rows } = await query(
    `INSERT INTO users (full_name, email, google_uid, role)
     VALUES ($1, $2, $3, 'student')
     RETURNING user_id, full_name, email, role`,
    [name, email, googleUid]
  );
  return rows[0];
}
