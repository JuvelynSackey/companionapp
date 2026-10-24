import { config } from '../config/env.js';
import { createGoogleIdTokenVerifier } from './googleIdTokenVerifier.js';

/**
 * The app-wide Google ID token verifier, built once on first use from the
 * environment (GOOGLE_SIGN_IN_ENABLED / FIREBASE_SERVICE_ACCOUNT — the same
 * credential push notifications use). Callers get a promise so building it
 * (which may load firebase-admin) never blocks a request. Resolves to null
 * when Google sign-in is off or misconfigured; the controller turns that
 * into a 503.
 */
let verifierPromise;

export function getGoogleIdTokenVerifier() {
  verifierPromise ??= createGoogleIdTokenVerifier({ config: config.googleSignIn });
  return verifierPromise;
}
