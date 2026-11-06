-- Students can record their own results (marked self_reported, kept apart
-- from official grades), and Lost & Found posts can carry one photo. The
-- photo lives in the database because the free host's disk is wiped on
-- every restart. Safe to re-run; adds columns only.
ALTER TABLE grades ADD COLUMN IF NOT EXISTS self_reported BOOLEAN NOT NULL DEFAULT false;
ALTER TABLE lost_found_items ADD COLUMN IF NOT EXISTS photo BYTEA;
ALTER TABLE lost_found_items ADD COLUMN IF NOT EXISTS photo_type VARCHAR(20);
