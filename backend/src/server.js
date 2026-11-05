import express from 'express';
import cors from 'cors';
import morgan from 'morgan';
import { config } from './config/env.js';
import { pool } from './config/db.js';
import apiRoutes from './routes/index.js';
import { getNotificationService } from './services/push.js';
import { getGoogleIdTokenVerifier } from './services/googleAuth.js';

const app = express();

app.use(cors());
app.use(express.json());
app.use(morgan(config.nodeEnv === 'production' ? 'combined' : 'dev'));

// Liveness probe, and a quick way to confirm the database is reachable.
app.get('/api/health', async (_req, res) => {
  try {
    await pool.query('SELECT 1');
    return res.json({
      status: 'ok',
      database: 'connected',
      // Deployment diagnostics: on/off flags and the key's format only, never
      // its contents. Push shares the key, so it is on whenever this is.
      googleSignIn: (await getGoogleIdTokenVerifier()) ? 'on' : 'off',
      firebaseKeyFormat: firebaseKeyFormat(),
      ...(firebaseKeyFormat() === 'unreadable' ? unreadableKeyHint() : {}),
      commit: process.env.RENDER_GIT_COMMIT?.slice(0, 7) ?? 'local',
    });
  } catch {
    return res.status(503).json({ status: 'degraded', database: 'unreachable' });
  }
});

function firebaseKeyFormat() {
  const raw = (process.env.FIREBASE_SERVICE_ACCOUNT ?? '').trim();
  if (!raw) return 'missing';
  try {
    JSON.parse(config.push.serviceAccount);
  } catch {
    return 'unreadable';
  }
  if (raw.startsWith('{')) return 'json';
  return raw.startsWith("'") || raw.startsWith('"') ? 'quoted-json' : 'base64';
}

// Only when the key cannot be read: its length and first four characters
// (a JSON key starts '{"ty', a base64 one 'eyJ0'), enough to tell what was
// pasted without revealing the key.
function unreadableKeyHint() {
  const raw = (process.env.FIREBASE_SERVICE_ACCOUNT ?? '').trim();
  return { firebaseKeyLength: raw.length, firebaseKeyStart: raw.slice(0, 4) };
}

app.use('/api', apiRoutes);

app.use((_req, res) => {
  res.status(404).json({ error: 'Route not found' });
});

// Central error handler. Without this, a thrown error in an async controller
// would hang the request instead of answering it.
app.use((err, _req, res, _next) => {
  console.error(err);
  res.status(500).json({ error: 'Internal server error' });
});

app.listen(config.port, () => {
  console.log(`Campus Companion API listening on http://localhost:${config.port}`);
  // Build these now so a misconfigured key shows up in the boot log, not on
  // the first announcement / first Google sign-in attempt. Both share one
  // Firebase app (services/firebaseAdminApp.js) and the same credential.
  getNotificationService().catch((err) => console.error('Push service failed to start:', err));
  getGoogleIdTokenVerifier().catch((err) => console.error('Google sign-in failed to start:', err));
});
