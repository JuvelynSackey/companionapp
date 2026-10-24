import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import { z } from 'zod';
import { query } from '../config/db.js';
import { config } from '../config/env.js';
import { getGoogleIdTokenVerifier } from '../services/googleAuth.js';
import { findOrCreateGoogleUser } from '../services/googleUserStore.js';

const SALT_ROUNDS = 12;

export const registerSchema = z.object({
  fullName: z.string().trim().min(2, 'Name must be at least 2 characters').max(120),
  email: z.string().trim().toLowerCase().email('Enter a valid email address').max(160),
  password: z
    .string()
    .min(8, 'Password must be at least 8 characters')
    .max(200, 'Password is too long'),
});

export const loginSchema = z.object({
  email: z.string().trim().toLowerCase().email('Enter a valid email address'),
  password: z.string().min(1, 'Password is required'),
});

export const googleSignInSchema = z.object({
  // A Firebase ID token, not a raw Google one — see docs/google-sign-in.md.
  // No format check beyond "non-trivial string"; verifyGoogleIdToken() is
  // what actually validates it, and rejecting garbage early just duplicates
  // that check with a worse error message.
  idToken: z.string().min(20, 'Missing or malformed idToken'),
});

/**
 * Provisions an elevated-role account (lecturer or admin). Only reachable by
 * an existing admin (see requireAdmin on the route) — there is no
 * self-service or email-invite path to lecturer/admin, deliberately, same
 * as the original admin seed account.
 */
export const provisionSchema = z.object({
  fullName: z.string().trim().min(2, 'Name must be at least 2 characters').max(120),
  email: z.string().trim().toLowerCase().email('Enter a valid email address').max(160),
  password: z
    .string()
    .min(8, 'Password must be at least 8 characters')
    .max(200, 'Password is too long'),
  role: z.enum(['lecturer', 'admin']),
});

/**
 * Granular permission strings derived from role, never stored — role stays
 * the single source of truth so permissions can't drift out of sync with
 * it. Computed fresh on every login/register/me response rather than
 * trusted from an old JWT, so a role change takes effect on next sign-in
 * without needing to reissue every outstanding token.
 */
const ROLE_PERMISSIONS = {
  student: [
    'schedule:read', 'exams:read', 'grades:read:own', 'announcements:read', 'events:read', 'events:register',
    'quizzes:read', 'quizzes:attempt',
  ],
  lecturer: [
    'schedule:read', 'exams:read', 'grades:read:own', 'announcements:read', 'events:read', 'events:register',
    'events:create', 'quizzes:read', 'quizzes:attempt', 'quizzes:create',
  ],
  admin: [
    'schedule:read', 'exams:read', 'grades:read:own', 'announcements:read', 'events:read', 'events:register',
    'events:create', 'schedule:write', 'grades:write', 'announcements:write',
    'quizzes:read', 'quizzes:attempt', 'quizzes:create', 'quizzes:delete',
  ],
};

function permissionsForRole(role) {
  return ROLE_PERMISSIONS[role] ?? [];
}

function issueToken(user) {
  return jwt.sign(
    { sub: user.user_id, role: user.role },
    config.jwt.secret,
    { expiresIn: config.jwt.expiresIn }
  );
}

/** Shape a DB row for the client, guaranteeing the hash never goes out. */
function publicUser(row) {
  return {
    userId: row.user_id,
    fullName: row.full_name,
    email: row.email,
    role: row.role,
    permissions: permissionsForRole(row.role),
  };
}

