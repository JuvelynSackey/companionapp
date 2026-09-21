import { z } from 'zod';
import {
  registerToken, unregisterToken, countTokensForUser, getPushEnabled, setPushEnabled,
} from '../services/deviceTokenStore.js';

// A real FCM token is ~150-170 characters; the bounds only reject junk and abuse.
const tokenField = z.string().trim().min(20).max(4096);

export const registerDeviceTokenSchema = z.object({
  token: tokenField,
  platform: z.enum(['android', 'ios', 'web']),
});

export const unregisterDeviceTokenSchema = z.object({ token: tokenField });

export const updatePreferencesSchema = z.object({ pushEnabled: z.boolean() });

async function preferences(userId) {
  return {
    pushEnabled: (await getPushEnabled(userId)) ?? true,
    registeredDevices: await countTokensForUser(userId),
  };
}

/**
 * POST /api/users/me/device-token
 * Idempotent: the app calls this on every sign-in and whenever Firebase
 * rotates the token. If the token was registered by another account it moves
 * to the caller (see registerToken).
 */
export async function registerDeviceToken(req, res, next) {
  try {
    await registerToken(req.user.userId, req.body.token, req.body.platform);
    return res.json({ registered: true, registeredDevices: await countTokensForUser(req.user.userId) });
  } catch (err) {
    return next(err);
  }
}

/**
 * DELETE /api/users/me/device-token  { token }
 * Called on sign-out. 204 even if the token was already gone, so the app
 * never has to handle "not found" while signing out. Only the caller's own
 * token is removed.
 */
export async function unregisterDeviceToken(req, res, next) {
  try {
    await unregisterToken(req.user.userId, req.body.token);
    return res.status(204).send();
  } catch (err) {
    return next(err);
  }
}

/** GET /api/users/me/notification-preferences */
export async function getNotificationPreferences(req, res, next) {
  try {
    return res.json(await preferences(req.user.userId));
  } catch (err) {
    return next(err);
  }
}

/** PUT /api/users/me/notification-preferences  { pushEnabled } */
export async function updateNotificationPreferences(req, res, next) {
  try {
    const updated = await setPushEnabled(req.user.userId, req.body.pushEnabled);
    if (!updated) return res.status(404).json({ error: 'User not found' });
    return res.json(await preferences(req.user.userId));
  } catch (err) {
    return next(err);
  }
}
