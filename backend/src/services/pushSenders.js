/**
 * The two ways a push message can leave the server, behind one interface:
 *
 *   sender.send(message, tokens) -> [{ token, ok, invalidToken?, error? }, ...]
 *
 * where `message` is { title, body, data, channelId, priority } and `data`
 * values are strings (an FCM requirement).
 *
 *   LogSender  keeps what it was asked to send and prints a line. Used when
 *              push is off, when no Firebase key is configured, and in tests.
 *   FcmSender  sends through Firebase Cloud Messaging.
 *
 * No database or config imports here, so both can be unit-tested alone.
 */
import { getSharedFirebaseApp } from './firebaseAdminApp.js';

/** FCM error codes that mean the token is dead and should be forgotten. */
export const INVALID_TOKEN_CODES = new Set([
  'messaging/registration-token-not-registered',
  'messaging/invalid-registration-token',
]);

export class LogSender {
  constructor({ logger = console } = {}) {
    this.name = 'log';
    this.logger = logger;
    /** Everything "sent", newest last: [{ message, tokens }]. */
    this.sent = [];
  }

  async send(message, tokens) {
    this.sent.push({ message, tokens });
    this.logger.log(`[push:log-only] "${message.title}" to ${tokens.length} device(s)`);
    return tokens.map((token) => ({ token, ok: true }));
  }
}

export class FcmSender {
  /** @param messaging a firebase-admin Messaging instance (or a fake with sendEachForMulticast) */
  constructor(messaging) {
    this.name = 'fcm';
    this.messaging = messaging;
  }

  async send(message, tokens) {
    const response = await this.messaging.sendEachForMulticast({
      tokens,
      notification: { title: message.title, body: message.body },
      data: message.data ?? {},
      android: {
        priority: message.priority === 'high' ? 'high' : 'normal',
        // Must match a channel the app creates, or Android files it under a default one.
        notification: message.channelId ? { channelId: message.channelId } : undefined,
      },
      apns: { payload: { aps: { sound: 'default' } } },
    });

    return response.responses.map((result, i) => ({
      token: tokens[i],
      ok: result.success,
      invalidToken: !result.success && INVALID_TOKEN_CODES.has(result.error?.code),
      error: result.error?.code,
    }));
  }
}

const defaultLoadFirebaseAdmin = async () => {
  const app = await import('firebase-admin/app');
  const messaging = await import('firebase-admin/messaging');
  return { initializeApp: app.initializeApp, cert: app.cert, getMessaging: messaging.getMessaging };
};

/**
 * Chooses the sender from config. It never throws: a wrong or missing Firebase
 * setup must not stop the API from booting (announcements and everything else
 * still work), so it warns and falls back to LogSender instead.
 *
 * @param config           { enabled: boolean, serviceAccount: string (JSON) }
 * @param loadFirebaseAdmin overridable in tests
 */
export async function createPushSender({
  config,
  logger = console,
  loadFirebaseAdmin = defaultLoadFirebaseAdmin,
}) {
  if (!config.enabled) {
    logger.log('Push notifications: off (FCM_ENABLED is not "true"); pushes are only logged.');
    return new LogSender({ logger });
  }

  const fallback = (reason) => {
    logger.warn(`Push notifications: FCM_ENABLED is true but ${reason}. Falling back to log-only.`);
    return new LogSender({ logger });
  };

  if (!config.serviceAccount) return fallback('FIREBASE_SERVICE_ACCOUNT is not set');

  try {
    JSON.parse(config.serviceAccount);
  } catch {
    return fallback('FIREBASE_SERVICE_ACCOUNT is not valid JSON (paste the key file as a single line)');
  }

  try {
    // Shared with googleIdTokenVerifier.js: one Firebase app, one credential,
    // whichever feature needs it first initialises it.
    const { app, projectId } = await getSharedFirebaseApp(config.serviceAccount, loadFirebaseAdmin);
    const { getMessaging } = await loadFirebaseAdmin();
    logger.log(`Push notifications: on (Firebase project ${projectId ?? 'unknown'}).`);
    return new FcmSender(getMessaging(app));
  } catch (err) {
    return fallback(`Firebase could not be initialised (${err.message})`);
  }
}
