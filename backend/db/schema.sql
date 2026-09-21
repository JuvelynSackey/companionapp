-- ============================================================
-- Campus Companion App - PostgreSQL schema
-- Implements the ERD from the project proposal (section 2.3),
-- with the normalisation notes recorded in docs/schema-notes.md
-- ============================================================

DROP TABLE IF EXISTS device_tokens     CASCADE;
DROP TABLE IF EXISTS event_registrations CASCADE;
DROP TABLE IF EXISTS club_memberships  CASCADE;
DROP TABLE IF EXISTS announcements     CASCADE;
DROP TABLE IF EXISTS events            CASCADE;
DROP TABLE IF EXISTS clubs             CASCADE;
DROP TABLE IF EXISTS grades            CASCADE;
DROP TABLE IF EXISTS schedules         CASCADE;
DROP TABLE IF EXISTS quiz_attempt_answers CASCADE;
DROP TABLE IF EXISTS quiz_attempts     CASCADE;
DROP TABLE IF EXISTS quiz_questions    CASCADE;
DROP TABLE IF EXISTS quizzes           CASCADE;
DROP TABLE IF EXISTS courses           CASCADE;
DROP TABLE IF EXISTS locations         CASCADE;
DROP TABLE IF EXISTS users             CASCADE;

-- ------------------------------------------------------------
-- USER  (proposal entity 1)
-- ------------------------------------------------------------
CREATE TABLE users (
    user_id       SERIAL PRIMARY KEY,
    full_name     VARCHAR(120)  NOT NULL,
    email         VARCHAR(160)  NOT NULL UNIQUE,
    password_hash VARCHAR(255)  NOT NULL,   -- bcrypt hash, never the raw password
    role          VARCHAR(20)   NOT NULL DEFAULT 'student'
                  CHECK (role IN ('student', 'lecturer', 'admin')),
    -- Durable per-user watermark for AnnouncementPushBridge: the highest
    -- announcement_id already surfaced as a notification. Server-side (not
    -- per-device) so a student signed in on two devices, or reinstalling,
    -- doesn't miss announcements posted while only one was online. 0 means
    -- "never synced" — the first sync baselines to the current max id
    -- instead of notifying for every historical announcement.
    last_synced_announcement_id INTEGER NOT NULL DEFAULT 0,
    -- Whether this user wants push notifications at all. Checked by the server
    -- before it sends; the OS-level permission on the device is separate.
    push_enabled  BOOLEAN       NOT NULL DEFAULT TRUE,
    created_at    TIMESTAMPTZ   NOT NULL DEFAULT now()
);

-- Email lookups happen on every login, so index the lower-cased form
-- to keep sign-in case-insensitive without a sequential scan.
CREATE UNIQUE INDEX idx_users_email_lower ON users (LOWER(email));

-- ------------------------------------------------------------
-- DEVICE_TOKEN  (push notifications; see docs/push-notifications.md)
-- One row per app install that has registered for push. The token is unique
-- across ALL users, so registering it again from another account moves it to
-- that account: a phone that is signed out and back in as someone else must
-- stop receiving the previous person's notifications.
-- ------------------------------------------------------------
CREATE TABLE device_tokens (
    token_id   SERIAL PRIMARY KEY,
    user_id    INTEGER      NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    token      TEXT         NOT NULL UNIQUE,
    platform   VARCHAR(10)  NOT NULL CHECK (platform IN ('android', 'ios', 'web')),
    created_at TIMESTAMPTZ  NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ  NOT NULL DEFAULT now()
);

CREATE INDEX idx_device_tokens_user ON device_tokens (user_id);

-- ------------------------------------------------------------
-- COURSE  (not in the proposal ERD - see docs/schema-notes.md)
-- The proposal stored course_name as free text on BOTH schedules
-- and grades. That allows "Mathematics" in one table and "Maths"
-- in the other for the same course, so course is lifted into its
-- own entity and referenced by key.
-- ------------------------------------------------------------
CREATE TABLE courses (
    course_id     SERIAL PRIMARY KEY,
    course_code   VARCHAR(20)   NOT NULL UNIQUE,   -- e.g. 'DCIT 205'
    course_title  VARCHAR(160)  NOT NULL,          -- e.g. 'Mathematics'
    lecturer_name VARCHAR(120),
    credit_hours  SMALLINT      NOT NULL DEFAULT 3
                  CHECK (credit_hours BETWEEN 1 AND 6)
);

