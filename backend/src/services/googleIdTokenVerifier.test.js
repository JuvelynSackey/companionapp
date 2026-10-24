/**
 * Offline tests for building the Google ID token verifier and for the
 * verifier itself:  npm test
 * Firebase itself is never loaded; a fake stands in for it.
 */
import { test, beforeEach } from 'node:test';
import assert from 'node:assert/strict';
import { createGoogleIdTokenVerifier } from './googleIdTokenVerifier.js';
import { _resetSharedFirebaseAppForTests } from './firebaseAdminApp.js';

// Shares one Firebase app (firebaseAdminApp.js) with push in the real
// process, so a test that initialises it (or fails to) does not leak into
// the next test in this file.
beforeEach(_resetSharedFirebaseAppForTests);

function recordingLogger() {
  const lines = { log: [], warn: [], error: [] };
  return { lines, log: (m) => lines.log.push(m), warn: (m) => lines.warn.push(m), error: (m) => lines.error.push(m) };
}

const serviceAccountJson = JSON.stringify({ project_id: 'campus-test', client_email: 'x@y', private_key: 'k' });

function fakeFirebase({ throwOnInit = false, verifyIdToken } = {}) {
  const calls = { initializeApp: [], cert: [], verifyIdToken: [] };
  const module = {
    initializeApp: (options, name) => {
      if (throwOnInit) throw new Error('bad credentials');
      calls.initializeApp.push({ options, name });
      return { name };
    },
    cert: (credentials) => { calls.cert.push(credentials); return { credentials }; },
    getAuth: () => ({
      verifyIdToken: async (idToken) => {
        calls.verifyIdToken.push(idToken);
        if (verifyIdToken) return verifyIdToken(idToken);
        return { uid: 'google-uid-1', email: 'ama@ug.edu.gh', email_verified: true, name: 'Ama Mensah' };
      },
    }),
  };
  return { calls, load: async () => module };
}

test('off by default, log-only, and Firebase is never loaded', async () => {
  let loaded = false;
  const verifier = await createGoogleIdTokenVerifier({
    config: { enabled: false, serviceAccount: serviceAccountJson },
    logger: recordingLogger(),
    loadFirebaseAdmin: async () => { loaded = true; return {}; },
  });

  assert.equal(verifier, null);
  assert.equal(loaded, false);
});

test('enabled without a key stays off, with a warning, not a crash', async () => {
  const logger = recordingLogger();
  const verifier = await createGoogleIdTokenVerifier({ config: { enabled: true, serviceAccount: '' }, logger });

  assert.equal(verifier, null);
  assert.match(logger.lines.warn[0], /FIREBASE_SERVICE_ACCOUNT is not set/);
});

test('a key that is not JSON stays off with a hint about single-line JSON', async () => {
  const logger = recordingLogger();
  const verifier = await createGoogleIdTokenVerifier({
    config: { enabled: true, serviceAccount: '{ not json' },
    logger,
  });

  assert.equal(verifier, null);
  assert.match(logger.lines.warn[0], /not valid JSON.*single line/);
});

test('Firebase refusing the credentials stays off, and says why', async () => {
  const logger = recordingLogger();
  const firebase = fakeFirebase({ throwOnInit: true });
  const verifier = await createGoogleIdTokenVerifier({
    config: { enabled: true, serviceAccount: serviceAccountJson },
    logger,
    loadFirebaseAdmin: firebase.load,
  });

  assert.equal(verifier, null);
  assert.match(logger.lines.warn[0], /could not be initialised.*bad credentials/);
});

test('firebase-admin failing to load stays off too', async () => {
  const logger = recordingLogger();
  const verifier = await createGoogleIdTokenVerifier({
    config: { enabled: true, serviceAccount: serviceAccountJson },
    logger,
    loadFirebaseAdmin: async () => { throw new Error('module not found'); },
  });

  assert.equal(verifier, null);
  assert.match(logger.lines.warn[0], /module not found/);
});

