-- Adds push-notification support to an existing database: a per-user on/off
-- preference and the table of registered device tokens.
--
--   npm run db:apply -- db/migrations/2026-09-push-notifications.sql
--
-- Safe to run more than once, and it keeps all existing data. A fresh
-- `npm run db:setup` already has this (see schema.sql).

BEGIN;

ALTER TABLE users ADD COLUMN IF NOT EXISTS push_enabled BOOLEAN NOT NULL DEFAULT TRUE;

CREATE TABLE IF NOT EXISTS device_tokens (
    token_id   SERIAL PRIMARY KEY,
    user_id    INTEGER      NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    token      TEXT         NOT NULL UNIQUE,
    platform   VARCHAR(10)  NOT NULL CHECK (platform IN ('android', 'ios', 'web')),
    created_at TIMESTAMPTZ  NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ  NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_device_tokens_user ON device_tokens (user_id);

COMMIT;
