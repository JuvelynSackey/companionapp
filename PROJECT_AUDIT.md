# Campus Companion — Project Audit

**Updated:** 21 September 2026 (after backend verification and legacy cleanup)
**Stack:** Flutter app (`mobile/`) + Node/Express API (`backend/`) + PostgreSQL

This replaces the August audit, which described an Android/Kotlin/Firebase app. The
live app is now Flutter; the legacy Kotlin module `app/` was removed (see section 4).

## 1. Verified today

| Check | Result |
|---|---|
| `flutter analyze` | No issues |
| `flutter test` | 269 / 269 pass |
| Backend `npm test` (offline) | 14 / 14 pass: the grading scale in `schema.sql`, the migration and `GRADE_POINTS` all match `docs/grading-scale-ug.json` |
| Backend `npm run test:smoke` | 154 / 154 pass against local Postgres (port 5433) after `npm run db:setup`. It covers auth, dashboard, schedule, grades, announcements, events (including lecturer create/delete and ownership), clubs, locations, admin provisioning, role permissions, self-registration never granting a role, and the quiz lifecycle. Re-runnable: it deletes its quizzes and events, but leaves a `smoke-lecturer-*` and a `smoke-register-*` account per run. |

## 2. Features that work (implemented and wired end to end)

Each of these has a UI in `mobile/lib/features/`, an API client or local store, and,
where noted, tests.

- **Auth** — register, login, session restore, 401 handling (`/auth/*`). Roles: student, lecturer, admin.
- **Onboarding** — institution picker and profile setup; per-institution branding.
- **Dashboard** — aggregated backend data (`/dashboard`).
- **Timetable** — local-first: the student adds, edits, deletes and imports classes (`.ics`/CSV) on the device, and exports to `.ics`; class reminders, the Today list and the walk-time/conflict cards all read that local copy. The server's `/schedule` routes, including `/schedule/today`, are **deliberately unused** by the app and kept working (and smoke-tested) as a possible cloud-backup layer. Wiring the dashboard to `/schedule/today` was considered and rejected: the server timetable is normally empty, so it would replace a student's real classes with nothing. Tested (`schedule_parser`, `ics_exporter`).
- **Exams** — local exams, countdown, exam mode, `.ics` export, reminder notifications. Stored on the device only.
- **Alerts / announcements** — feed, admin broadcast, server-side sync cursor, local notifications from a foreground poll.
- **Events** — list, create (lecturer/admin), register / cancel, and delete with a confirmation dialog: an admin can delete any event, a lecturer only the ones they created (the events API returns `createdBy`, and the button follows the same rule the backend enforces; events with no known creator, including the seeded ones, are admin-only). Creating an event from the app was broken until 21 September (it sent a timestamp with no timezone, which the backend rejects); fixed and covered by a test.
- **Admin panel** — admins only (Admin panel item in the profile menu): create lecturer or admin accounts via `/admin/provision-user`, with client-side validation, backend errors shown (e.g. duplicate email), and an extra confirmation before creating an admin. The screen and the menu item are hidden from other roles; the backend enforces the role regardless. Tested. The menu item itself is not covered by a widget test.
- **Clubs** — list with search and an All / My clubs filter, join / leave with optimistic updates and rollback on failure, and a detail screen with the club's upcoming events. Opened from the Clubs icon on the Events screen. Tested (`club`, `clubs_providers`, `clubs_screen`). Not seen running on a device or emulator yet.
- **Campus locations and map** — `/locations`, custom painter map, open in Maps. Tested (`map_coordinate_mapper`).
- **Grades and GPA** — the server and the app now use the same University of Ghana scale (A 80+ … F below 45; E and F do not pass, so the pass mark is 50, while E still earns 0.5 grade points; GPA = Σ points × credits / Σ credits). Before 21 September the server graded on the proposal's simplified scale, so a 55 showed as a fail (F) next to a GPA that counted it as D+. Guarded by `docs/grading-scale-ug.json`, which the backend tests and the Flutter parity test both read. Existing databases need `npm run db:apply -- db/migrations/2026-09-ug-grading-scale.sql`. For non-UG institutions in the app (5.0, 4.3, CWA) the per-course letter label is still the UG one.
- **Analytics** — GPA/CWA, honours class and target-class predictor, computed client-side per institution. Tested (`grade_prediction_engine`, `academic_engine`).
- **Quizzes** — create, take, submit attempts; import a past-paper PDF and extract questions with Gemini. Tested (`past_paper_extraction`).
- **AI Assistant / AI Tutor** — Gemini when a key is supplied, otherwise a local rule engine. Follow-up questions work (the last 10 messages are sent to Gemini), replies render bold/italic/bullets instead of raw `**`, answers can be selected and copied, and there is a New chat button. **It keeps working when the server is unreachable**: today's classes and exams are local, and each of the four server-backed sources (grades, events, alerts, locations) fails on its own; the assistant then says it can't reach the server for that topic instead of reporting "no grades" or "no events". Before 21 September any one failed server call made every question answer "couldn't load your campus data". Tested (`assistant_engine`, `assistant_controller`, `assistant_context_offline`, `gemini_assistant_service`, `chat_view`, `assistant_screen`, `message_text`). Not seen running against a live Gemini key or on a device.
- **Digital Student ID** — flippable card with QR code. Tested.