export async function register(req, res, next) {
  const { fullName, email, password } = req.body;

  try {
    const existing = await query(
      'SELECT 1 FROM users WHERE LOWER(email) = LOWER($1)',
      [email]
    );

    if (existing.rowCount > 0) {
      return res.status(409).json({ error: 'An account with that email already exists' });
    }

    const passwordHash = await bcrypt.hash(password, SALT_ROUNDS);

    // New sign-ups are always students. Admins are promoted deliberately,
    // never by anything the client can send in the request body.
    const { rows } = await query(
      `INSERT INTO users (full_name, email, password_hash, role)
       VALUES ($1, $2, $3, 'student')
       RETURNING user_id, full_name, email, role`,
      [fullName, email, passwordHash]
    );

    const user = rows[0];
    return res.status(201).json({ token: issueToken(user), user: publicUser(user) });
  } catch (err) {
    return next(err);
  }
}

export async function login(req, res, next) {
  const { email, password } = req.body;

  try {
    const { rows } = await query(
      `SELECT user_id, full_name, email, role, password_hash
         FROM users
        WHERE LOWER(email) = LOWER($1)`,
      [email]
    );

    const user = rows[0];

    // Compare against a dummy hash when the user is absent so that a missing
    // account and a wrong password take the same time to answer, and return
    // the same message either way.
    const hash = user?.password_hash ?? '$2a$12$invalidinvalidinvalidinvalidinvalidinvalidinvalidinvalidinv';
    const passwordMatches = await bcrypt.compare(password, hash);

    if (!user || !passwordMatches) {
      return res.status(401).json({ error: 'Incorrect email or password' });
    }

    return res.json({ token: issueToken(user), user: publicUser(user) });
  } catch (err) {
    return next(err);
  }
}

/**
 * POST /api/auth/google — { idToken } from Firebase (the app signs into
 * Firebase with a Google credential first — see mobile's google_auth_service.dart).
 *
 * Three independent failure shapes, each meaning something different to the
 * client: 503 is "ask the admin to finish setup", 401 is "that token is no
 * good, try signing in again", 409 is the one Postgres itself catches (the
 * google_uid UNIQUE constraint) when two concurrent requests try to link the
 * same Google account to two different rows.
 */
export async function googleSignIn(req, res, next) {
  const verifier = await getGoogleIdTokenVerifier();
  if (!verifier) {
    return res.status(503).json({ error: 'Google sign-in is not configured on this server' });
  }

  let identity;
  try {
    identity = await verifier(req.body.idToken);
  } catch (err) {
    console.warn('Google sign-in token rejected:', err.message);
    return res.status(401).json({ error: 'Invalid or expired Google sign-in token' });
  }

  try {
    const user = await findOrCreateGoogleUser(identity);
    return res.json({ token: issueToken(user), user: publicUser(user) });
  } catch (err) {
    if (err.code === '23505') {
      return res.status(409).json({ error: 'That Google account is already linked to a different user' });
    }
    return next(err);
  }
}

/** POST /api/admin/provision-user — admin only. Creates a lecturer/admin account directly. */
export async function provisionUser(req, res, next) {
  const { fullName, email, password, role } = req.body;

  try {
    const existing = await query(
      'SELECT 1 FROM users WHERE LOWER(email) = LOWER($1)',
      [email]
    );

    if (existing.rowCount > 0) {
      return res.status(409).json({ error: 'An account with that email already exists' });
    }

    const passwordHash = await bcrypt.hash(password, SALT_ROUNDS);

    const { rows } = await query(
      `INSERT INTO users (full_name, email, password_hash, role)
       VALUES ($1, $2, $3, $4)
       RETURNING user_id, full_name, email, role`,
      [fullName, email, passwordHash, role]
    );

    return res.status(201).json({ user: publicUser(rows[0]) });
  } catch (err) {
    return next(err);
  }
}

/** Returns the caller's own profile - used by the app to restore a session. */
export async function me(req, res, next) {
  try {
    const { rows } = await query(
      'SELECT user_id, full_name, email, role FROM users WHERE user_id = $1',
      [req.user.userId]
    );

    if (rows.length === 0) {
      return res.status(404).json({ error: 'User not found' });
    }

    return res.json({ user: publicUser(rows[0]) });
  } catch (err) {
    return next(err);
  }
}
