/**
 * Offline tests for the push senders and how one is chosen:  npm test
 * Firebase itself is never loaded; a fake stands in for it.
 */
import { test, beforeEach } from 'node:test';
import assert from 'node:assert/strict';
import { createPushSender, FcmSender, LogSender, INVALID_TOKEN_CODES } from './pushSenders.js';
import { _resetSharedFirebaseAppForTests } from './firebaseAdminApp.js';

// createPushSender shares one Firebase app (firebaseAdminApp.js) across calls
// in the real process, so a test that initialises it (or fails to) does not
// leak into the next test in this file.
beforeEach(_resetSharedFirebaseAppForTests);

/** Collects what would have been printed. */
function recordingLogger() {
  const lines = { log: [], warn: [], error: [] };
  return { lines, log: (m) => lines.log.push(m), warn: (m) => lines.warn.push(m), error: (m) => lines.error.push(m) };
}

const message = {
  title: 'Campus closed',
  body: 'Severe weather',
  data: { type: 'announcement', announcementId: '7' },
  channelId: 'emergency_announcements',
  priority: 'high',
};

const serviceAccountJson = JSON.stringify({ project_id: 'campus-test', client_email: 'x@y', private_key: 'k' });

function fakeFirebase({ throwOnInit = false } = {}) {
  const calls = { initializeApp: [], cert: [] };
  const module = {
    initializeApp: (options, name) => {
      if (throwOnInit) throw new Error('bad credentials');
      calls.initializeApp.push({ options, name });
      return { name };
    },
    cert: (credentials) => { calls.cert.push(credentials); return { credentials }; },
    getMessaging: () => ({ sendEachForMulticast: async () => ({ responses: [] }) }),
  };
  return { calls, load: async () => module };
}

test('LogSender records what it was asked to send and reports every token as sent', async () => {
  const logger = recordingLogger();
  const sender = new LogSender({ logger });

  const results = await sender.send(message, ['a', 'b']);

  assert.deepEqual(results, [{ token: 'a', ok: true }, { token: 'b', ok: true }]);
  assert.deepEqual(sender.sent, [{ message, tokens: ['a', 'b'] }]);
  assert.match(logger.lines.log[0], /Campus closed.*2 device/);
});

test('FcmSender builds the request FCM expects, including the Android channel', async () => {
  let request;
  const sender = new FcmSender({
    async sendEachForMulticast(r) { request = r; return { responses: [{ success: true }, { success: true }] }; },
  });

  await sender.send(message, ['t1', 't2']);

  assert.deepEqual(request.tokens, ['t1', 't2']);
  assert.deepEqual(request.notification, { title: 'Campus closed', body: 'Severe weather' });
  assert.deepEqual(request.data, { type: 'announcement', announcementId: '7' });
  assert.equal(request.android.priority, 'high');
  assert.deepEqual(request.android.notification, { channelId: 'emergency_announcements' });
});

test('FcmSender maps each response back to its token and flags only dead-token errors', async () => {
  const sender = new FcmSender({
    async sendEachForMulticast() {
      return {
        responses: [
          { success: true },
          { success: false, error: { code: 'messaging/registration-token-not-registered' } },
          { success: false, error: { code: 'messaging/invalid-registration-token' } },
          { success: false, error: { code: 'messaging/quota-exceeded' } },
        ],
      };
    },
  });

  const results = await sender.send(message, ['ok', 'gone', 'malformed', 'throttled']);

  assert.deepEqual(results.map((r) => [r.token, r.ok, !!r.invalidToken]), [
    ['ok', true, false],
    ['gone', false, true],
    ['malformed', false, true],
    ['throttled', false, false],
  ]);
  assert.equal(results[3].error, 'messaging/quota-exceeded');
});

test('the dead-token codes are exactly the two FCM uses for a token that will never work', () => {
  assert.deepEqual([...INVALID_TOKEN_CODES].sort(), [
    'messaging/invalid-registration-token',
    'messaging/registration-token-not-registered',
  ]);
});

test('createPushSender: off by default, log-only, and Firebase is never loaded', async () => {
  let loaded = false;
  const sender = await createPushSender({
    config: { enabled: false, serviceAccount: serviceAccountJson },
    logger: recordingLogger(),
    loadFirebaseAdmin: async () => { loaded = true; return {}; },
  });

  assert.equal(sender.name, 'log');
  assert.equal(loaded, false);
});

test('createPushSender: enabled without a key falls back to log-only with a warning, not a crash', async () => {
  const logger = recordingLogger();
  const sender = await createPushSender({ config: { enabled: true, serviceAccount: '' }, logger });

  assert.equal(sender.name, 'log');
  assert.match(logger.lines.warn[0], /FIREBASE_SERVICE_ACCOUNT is not set/);
});

test('createPushSender: a key that is not JSON falls back with a hint about single-line JSON', async () => {
  const logger = recordingLogger();
  const sender = await createPushSender({ config: { enabled: true, serviceAccount: '{ not json' }, logger });

  assert.equal(sender.name, 'log');
  assert.match(logger.lines.warn[0], /not valid JSON.*single line/);
});

test('createPushSender: Firebase refusing the credentials falls back, and says why', async () => {
  const logger = recordingLogger();
  const firebase = fakeFirebase({ throwOnInit: true });
  const sender = await createPushSender({
    config: { enabled: true, serviceAccount: serviceAccountJson },
    logger,
    loadFirebaseAdmin: firebase.load,
  });

  assert.equal(sender.name, 'log');
  assert.match(logger.lines.warn[0], /could not be initialised.*bad credentials/);
});

test('createPushSender: firebase-admin failing to load falls back too', async () => {
  const logger = recordingLogger();
  const sender = await createPushSender({
    config: { enabled: true, serviceAccount: serviceAccountJson },
    logger,
    loadFirebaseAdmin: async () => { throw new Error('module not found'); },
  });

  assert.equal(sender.name, 'log');
  assert.match(logger.lines.warn[0], /module not found/);
});

test('createPushSender: a valid key and a working Firebase gives the FCM sender, initialised from that key', async () => {
  const logger = recordingLogger();
  const firebase = fakeFirebase();
  const sender = await createPushSender({
    config: { enabled: true, serviceAccount: serviceAccountJson },
    logger,
    loadFirebaseAdmin: firebase.load,
  });

  assert.equal(sender.name, 'fcm');
  assert.equal(firebase.calls.cert[0].project_id, 'campus-test');
  assert.equal(firebase.calls.initializeApp[0].name, 'campus-companion', 'a named app, not the default');
  assert.match(logger.lines.log[0], /campus-test/);
  assert.equal(logger.lines.warn.length, 0);
});
