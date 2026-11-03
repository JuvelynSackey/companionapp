/**
 * Offline tests for optionalAuth, the gate on the guest-readable routes:  npm test
 */
import { test } from 'node:test';
import assert from 'node:assert/strict';
import jwt from 'jsonwebtoken';

// config/env.js fails fast without these; .env may not exist where tests run.
process.env.DB_PASSWORD ??= 'unused-in-these-tests';
process.env.JWT_SECRET ??= 'test-secret';
const { optionalAuth } = await import('./auth.js');
const { config } = await import('../config/env.js');

function run(headers) {
  const req = { headers };
  const res = {
    statusCode: 200,
    status(code) { this.statusCode = code; return this; },
    json(body) { this.body = body; return this; },
  };
  let nextCalled = false;
  optionalAuth(req, res, () => { nextCalled = true; });
  return { req, res, nextCalled };
}

test('no Authorization header continues as a guest', () => {
  const { req, res, nextCalled } = run({});
  assert.equal(nextCalled, true);
  assert.equal(req.user, null);
  assert.equal(res.statusCode, 200);
});

test('a valid token attaches the caller, like requireAuth', () => {
  const token = jwt.sign({ sub: 7, role: 'student' }, config.jwt.secret);
  const { req, nextCalled } = run({ authorization: `Bearer ${token}` });
  assert.equal(nextCalled, true);
  assert.deepEqual(req.user, { userId: 7, role: 'student' });
});

test('a bad token is still a 401, not a silent guest', () => {
  const { res, nextCalled } = run({ authorization: 'Bearer not-a-real-token' });
  assert.equal(nextCalled, false);
  assert.equal(res.statusCode, 401);
});

test('a malformed header is still a 401', () => {
  const { res, nextCalled } = run({ authorization: 'Basic abc' });
  assert.equal(nextCalled, false);
  assert.equal(res.statusCode, 401);
});
