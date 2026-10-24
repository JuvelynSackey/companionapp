const defaultLoadApp = async () => {
  const { initializeApp, cert } = await import('firebase-admin/app');
  return { initializeApp, cert };
};

/**
 * One shared, lazily-created Firebase Admin app named 'campus-companion',
 * used by both push (pushSenders.js) and Google sign-in (googleIdTokenVerifier.js)
 * so a single service-account credential backs both, and initializeApp runs
 * exactly once even if both features are first used at nearly the same time
 * on boot.
 *
 * Rejects (never throws synchronously) on a missing/invalid credential or if
 * firebase-admin cannot be loaded; each caller decides its own fallback
 * (push falls back to log-only, Google sign-in returns 503).
 */
let promise = null;

export function getSharedFirebaseApp(serviceAccountJson, loadApp = defaultLoadApp) {
  promise ??= (async () => {
    const { initializeApp, cert } = await loadApp();
    const credentials = JSON.parse(serviceAccountJson);
    const app = initializeApp({ credential: cert(credentials) }, 'campus-companion');
    return { app, projectId: credentials.project_id };
  })();
  return promise;
}

/** Test-only: clears the cached app so the next call rebuilds it from scratch. */
export function _resetSharedFirebaseAppForTests() {
  promise = null;
}
