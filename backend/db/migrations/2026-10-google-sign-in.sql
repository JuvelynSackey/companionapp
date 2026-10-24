-- Adds Google Sign-In support to an existing database: makes password_hash
-- nullable (a Google-only account has no password) and adds google_uid.
--
--   npm run db:apply -- db/migrations/2026-10-google-sign-in.sql
--
-- Safe to run more than once, and it keeps all existing data: every existing
-- row already has a password_hash, so dropping the NOT NULL and adding the
-- "has at least one login method" check does not reject anything that is
-- already there. A fresh `npm run db:setup` already has this (see schema.sql).

BEGIN;

ALTER TABLE users ALTER COLUMN password_hash DROP NOT NULL;
ALTER TABLE users ADD COLUMN IF NOT EXISTS google_uid VARCHAR(128) UNIQUE;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'chk_has_a_login_method'
  ) THEN
    ALTER TABLE users ADD CONSTRAINT chk_has_a_login_method
      CHECK (password_hash IS NOT NULL OR google_uid IS NOT NULL);
  END IF;
END $$;

COMMIT;
