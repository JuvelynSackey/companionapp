import express from 'express';
import cors from 'cors';
import morgan from 'morgan';
import { config } from './config/env.js';
import { pool } from './config/db.js';
import apiRoutes from './routes/index.js';
import { getNotificationService } from './services/push.js';

const app = express();

app.use(cors());
app.use(express.json());
app.use(morgan(config.nodeEnv === 'production' ? 'combined' : 'dev'));

// Liveness probe, and a quick way to confirm the database is reachable.
app.get('/api/health', async (_req, res) => {
  try {
    await pool.query('SELECT 1');
    return res.json({ status: 'ok', database: 'connected' });
  } catch {
    return res.status(503).json({ status: 'degraded', database: 'unreachable' });
  }
});

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
  // Build the push service now so a misconfigured key shows up in the boot log,
  // not on the first announcement.
  getNotificationService().catch((err) => console.error('Push service failed to start:', err));
});
