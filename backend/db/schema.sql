-- ============================================================
-- Campus Companion App - PostgreSQL schema
-- Implements the ERD from the project proposal (section 2.3),
-- with the normalisation notes recorded in docs/schema-notes.md
-- ============================================================

DROP TABLE IF EXISTS event_registrations CASCADE;
DROP TABLE IF EXISTS club_memberships  CASCADE;
DROP TABLE IF EXISTS announcements     CASCADE;
DROP TABLE IF EXISTS events            CASCADE;
DROP TABLE IF EXISTS clubs             CASCADE;
DROP TABLE IF EXISTS grades            CASCADE;
DROP TABLE IF EXISTS schedules         CASCADE;
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
                  CHECK (role IN ('student', 'admin')),
    created_at    TIMESTAMPTZ   NOT NULL DEFAULT now()
);

-- Email lookups happen on every login, so index the lower-cased form
-- to keep sign-in case-insensitive without a sequential scan.
CREATE UNIQUE INDEX idx_users_email_lower ON users (LOWER(email));

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
-- letter_grade is GENERATED from score using the grading scale
-- printed on the proposal's Grades mock-up (page 25), so the two
-- columns can never drift out of sync.
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
            WHEN score >= 90 THEN 'A+'
            WHEN score >= 80 THEN 'A'
            WHEN score >= 75 THEN 'B+'
            WHEN score >= 70 THEN 'B'
            WHEN score >= 60 THEN 'C'
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
