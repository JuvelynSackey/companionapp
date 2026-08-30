import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import { z } from 'zod';
import { query } from '../config/db.js';
import { config } from '../config/env.js';

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
