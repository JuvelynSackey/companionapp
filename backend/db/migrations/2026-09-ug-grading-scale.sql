-- Moves an existing database from the proposal's grading scale
-- (A+ >= 90, A >= 80, B+ >= 75, B >= 70, C >= 60, else F) to the University
-- of Ghana undergraduate scale, keeping every recorded score.
--
--   npm run db:apply -- db/migrations/2026-09-ug-grading-scale.sql
--
-- letter_grade is a GENERATED column, so it cannot be altered in place: it is
-- dropped and re-added, and Postgres recomputes it for every existing row.
-- Safe to run more than once. A fresh `npm run db:setup` already has this
-- (see schema.sql) and does not need it.
--
-- Deploy the matching gradeController.js (new GRADE_POINTS) with this: the
-- old code has no grade points for C+, D+, D or E.

BEGIN;

ALTER TABLE grades DROP COLUMN IF EXISTS letter_grade;

ALTER TABLE grades ADD COLUMN letter_grade VARCHAR(2) GENERATED ALWAYS AS (
    CASE
        WHEN score >= 80 THEN 'A'
        WHEN score >= 75 THEN 'B+'
        WHEN score >= 70 THEN 'B'
        WHEN score >= 65 THEN 'C+'
        WHEN score >= 60 THEN 'C'
        WHEN score >= 55 THEN 'D+'
        WHEN score >= 50 THEN 'D'
        WHEN score >= 45 THEN 'E'
        ELSE 'F'
    END
) STORED;

COMMIT;
