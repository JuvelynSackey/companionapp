import jwt from 'jsonwebtoken';
import { config } from '../config/env.js';

/**
 * Verifies the Bearer token and attaches { userId, role } to the request.
 * Every route that touches a student's own data must sit behind this.
 */
export function requireAuth(req, res, next) {
  const header = req.headers.authorization ?? '';

  if (!header.startsWith('Bearer ')) {
    return res.status(401).json({ error: 'Missing or malformed Authorization header' });
  }

  const token = header.slice('Bearer '.length);

  try {
    const payload = jwt.verify(token, config.jwt.secret);
    req.user = { userId: payload.sub, role: payload.role };
    return next();
  } catch {
    // Deliberately vague: distinguishing "expired" from "forged" for an
    // unauthenticated caller only helps an attacker.
    return res.status(401).json({ error: 'Invalid or expired token' });
  }
}

/**
 * Gate for the admin-only use cases in the proposal (manage users, post
 * announcements, manage events, update schedules and grades).
 *
 * Must be used *after* requireAuth.
 */
export function requireAdmin(req, res, next) {
  if (req.user?.role !== 'admin') {
    return res.status(403).json({ error: 'Administrator access required' });
  }
  return next();
}
