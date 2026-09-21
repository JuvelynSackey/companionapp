/**
 * Offline tests for the push fan-out (no database, no Firebase):  npm test
 */
import { test } from 'node:test';
import assert from 'node:assert/strict';
import {
  announcementMessage, createNotificationService, MAX_TOKENS_PER_REQUEST,
  CHANNEL_ANNOUNCEMENTS, CHANNEL_EMERGENCY,
} from './notificationService.js';
import { LogSender } from './pushSenders.js';

const silent = { log() {}, warn() {}, error() {} };

/** In-memory stand-in for the database-backed store. */
function fakeStore(tokens) {
  const store = {
    tokens: [...tokens],
    removed: [],
    failLoad: false,
    async tokensForAllEnabledUsers() {
      if (store.failLoad) throw new Error('db down');
      return store.tokens;
    },
    async removeTokens(dead) {
      store.removed.push(...dead);
      store.tokens = store.tokens.filter((t) => !dead.includes(t));
      return dead.length;
    },
  };
  return store;
}

const announcement = { announcementId: 42, title: 'Exam timetable out', message: 'See the portal.', category: 'academic' };

test('announcementMessage: a normal announcement', () => {
  assert.deepEqual(announcementMessage(announcement), {
    title: 'Exam timetable out',
    body: 'See the portal.',
    data: { type: 'announcement', announcementId: '42', category: 'academic' },
    channelId: CHANNEL_ANNOUNCEMENTS,
    priority: 'high',
  });
});

test('announcementMessage: an emergency gets the siren and the emergency channel, like the in-app notification', () => {
  const message = announcementMessage({ ...announcement, title: 'Campus closed', category: 'emergency' });
  assert.equal(message.title, '🚨 Campus closed');
  assert.equal(message.channelId, CHANNEL_EMERGENCY);
  assert.equal(message.data.category, 'emergency');
});

test('announcementMessage: every data value is a string (an FCM requirement)', () => {
  for (const value of Object.values(announcementMessage(announcement).data)) assert.equal(typeof value, 'string');
});

test('announcementMessage: a long body is shortened with an ellipsis', () => {
  const body = announcementMessage({ ...announcement, message: 'x'.repeat(1000) }).body;
  assert.equal(body.length, 300);
  assert.ok(body.endsWith('…'));
});

test('announcementMessage: a category-less announcement is "general"', () => {
  assert.equal(announcementMessage({ ...announcement, category: undefined }).data.category, 'general');
});

test('sends one message to every enabled device', async () => {
  const sender = new LogSender({ logger: silent });
  const service = createNotificationService({ store: fakeStore(['a', 'b', 'c']), sender, logger: silent });

  const summary = await service.notifyAnnouncement(announcement);

  assert.deepEqual(summary, { devices: 3, sent: 3, failed: 0, removed: 0 });
  assert.equal(sender.sent.length, 1);
  assert.deepEqual(sender.sent[0].tokens, ['a', 'b', 'c']);
  assert.equal(sender.sent[0].message.title, 'Exam timetable out');
});

test('nobody registered: nothing is sent and nothing breaks', async () => {
  const sender = new LogSender({ logger: silent });
  const service = createNotificationService({ store: fakeStore([]), sender, logger: silent });

  assert.deepEqual(await service.notifyAnnouncement(announcement), { devices: 0, sent: 0, failed: 0, removed: 0 });
  assert.equal(sender.sent.length, 0, 'no empty request');
});

test('a token in the store twice is only sent to once', async () => {
  const sender = new LogSender({ logger: silent });
  const service = createNotificationService({ store: fakeStore(['a', 'a', 'b']), sender, logger: silent });

  const summary = await service.notifyAnnouncement(announcement);

  assert.equal(summary.devices, 2);
  assert.deepEqual(sender.sent[0].tokens, ['a', 'b']);
});

test(`tokens go out in batches of at most ${MAX_TOKENS_PER_REQUEST} (the FCM limit)`, async () => {
  const tokens = Array.from({ length: 1201 }, (_, i) => `token-${i}`);
  const sender = new LogSender({ logger: silent });
  const service = createNotificationService({ store: fakeStore(tokens), sender, logger: silent });

  const summary = await service.notifyAnnouncement(announcement);

  assert.deepEqual(sender.sent.map((s) => s.tokens.length), [500, 500, 201]);
  assert.equal(summary.sent, 1201);
  assert.deepEqual(sender.sent.flatMap((s) => s.tokens), tokens, 'every token exactly once, in order');
});

test('tokens the push service says are dead are removed from the store', async () => {
  const store = fakeStore(['good', 'dead-1', 'dead-2']);
  const sender = {
    async send(_message, tokens) {
      return tokens.map((token) => ({ token, ok: !token.startsWith('dead'), invalidToken: token.startsWith('dead') }));
    },
  };
  const service = createNotificationService({ store, sender, logger: silent });

  const summary = await service.notifyAnnouncement(announcement);

  assert.deepEqual(summary, { devices: 3, sent: 1, failed: 2, removed: 2 });
  assert.deepEqual(store.removed, ['dead-1', 'dead-2']);
  assert.deepEqual(store.tokens, ['good']);
});

test('a failed send that is not a dead token keeps the token', async () => {
  const store = fakeStore(['a']);
  const sender = { async send(_m, tokens) { return tokens.map((token) => ({ token, ok: false, error: 'messaging/quota-exceeded' })); } };
  const service = createNotificationService({ store, sender, logger: silent });

  const summary = await service.notifyAnnouncement(announcement);

  assert.deepEqual(summary, { devices: 1, sent: 0, failed: 1, removed: 0 });
  assert.deepEqual(store.tokens, ['a']);
});

test('one batch throwing does not stop the other batches, and never rejects', async () => {
  const tokens = Array.from({ length: 1000 }, (_, i) => `token-${i}`);
  let call = 0;
  const sender = {
    async send(_m, batch) {
      call++;
      if (call === 1) throw new Error('network down');
      return batch.map((token) => ({ token, ok: true }));
    },
  };
  const service = createNotificationService({ store: fakeStore(tokens), sender, logger: silent });

  const summary = await service.notifyAnnouncement(announcement);

  assert.deepEqual(summary, { devices: 1000, sent: 500, failed: 500, removed: 0 });
});

test('the store failing to load tokens does not reject either', async () => {
  const store = fakeStore(['a']);
  store.failLoad = true;
  const service = createNotificationService({ store, sender: new LogSender({ logger: silent }), logger: silent });

  assert.deepEqual(await service.notifyAnnouncement(announcement), { devices: 0, sent: 0, failed: 0, removed: 0 });
});

test('failing to remove dead tokens does not reject', async () => {
  const store = fakeStore(['dead']);
  store.removeTokens = async () => { throw new Error('db down'); };
  const sender = { async send(_m, tokens) { return tokens.map((token) => ({ token, ok: false, invalidToken: true })); } };
  const service = createNotificationService({ store, sender, logger: silent });

  const summary = await service.notifyAnnouncement(announcement);

  assert.equal(summary.failed, 1);
  assert.equal(summary.removed, 0);
});