## 3. Features that are partial, simulated or not working

These are what to clean up or finish. Ordered by how likely they are to matter in a demo.

| # | Feature | State | Detail |
|---|---|---|---|
| 1 | **Push notifications** | Not working as push | No Firebase/FCM. Alerts appear only while the app polls in the foreground. The server-side hook is an open `TODO` in `backend/src/controllers/announcementController.js` (createAnnouncement). |
| 2 | **Student Hub — Shuttles, MoMo Dues, Lost & Found** | Simulated | No backend tables. Content is static fixtures (`student_hub_fixtures.dart`). "Paying" a due only writes a fake receipt on the device; no payment gateway. Lost & Found reports are per device and never shared. |
| 3 | **Resources** — libraries, past papers, academic calendar, handbook | Static content | Hard-coded in `resource_models.dart`. Not editable and not backed by the API. |
| 4 | **AI Assistant on the deployed web build** | Local fallback only | `GEMINI_API_KEY` is intentionally not baked into the web build (`render.yaml`), so it always uses the rule engine. In that engine the shuttle, MoMo, wifi, food and stress replies are generic text, not data. |
| 5 | **Default API URL** | Works only on an Android emulator | Defaults to `http://10.0.2.2:4000/api`. A physical device or desktop run needs `--dart-define=API_BASE_URL=...`. |
| 6 | **Backend tests** | Thin | A smoke script that needs a live server and database, plus offline unit tests for the grading scale only. Nothing else has unit tests. |
| 7 | **`POST /schedule` cannot target another user** | Latent backend bug | `createScheduleEntry` reads `req.body.userId`, but the request schema does not list it, so validation strips it and a class always lands on the caller's own timetable. It has no effect today (the app is local-first) and only matters if the server timetable is ever used. |

## 4. Cleanup done

Removed after a safety commit (`77b2e02`), so everything is recoverable from git history:

- The legacy Kotlin/Compose app `app/` and the root Gradle files (`build.gradle.kts`,
  `settings.gradle.kts`, `gradle.properties`, `gradle/`, `.gradle/`), `metadata.json`, the root
  `.env.example` (AI Studio Gemini placeholder), the empty `assets/` folder, and a stale
  `.claude/scheduled_tasks.lock`.
- Comments in `mobile/lib` and `docs/phase-2-plan.md` that cited the Kotlin sources as "ported from".

`mobile/android/` is the Flutter project's own Android host and has its own Gradle setup, so it was not touched.

Still open: `mobile/build/` and `mobile/android/build/` are build output and can be deleted with `flutter clean`.
`docs/phase-2-plan.md` is a scoping doc written before implementation, so its "no implementation yet" framing is stale.
The root `.gitignore` still has Android/Gradle entries from the old layout.

## 5. Corrections to the old audit

The August report listed these as problems. They are no longer accurate:

- `backend/.env` and `backend/.env.example` exist.
- Retrofit, Hilt, Room, WorkManager and `google-services.json` gaps no longer apply; the app is Flutter with Dio and Riverpod.
- Course listing (`GET /courses`), quizzes and a `lecturer` role now exist.
- A Render deploy config (`render.yaml`) now exists for the API, the web build and Postgres.

## 6. Suggested next steps

1. Push notifications: resolve the `TODO` in `announcementController.js` and add an FCM listener in the app.
2. Student Hub: replace `student_hub_fixtures.dart` with real tables and routes for shuttles, dues and lost & found.
3. Fix `POST /schedule`'s `userId` if the server timetable is ever used as a cloud backup.