test('a valid key and a working Firebase gives a verifier function, initialised from that key', async () => {
  const logger = recordingLogger();
  const firebase = fakeFirebase();
  const verifier = await createGoogleIdTokenVerifier({
    config: { enabled: true, serviceAccount: serviceAccountJson },
    logger,
    loadFirebaseAdmin: firebase.load,
  });

  assert.equal(typeof verifier, 'function');
  assert.equal(firebase.calls.cert[0].project_id, 'campus-test');
  assert.equal(firebase.calls.initializeApp[0].name, 'campus-companion', 'a named app, not the default');
  assert.match(logger.lines.log[0], /campus-test/);
  assert.equal(logger.lines.warn.length, 0);
});

test('push and Google sign-in share one Firebase app when both are configured', async () => {
  // Importing createPushSender here (rather than at module scope) keeps this
  // the one test that needs both modules, and avoids a circular-sounding
  // top-of-file import for something only this test cares about.
  const { createPushSender } = await import('./pushSenders.js');
  const firebase = fakeFirebase();

  await createPushSender({
    config: { enabled: true, serviceAccount: serviceAccountJson },
    logger: recordingLogger(),
    loadFirebaseAdmin: firebase.load,
  });
  await createGoogleIdTokenVerifier({
    config: { enabled: true, serviceAccount: serviceAccountJson },
    logger: recordingLogger(),
    loadFirebaseAdmin: firebase.load,
  });

  assert.equal(firebase.calls.initializeApp.length, 1, 'initializeApp ran exactly once for both features');
});

test('the verifier function: a verified Google identity is lower-cased and shaped for the user store', async () => {
  const firebase = fakeFirebase({
    verifyIdToken: async () => ({ uid: 'uid-1', email: 'Ama@UG.EDU.GH', email_verified: true, name: 'Ama Mensah' }),
  });
  const verifier = await createGoogleIdTokenVerifier({
    config: { enabled: true, serviceAccount: serviceAccountJson },
    logger: recordingLogger(),
    loadFirebaseAdmin: firebase.load,
  });

  const identity = await verifier('a-real-looking-id-token');

  assert.deepEqual(identity, { googleUid: 'uid-1', email: 'ama@ug.edu.gh', name: 'Ama Mensah' });
  assert.deepEqual(firebase.calls.verifyIdToken, ['a-real-looking-id-token']);
});

test('the verifier function: a missing display name falls back to the email\'s local part', async () => {
  const firebase = fakeFirebase({
    verifyIdToken: async () => ({ uid: 'uid-2', email: 'kojo@ug.edu.gh', email_verified: true, name: undefined }),
  });
  const verifier = await createGoogleIdTokenVerifier({
    config: { enabled: true, serviceAccount: serviceAccountJson },
    logger: recordingLogger(),
    loadFirebaseAdmin: firebase.load,
  });

  assert.equal((await verifier('t')).name, 'kojo');
});

test('the verifier function: an unverified email is rejected', async () => {
  const firebase = fakeFirebase({
    verifyIdToken: async () => ({ uid: 'uid-3', email: 'x@y.z', email_verified: false, name: 'X' }),
  });
  const verifier = await createGoogleIdTokenVerifier({
    config: { enabled: true, serviceAccount: serviceAccountJson },
    logger: recordingLogger(),
    loadFirebaseAdmin: firebase.load,
  });

  await assert.rejects(() => verifier('t'), /not verified/);
});

test('the verifier function: a token with no email is rejected', async () => {
  const firebase = fakeFirebase({
    verifyIdToken: async () => ({ uid: 'uid-4', email: undefined, name: 'X' }),
  });
  const verifier = await createGoogleIdTokenVerifier({
    config: { enabled: true, serviceAccount: serviceAccountJson },
    logger: recordingLogger(),
    loadFirebaseAdmin: firebase.load,
  });

  await assert.rejects(() => verifier('t'), /email/);
});

test('the verifier function: an invalid/expired token rejects, it does not resolve to something falsy', async () => {
  const firebase = fakeFirebase({
    verifyIdToken: async () => { throw new Error('Firebase ID token has expired'); },
  });
  const verifier = await createGoogleIdTokenVerifier({
    config: { enabled: true, serviceAccount: serviceAccountJson },
    logger: recordingLogger(),
    loadFirebaseAdmin: firebase.load,
  });

  await assert.rejects(() => verifier('an-expired-token'), /expired/);
});