-- ------------------------------------------------------------
-- QUIZ  (Phase 3: interactive learning — not in the original
-- proposal ERD). A quiz is course-anchored and either hand-authored
-- by a lecturer/admin or curated from a real past-paper PDF (see
-- docs/schema-notes.md-style rationale in the mobile PastPaperImport
-- flow — extraction always happens client-side; the backend only
-- ever receives the final structured question set, never raw PDF
-- bytes or AI calls).
-- ------------------------------------------------------------
CREATE TABLE quizzes (
    quiz_id     SERIAL PRIMARY KEY,
    course_id   INTEGER NOT NULL REFERENCES courses(course_id) ON DELETE CASCADE,
    title       VARCHAR(160) NOT NULL,
    source      VARCHAR(20) NOT NULL DEFAULT 'manual'
                CHECK (source IN ('manual', 'past_paper')),
    created_by  INTEGER REFERENCES users(user_id) ON DELETE SET NULL,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_quizzes_course ON quizzes(course_id);

-- Two question shapes share one table: multiple_choice (options +
-- correct_option index) and open_ended (model_answer only, no
-- options) — many real past exam papers are essay/structured-answer
-- format, not MCQ, so a single rigid MCQ-only shape would not fit them.
CREATE TABLE quiz_questions (
    question_id     SERIAL PRIMARY KEY,
    quiz_id         INTEGER NOT NULL REFERENCES quizzes(quiz_id) ON DELETE CASCADE,
    question_type   VARCHAR(20) NOT NULL
                    CHECK (question_type IN ('multiple_choice', 'open_ended')),
    question_text   TEXT NOT NULL,
    options         JSONB,      -- array of option strings; multiple_choice only
    correct_option  SMALLINT,   -- index into options; multiple_choice only
    model_answer    TEXT,       -- open_ended model answer, or an MCQ explanation
    order_index     SMALLINT NOT NULL DEFAULT 0
);

CREATE INDEX idx_quiz_questions_quiz ON quiz_questions(quiz_id);

-- One row per student attempt. score/total_graded cover only the
-- auto-gradable (multiple_choice) questions in the quiz — open_ended
-- answers are self-marked by the student against the revealed model
-- answer, not server-scored.
CREATE TABLE quiz_attempts (
    attempt_id    SERIAL PRIMARY KEY,
    quiz_id       INTEGER NOT NULL REFERENCES quizzes(quiz_id) ON DELETE CASCADE,
    user_id       INTEGER NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    score         NUMERIC(5,2),
    total_graded  SMALLINT,
    completed_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_quiz_attempts_user ON quiz_attempts(user_id);

CREATE TABLE quiz_attempt_answers (
    attempt_id        INTEGER NOT NULL REFERENCES quiz_attempts(attempt_id) ON DELETE CASCADE,
    question_id       INTEGER NOT NULL REFERENCES quiz_questions(question_id) ON DELETE CASCADE,
    selected_option   SMALLINT,
    free_text_answer  TEXT,
    is_correct        BOOLEAN,
    PRIMARY KEY (attempt_id, question_id)
);

-- ------------------------------------------------------------
-- SCHEDULE  (proposal entity 2)
-- Proposal had day + time as plain strings. Using a numbered day
-- and real TIME columns lets the API sort a timetable correctly
-- and work out "what class is on now" for the dashboard.
-- ------------------------------------------------------------
CREATE TABLE schedules (
    schedule_id SERIAL PRIMARY KEY,
    user_id     INTEGER  NOT NULL REFERENCES users(user_id)   ON DELETE CASCADE,
    course_id   INTEGER  NOT NULL REFERENCES courses(course_id) ON DELETE CASCADE,
    day_of_week SMALLINT NOT NULL CHECK (day_of_week BETWEEN 1 AND 7),  -- 1 = Monday
    start_time  TIME     NOT NULL,
    end_time    TIME     NOT NULL,
    room        VARCHAR(80),
    CONSTRAINT chk_schedule_time_order CHECK (end_time > start_time),
    -- the same course cannot be timetabled twice in one slot for one student
    CONSTRAINT uq_schedule_slot UNIQUE (user_id, course_id, day_of_week, start_time)
);

CREATE INDEX idx_schedules_user_day ON schedules (user_id, day_of_week, start_time);

-- ------------------------------------------------------------
-- GRADE  (proposal entity 3)
-- letter_grade is GENERATED from score using the University of Ghana
-- undergraduate scale, so the two columns can never drift out of sync.
-- The grade points for each letter are in gradeController.js
-- (GRADE_POINTS) and the app's academic_engine.dart; the whole table is
-- also in docs/grading-scale-ug.json, which the tests check all three
-- against. Change them together. Existing databases need
-- db/migrations/2026-09-ug-grading-scale.sql (this file only affects a
-- fresh `npm run db:setup`).
-- ------------------------------------------------------------
CREATE TABLE grades (
    grade_id    SERIAL PRIMARY KEY,
    user_id     INTEGER      NOT NULL REFERENCES users(user_id)     ON DELETE CASCADE,
    course_id   INTEGER      NOT NULL REFERENCES courses(course_id) ON DELETE CASCADE,
    score       NUMERIC(5,2) NOT NULL CHECK (score >= 0 AND score <= 100),
    semester    VARCHAR(40)  NOT NULL DEFAULT 'Semester 1 - 2025/2026',
    recorded_at TIMESTAMPTZ  NOT NULL DEFAULT now(),
    letter_grade VARCHAR(2) GENERATED ALWAYS AS (
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
    ) STORED,
    CONSTRAINT uq_grade_per_course UNIQUE (user_id, course_id, semester)
);

CREATE INDEX idx_grades_user ON grades (user_id);

-- ------------------------------------------------------------
-- CLUB  (proposal entity 6)
-- ------------------------------------------------------------
CREATE TABLE clubs (
    club_id     SERIAL PRIMARY KEY,
    name        VARCHAR(120) NOT NULL UNIQUE,
    description TEXT
);

-- ------------------------------------------------------------
-- EVENT  (proposal entity 5)
-- club_id added to satisfy the stated relationship "Clubs organize
-- Events", which the proposal listed but did not draw.
-- ------------------------------------------------------------
CREATE TABLE events (
    event_id    SERIAL PRIMARY KEY,
    title       VARCHAR(160) NOT NULL,
    description TEXT,
    event_date  TIMESTAMPTZ  NOT NULL,
    location    VARCHAR(160),
    club_id     INTEGER REFERENCES clubs(club_id)  ON DELETE SET NULL,
    created_by  INTEGER REFERENCES users(user_id)  ON DELETE SET NULL
);

CREATE INDEX idx_events_date ON events (event_date);

-- ------------------------------------------------------------
-- ANNOUNCEMENT  (proposal entity 4)
-- ------------------------------------------------------------
CREATE TABLE announcements (
    announcement_id SERIAL PRIMARY KEY,
    title           VARCHAR(160) NOT NULL,
    message         TEXT         NOT NULL,
    category        VARCHAR(30)  NOT NULL DEFAULT 'general'
                    CHECK (category IN ('general', 'academic', 'emergency')),
    posted_by       INTEGER REFERENCES users(user_id) ON DELETE SET NULL,
    date_posted     TIMESTAMPTZ  NOT NULL DEFAULT now()
);

CREATE INDEX idx_announcements_posted ON announcements (date_posted DESC);

-- ------------------------------------------------------------
-- USER_CLUB junction  (resolves User <-> Club many-to-many)
-- ------------------------------------------------------------
CREATE TABLE club_memberships (
    user_id   INTEGER     NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    club_id   INTEGER     NOT NULL REFERENCES clubs(club_id) ON DELETE CASCADE,
    joined_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (user_id, club_id)
);

-- ------------------------------------------------------------
-- EVENT_REGISTRATION junction
-- Implements "A User can register for many Events" (proposal p.18),
-- which had no table in the ERD.
-- ------------------------------------------------------------
CREATE TABLE event_registrations (
    user_id       INTEGER     NOT NULL REFERENCES users(user_id)   ON DELETE CASCADE,
    event_id      INTEGER     NOT NULL REFERENCES events(event_id) ON DELETE CASCADE,
    registered_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (user_id, event_id)
);

-- ------------------------------------------------------------
-- LOCATION  (campus map, Module 6)
-- The proposal specifies an interactive campus map but the ERD had
-- nowhere to store the places being mapped.
-- ------------------------------------------------------------
CREATE TABLE locations (
    location_id SERIAL PRIMARY KEY,
    name        VARCHAR(160)  NOT NULL,
    category    VARCHAR(40)   NOT NULL DEFAULT 'other'
                CHECK (category IN ('lecture_hall','library','laboratory',
                                    'cafeteria','office','hostel','other')),
    description TEXT,
    latitude    NUMERIC(9,6)  NOT NULL CHECK (latitude  BETWEEN  -90 AND  90),
    longitude   NUMERIC(9,6)  NOT NULL CHECK (longitude BETWEEN -180 AND 180)
);

CREATE INDEX idx_locations_category ON locations (category);
