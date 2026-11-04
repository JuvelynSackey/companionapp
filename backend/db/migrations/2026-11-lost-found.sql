-- Adds the shared Lost & Found board to an existing database.
--
--   npm run db:apply -- db/migrations/2026-11-lost-found.sql
--
-- Only creates a new table; nothing existing is changed, and it is safe to
-- run more than once. A fresh `npm run db:setup` already has this (see
-- schema.sql).

BEGIN;

CREATE TABLE IF NOT EXISTS lost_found_items (
    item_id     SERIAL PRIMARY KEY,
    kind        VARCHAR(10)  NOT NULL CHECK (kind IN ('lost', 'found')),
    title       VARCHAR(120) NOT NULL,
    description TEXT,
    location    VARCHAR(160),
    contact     VARCHAR(160),
    status      VARCHAR(10)  NOT NULL DEFAULT 'open'
                CHECK (status IN ('open', 'returned')),
    posted_by   INTEGER      NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    created_at  TIMESTAMPTZ  NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_lost_found_created ON lost_found_items (created_at DESC);

COMMIT;
