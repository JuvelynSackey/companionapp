/**
 * Offline unit tests for the account lookup in registration and login
 * (no database):  npm test
 */
import '../testing/testEnv.js';
import { test, afterEach, before } from 'node:test';
import assert from 'node:assert/strict';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import { installFakeDb, callController } from '../testing/fakeDb.js';
import { config } from '../config/env.js';
import { register, login, registerSchema, loginSchema } from './authController.js';

let db;
afterEach(() => db?.restore());

// A cheap hash for the stored account; bcrypt.compare works at any cost.
let storedHash;
before(async () => {
  storedHash = await bcrypt.hash('correct horse', 4);
});

const kojo = () => ({ user_id: 3, full_name: 'Kojo Mensah', email: 'kojo@ug.edu.gh', role: 'student', password_hash: storedHash });

test('register: an email already in use (in any letter case) is a 409, and nothing is inserted', async () => {
  db = installFakeDb(() => ({ rowCount: 1, rows: [{}] }));
  const { status, body } = await callController(register, {
    body: { fullName: 'Kojo Mensah', email: 'kojo@ug.edu.gh', password: 'long enough' },
  });

  assert.equal(status, 409);
  assert.deepEqual(body, { error: 'An account with that email already exists' });
  assert.match(db.calls[0].sql, /WHERE LOWER\(email\) = LOWER\(\$1\)/, 'the lookup ignores letter case');
  assert.equal(db.calls.length, 1);
});

test('register: a new account is always a student, its password is stored only as a hash', async () => {
  db = installFakeDb((sql) => (sql.startsWith('SELECT')
    ? { rowCount: 0 }
    : { rows: [{ user_id: 50, full_name: 'Ama Owusu', email: 'ama@ug.edu.gh', role: 'student' }] }));

  const { status, body } = await callController(register, {
    // A client trying to choose its own role is ignored.
    body: { fullName: 'Ama Owusu', email: 'ama@ug.edu.gh', password: 'long enough', role: 'admin' },
  });

  assert.equal(status, 201);
  const insert = db.calls[1];
  assert.match(insert.sql, /VALUES \(\$1, \$2, \$3, 'student'\)/, 'the role is fixed in the SQL, not taken from the request');
  assert.notEqual(insert.params[2], 'long enough');
  assert.equal(await bcrypt.compare('long enough', insert.params[2]), true);
  assert.deepEqual(body.user, {
    userId: 50, fullName: 'Ama Owusu', email: 'ama@ug.edu.gh', role: 'student', permissions: body.user.permissions,
  });
  assert.equal(jwt.verify(body.token, config.jwt.secret).sub, 50);
});

test('login: the right password signs in, and the hash never leaves the server', async () => {
  db = installFakeDb(() => ({ rows: [kojo()] }));
  const { status, body } = await callController(login, { body: { email: 'kojo@ug.edu.gh', password: 'correct horse' } });

  assert.equal(status, 200);
  assert.equal(body.user.email, 'kojo@ug.edu.gh');
  assert.equal('password_hash' in body.user, false);
  assert.doesNotMatch(JSON.stringify(body), /\$2[aby]\$/, 'no bcrypt hash anywhere in the reply');
  const claims = jwt.verify(body.token, config.jwt.secret);
  assert.equal(claims.sub, 3);
  assert.equal(claims.role, 'student');
  assert.match(db.calls[0].sql, /WHERE LOWER\(email\) = LOWER\(\$1\)/);
});

test('login: a wrong password and an unknown email get the same answer', async () => {
  db = installFakeDb(() => ({ rows: [kojo()] }));
  const wrongPassword = await callController(login, { body: { email: 'kojo@ug.edu.gh', password: 'wrong' } });
  db.restore();

  db = installFakeDb(() => ({ rows: [] }));
  const noAccount = await callController(login, { body: { email: 'nobody@ug.edu.gh', password: 'wrong' } });

  for (const result of [wrongPassword, noAccount]) {
    assert.equal(result.status, 401);
    assert.deepEqual(result.body, { error: 'Incorrect email or password' });
  }
});

test('the schemas trim and lower-case the email, so the lookup matches however it was typed', () => {
  assert.equal(loginSchema.parse({ email: '  Kojo@UG.edu.gh ', password: 'x' }).email, 'kojo@ug.edu.gh');
  assert.equal(registerSchema.parse({ fullName: 'Kojo', email: 'KOJO@ug.edu.gh', password: 'long enough' }).email, 'kojo@ug.edu.gh');
  assert.equal(registerSchema.safeParse({ fullName: 'Kojo', email: 'kojo@ug.edu.gh', password: 'short' }).success, false);
});

test('an unexpected database failure is passed on to the error handler', async () => {
  const failure = new Error('connection lost');
  db = installFakeDb(() => { throw failure; });
  assert.equal((await callController(login, { body: { email: 'kojo@ug.edu.gh', password: 'x' } })).error, failure);
});
