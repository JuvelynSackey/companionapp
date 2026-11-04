/**
 * Imported first by controller unit tests, before anything that loads
 * config/env.js. The config insists on these two values; unit tests never
 * open a database connection or need a real secret, so fixed stand-ins keep
 * the tests independent of backend/.env (and runnable in CI, which has none).
 */
process.env.DB_PASSWORD ??= 'unused-by-unit-tests';
process.env.JWT_SECRET ??= 'unit-test-secret';
