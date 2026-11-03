/**
 * Live checks of the external integrations, against the real services:
 *   npm run verify:integrations
 *
 * Prints what was actually demonstrated and what was not. It never prints a
 * credential, and nothing it does reaches a user: the FCM check is a dry run
 * (FCM validates and authorises the message but delivers nothing).
 *
 * What it cannot show, and says so: delivery of a push to a physical phone,
 * a real Google sign-in (that needs a person and a device), and Gemini when
 * no GEMINI_API_KEY is set in the environment running this script.
 */
import { config } from '../config/env.js';
import { getSharedFirebaseApp } from '../services/firebaseAdminApp.js';

const results = [];
function report(name, status, detail) {
  results.push({ name, status, detail });
  console.log(`  ${status.padEnd(14)} ${name}${detail ? ` — ${detail}` : ''}`);
}

async function firebaseChecks() {
  console.log('\nFirebase (service account in backend/.env)');
  if (!config.push.serviceAccount) {
    report('Firebase credential', 'NOT CONFIGURED', 'FIREBASE_SERVICE_ACCOUNT is empty');
    return;
  }

  let app;
  let projectId;
  try {
    ({ app, projectId } = await getSharedFirebaseApp(config.push.serviceAccount));
    report('Firebase credential', 'VERIFIED', `loads for project ${projectId}`);
  } catch (err) {
    report('Firebase credential', 'FAILED', err.message);
    return;
  }

  // FCM: a dry-run send to a topic needs no device token, but FCM still checks
  // that this credential may send for the project and that the message is valid.
  try {
    const { getMessaging } = await import('firebase-admin/messaging');
    const id = await getMessaging(app).send(
      { topic: 'campus-companion-integration-check', notification: { title: 'Integration check', body: 'Dry run, not delivered.' } },
      true,
    );
    report('FCM send authorisation (dry run)', 'VERIFIED', `FCM accepted the message (${id.split('/').pop()}); nothing was delivered`);
  } catch (err) {
    report('FCM send authorisation (dry run)', 'FAILED', err.code ?? err.message);
  }
  report('Push delivery to a physical phone', 'NOT TESTED', 'needs a phone running a build with FCM_ENABLED=true');

  // Google provider: read the project's Firebase Auth config with the same credential.
  try {
    const token = await app.options.credential.getAccessToken();
    const res = await fetch(
      `https://identitytoolkit.googleapis.com/admin/v2/projects/${projectId}/defaultSupportedIdpConfigs/google.com`,
      { headers: { Authorization: `Bearer ${token.access_token}` } },
    );
    if (res.status === 404) {
      report('Google sign-in provider', 'NOT ENABLED', 'Google is not set up as a sign-in provider in Firebase Authentication');
    } else if (res.ok) {
      const body = await res.json();
      report('Google sign-in provider', body.enabled ? 'ENABLED' : 'NOT ENABLED',
        body.enabled ? 'enabled in Firebase Authentication' : 'configured but switched off in Firebase Authentication');
    } else {
      report('Google sign-in provider', 'UNKNOWN', `could not read the Auth config (HTTP ${res.status})`);
    }
  } catch (err) {
    report('Google sign-in provider', 'UNKNOWN', err.message);
  }

  // The backend's own verification path: a garbage ID token must be rejected
  // as invalid by real Firebase (the smoke test checks the same through the API).
  try {
    const { getAuth } = await import('firebase-admin/auth');
    await getAuth(app).verifyIdToken('not-a-real-token');
    report('Backend ID-token verification', 'FAILED', 'a garbage token was accepted');
  } catch (err) {
    report('Backend ID-token verification', err.code === 'auth/argument-error' ? 'VERIFIED' : 'FAILED',
      err.code === 'auth/argument-error' ? 'real Firebase rejects an invalid token' : (err.code ?? err.message));
  }
  report('End-to-end Google sign-in', 'NOT TESTED', 'needs the provider enabled, the app fingerprint registered and a person signing in on a device');
}

async function geminiCheck() {
  console.log('\nGemini');
  const key = process.env.GEMINI_API_KEY;
  if (!key) {
    report('Gemini API key', 'NOT CONFIGURED', 'GEMINI_API_KEY is not set; the app uses its local fallback engine');
    return;
  }
  try {
    const res = await fetch('https://generativelanguage.googleapis.com/v1beta/models?pageSize=1', {
      headers: { 'x-goog-api-key': key },
    });
    report('Gemini API key', res.ok ? 'VERIFIED' : 'FAILED', res.ok ? 'the key is accepted by the Gemini API' : `HTTP ${res.status}`);
  } catch (err) {
    report('Gemini API key', 'FAILED', err.message);
  }
}

console.log('Campus Companion: live integration checks');
await firebaseChecks();
await geminiCheck();
const failed = results.filter((r) => r.status === 'FAILED').length;
console.log(`\n${results.filter((r) => r.status === 'VERIFIED').length} verified, ${failed} failed, `
  + `${results.filter((r) => !['VERIFIED', 'FAILED'].includes(r.status)).length} not verified (see above)`);
process.exit(failed ? 1 : 0);
