/**
 * Turns "an announcement was posted" into pushes to every device that wants
 * them. Depends only on a `store` and a `sender` passed in, so it is tested
 * with in-memory fakes and no database or Firebase:
 *
 *   store.tokensForAllEnabledUsers() -> Promise<string[]>
 *   store.removeTokens(tokens)       -> Promise<number>
 *   sender.send(message, tokens)     -> Promise<[{ token, ok, invalidToken? }]>
 *
 * Nothing here throws to its caller: a failed batch is logged and counted, and
 * the rest still go out. Callers run it in the background.
 */

/** FCM accepts at most 500 tokens per multicast request. */
export const MAX_TOKENS_PER_REQUEST = 500;

const MAX_BODY_LENGTH = 300;

/** Must match the channel ids the app creates (notification_service.dart). */
export const CHANNEL_ANNOUNCEMENTS = 'announcements';
export const CHANNEL_EMERGENCY = 'emergency_announcements';

/**
 * The push for an announcement. Titled like the app's own local notification
 * (an emergency gets the siren), and carries the id so a tap can open Alerts.
 */
export function announcementMessage({ announcementId, title, message, category }) {
  const isEmergency = category === 'emergency';
  const body = message.length > MAX_BODY_LENGTH ? `${message.slice(0, MAX_BODY_LENGTH - 1)}…` : message;

  return {
    title: isEmergency ? `🚨 ${title}` : title,
    body,
    // FCM data values must all be strings.
    data: { type: 'announcement', announcementId: String(announcementId), category: category ?? 'general' },
    channelId: isEmergency ? CHANNEL_EMERGENCY : CHANNEL_ANNOUNCEMENTS,
    priority: 'high',
  };
}

function chunk(items, size) {
  const chunks = [];
  for (let i = 0; i < items.length; i += size) chunks.push(items.slice(i, i + size));
  return chunks;
}

export function createNotificationService({ store, sender, logger = console }) {
  /** Sends one message to every enabled device. Resolves with a summary; never rejects. */
  async function sendToAll(message) {
    const summary = { devices: 0, sent: 0, failed: 0, removed: 0 };

    let tokens;
    try {
      tokens = [...new Set(await store.tokensForAllEnabledUsers())];
    } catch (err) {
      logger.error('Push: could not load device tokens:', err);
      return summary;
    }
    summary.devices = tokens.length;

    const dead = [];
    for (const batch of chunk(tokens, MAX_TOKENS_PER_REQUEST)) {
      try {
        const results = await sender.send(message, batch);
        for (const result of results) {
          if (result.ok) summary.sent++;
          else summary.failed++;
          if (result.invalidToken) dead.push(result.token);
        }
      } catch (err) {
        // One bad batch (network, quota) must not stop the others.
        summary.failed += batch.length;
        logger.error(`Push: a batch of ${batch.length} failed:`, err);
      }
    }

    if (dead.length > 0) {
      try {
        summary.removed = await store.removeTokens(dead);
      } catch (err) {
        logger.error('Push: could not remove dead tokens:', err);
      }
    }

    return summary;
  }

  return {
    sender,
    sendToAll,
    notifyAnnouncement: (announcement) => sendToAll(announcementMessage(announcement)),
  };
}
