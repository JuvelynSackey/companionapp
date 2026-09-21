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

  db: {
    host: process.env.DB_HOST ?? 'localhost',
    port: Number(process.env.DB_PORT ?? 5432),
    database: process.env.DB_NAME ?? 'campus_companion',
    user: process.env.DB_USER ?? 'postgres',
    password: required('DB_PASSWORD'),
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
};
