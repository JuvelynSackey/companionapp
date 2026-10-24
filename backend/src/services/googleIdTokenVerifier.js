/**
 * Verifies a Firebase ID token (issued when the app signs into Firebase with
 * a Google credential — see mobile/lib/core/services/google_auth_service.dart)
 * and returns the account's Google identity. Shares its Firebase app with
 * push notifications (firebaseAdminApp.js): one service-account credential,
 * one app, whichever feature is used first initialises it.
 *
 * No database import here, so it is unit-tested alone, the same way
 * pushSenders.js is.
 */
import { getSharedFirebaseApp } from './firebaseAdminApp.js';

const defaultLoadFirebaseAdmin = async () => {
  const app = await import('firebase-admin/app');
  const auth = await import('firebase-admin/auth');
  return { initializeApp: app.initializeApp, cert: app.cert, getAuth: auth.getAuth };
};

/**
 * Builds the verifier function from config. Never throws while building it —
 * a wrong or missing key here must not stop the API from booting (every
 * other route still works), so it warns and returns null (Google sign-in
 * stays off) instead. The server-account credential is shared with push, so
 * this can come up even when only FCM_ENABLED is set and vice versa.
 *
 * @param config { enabled: boolean, serviceAccount: string (JSON) }
 * @returns `null`, or `async (idToken) => { googleUid, email, name }`. The
 *   returned function throws on an invalid/expired/malformed token — that is
 *   the caller's signal to answer with 401, not a configuration problem.
 */
export async function createGoogleIdTokenVerifier({
  config,
  logger = console,
  loadFirebaseAdmin = defaultLoadFirebaseAdmin,
}) {
  if (!config.enabled) {
    logger.log('Google sign-in: off (GOOGLE_SIGN_IN_ENABLED is not "true").');
    return null;
  }

  const disabled = (reason) => {
    logger.warn(`Google sign-in: GOOGLE_SIGN_IN_ENABLED is true but ${reason}. Google sign-in stays off.`);
    return null;
  };

  if (!config.serviceAccount) return disabled('FIREBASE_SERVICE_ACCOUNT is not set');

  try {
    JSON.parse(config.serviceAccount);
  } catch {
    return disabled('FIREBASE_SERVICE_ACCOUNT is not valid JSON (paste the key file as a single line)');
  }

  try {
    const { app, projectId } = await getSharedFirebaseApp(config.serviceAccount, loadFirebaseAdmin);
    const { getAuth } = await loadFirebaseAdmin();
    const auth = getAuth(app);
    logger.log(`Google sign-in: on (Firebase project ${projectId ?? 'unknown'}).`);

    return async function verifyGoogleIdToken(idToken) {
      const decoded = await auth.verifyIdToken(idToken);
      if (!decoded.email) throw new Error('Google did not provide an email address for this account');
      if (decoded.email_verified === false) {
        throw new Error("Google has not verified this account's email address");
      }
      return {
        googleUid: decoded.uid,
        email: decoded.email.toLowerCase(),
        name: decoded.name ?? decoded.email.split('@')[0],
      };
    };
  } catch (err) {
    return disabled(`Firebase could not be initialised (${err.message})`);
  }
}
