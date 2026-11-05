import 'dotenv/config';

/**
 * Reads a required environment variable, failing fast at boot rather than
 * letting the server start and then break on the first request.
 */
function required(name) {
  const value = process.env[name];
  if (!value) {
    throw new Error(
      `Missing required environment variable ${name}. ` +
        'Copy .env.example to .env and fill it in.'
    );
  }
  return value;
}

export const config = {
  port: Number(process.env.PORT ?? 4000),
  nodeEnv: process.env.NODE_ENV ?? 'development',

  // A hosted database (Render, Neon, ...) gives one connection URL. When it is
  // set it replaces the DB_* settings below, and SSL is used.
  databaseUrl: process.env.DATABASE_URL ?? '',

  db: {
    host: process.env.DB_HOST ?? 'localhost',
    port: Number(process.env.DB_PORT ?? 5432),
    database: process.env.DB_NAME ?? 'campus_companion',
    user: process.env.DB_USER ?? 'postgres',
    password: process.env.DATABASE_URL ? process.env.DB_PASSWORD ?? '' : required('DB_PASSWORD'),
  },

  jwt: {
    secret: required('JWT_SECRET'),
    expiresIn: process.env.JWT_EXPIRES_IN ?? '7d',
  },

  // Push notifications. Off unless FCM_ENABLED=true; then FIREBASE_SERVICE_ACCOUNT
  // must hold the service-account key JSON (as a single line). If it is missing
  // or wrong the API still starts and pushes are only logged, see services/pushSenders.js.
  push: {
    enabled: process.env.FCM_ENABLED === 'true',
    serviceAccount: process.env.FIREBASE_SERVICE_ACCOUNT ?? '',
  },

  // Google Sign-In. Off unless GOOGLE_SIGN_IN_ENABLED=true; shares
  // FIREBASE_SERVICE_ACCOUNT with push (see services/googleIdTokenVerifier.js).
  // A wrong or missing key logs a warning and leaves it off, same as push.
  googleSignIn: {
    enabled: process.env.GOOGLE_SIGN_IN_ENABLED === 'true',
    serviceAccount: process.env.FIREBASE_SERVICE_ACCOUNT ?? '',
  },
};
