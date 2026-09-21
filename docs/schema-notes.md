# Schema notes — where the implementation differs from the proposal ERD

The proposal's ERD (section 2.3) was a sketch. Turning it into a working
database surfaced a few things it did not specify. Each change below is
listed with its reason, so it can be defended in the report and written up
in Chapter 4.

## 1. `courses` lifted into its own table

**Proposal:** `Schedule.course_name` and `Grades.course_name`, both free text.

**Problem:** the same course is named independently in two places. Nothing
stops `"Mathematics"` in the timetable and `"Maths"` in the grade record, and
then a query that joins them by name silently returns nothing. Renaming a
course means updating every row in two tables.

**Change:** a `courses` table holding `course_code`, `course_title`,
`lecturer_name` and `credit_hours`. `schedules` and `grades` reference it by
`course_id`.

**Bonus:** the mock-ups show a lecturer name per class (`Prof. A. Mensah`) and
the grades screen shows a GPA. Neither is storable in the original ERD —
there was no lecturer field, and no credit hours to weight a GPA by.

## 2. `event_registrations` junction table added

The proposal's relationship list states *"A User can register for many
Events"*, and the Events mock-up has an RSVP button, but the ERD has no table
to record a registration. `event_registrations (user_id, event_id)` implements
it, mirroring how `club_memberships` resolves User↔Club.

## 3. `events.club_id` added

The proposal states *"Clubs organize Events"* but draws no link. `events` now
carries a nullable `club_id` — nullable because an event may be run by the
administration rather than a club.

## 4. `locations` table added

Module 6 is the interactive campus map, but the ERD had nowhere to store the
places being mapped. `locations` holds name, category, description and
lat/long.

⚠️ The coordinates in `seed.sql` are approximate placeholders. Take real GPS
readings on campus before the demo — a map that puts Balme Library in the
wrong place is the kind of thing a supervisor notices immediately.

## 5. `letter_grade` is generated, not stored

**Proposal:** `Grades` has both `score` and `grade`.

**Problem:** two columns holding the same fact can disagree. A score of 85
with a stored grade of `C` is representable, and nothing rejects it.

**Change:** `letter_grade` is a `GENERATED ALWAYS AS ... STORED` column
computed from `score`. It is still a real, queryable column, but PostgreSQL
guarantees it always matches.

## 6. `password` renamed to `password_hash`

The ERD lists a `password` attribute. The column stores a bcrypt hash and is
named to say so, so no one is ever tempted to write a plaintext password into
it. Section 2.7 of the proposal already commits to encrypted passwords.

## 7. Day and time given real types

**Proposal:** `Schedule.day` and `Schedule.time` as strings.

**Change:** `day_of_week SMALLINT` (1 = Monday) plus `start_time` / `end_time`
as `TIME`. Strings sort alphabetically — `"Friday"` before `"Monday"` — so a
timetable ordered by a text day comes out in the wrong order. Real types also
let the dashboard work out which class is on *now*, which the mock-up shows
with its "Now" badge.

---

## Grading scale: University of Ghana (decided)

The Grades mock-up (proposal p.25) printed a simplified scale:

    A+ ≥ 90    A ≥ 80    B+ ≥ 75    B ≥ 70    C ≥ 60    F < 60

That is **not** the University of Ghana undergraduate scale, and under it a
student scoring 55 failed. The implementation now uses the real UG scale:

| Grade | Marks   | Points |
|-------|---------|--------|
| A     | 80–100  | 4.0    |
| B+    | 75–79   | 3.5    |
| B     | 70–74   | 3.0    |
| C+    | 65–69   | 2.5    |
| C     | 60–64   | 2.0    |
| D+    | 55–59   | 1.5    |
| D     | 50–54   | 1.0    |
| E     | 45–49   | 0.5    |
| F     | 0–44    | 0.0    |

F is the only failing grade. A cumulative GPA is
sum(points × credit hours) / sum(credit hours).

**Where it lives.** The letter is the generated `grades.letter_grade` column in
`schema.sql`; the points are `GRADE_POINTS` in `backend/src/utils/grading.js`;
the app's copy is `_gpa4_0Breakpoints` in `academic_engine.dart`. The whole table
is also in `docs/grading-scale-ug.json`, and every one of those is tested
against that file (backend `npm test` and `npm run test:smoke`, Flutter
`grading_scale_parity_test.dart`), so they cannot drift apart unnoticed.

**Existing databases** keep the old column until you run
`npm run db:apply -- db/migrations/2026-09-ug-grading-scale.sql`, which
preserves every recorded score. A fresh `npm run db:setup` already has the new
scale.

**For the report:** this deliberately differs from the proposal's mock-up. Say
so in Chapter 4, and update the Grades screenshot/table if the report reprints
the old scale.
