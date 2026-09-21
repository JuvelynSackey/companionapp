# Campus Companion — Project Audit

**Updated:** 21 September 2026
**Stack:** Flutter app (`mobile/`) + Node/Express API (`backend/`) + PostgreSQL

This replaces the August audit, which described an Android/Kotlin/Firebase app. The
live app is now Flutter; the Kotlin module in `app/` is legacy (see section 4).

## 1. Verified today

| Check | Result |
|---|---|
| `flutter analyze` | No issues |
| `flutter test` | 93 / 93 pass |
| Backend runtime / `npm run test:smoke` | **Not run** — PostgreSQL was not answering on `127.0.0.1:5433` and the API was not up. Backend status below comes from reading the code, not running it. |

## 2. Features that work (implemented and wired end to end)

Each of these has a UI in `mobile/lib/features/`, an API client or local store, and,
where noted, tests.

- **Auth** — register, login, session restore, 401 handling (`/auth/*`). Roles: student, lecturer, admin.
- **Onboarding** — institution picker and profile setup; per-institution branding.
- **Dashboard** — aggregated backend data (`/dashboard`).
- **Timetable** — list, add, delete (admin), import from `.ics`/CSV, export to `.ics`, class reminders. Tested (`schedule_parser`, `ics_exporter`).
- **Exams** — local exams, countdown, exam mode, `.ics` export, reminder notifications. Stored on the device only.
- **Alerts / announcements** — feed, admin broadcast, server-side sync cursor, local notifications from a foreground poll.
- **Events** — list, create (lecturer/admin), register / cancel.
- **Campus locations and map** — `/locations`, custom painter map, open in Maps. Tested (`map_coordinate_mapper`).
- **Analytics** — GPA/CWA, honours class and target-class predictor, computed client-side per institution. Tested (`grade_prediction_engine`, `academic_engine`).
- **Quizzes** — create, take, submit attempts; import a past-paper PDF and extract questions with Gemini. Tested (`past_paper_extraction`).
- **AI Assistant / AI Tutor** — Gemini when a key is supplied, otherwise a local rule engine. Tested (`assistant_engine`).
- **Digital Student ID** — flippable card with QR code. Tested.

## 3. Features that are partial, simulated or not working

These are what to clean up or finish. Ordered by how likely they are to matter in a demo.

| # | Feature | State | Detail |
|---|---|---|---|
| 1 | **Push notifications** | Not working as push | No Firebase/FCM. Alerts appear only while the app polls in the foreground. The server-side hook is an open `TODO` in `backend/src/controllers/announcementController.js` (createAnnouncement). |
| 2 | **Student Hub — Shuttles, MoMo Dues, Lost & Found** | Simulated | No backend tables. Content is static fixtures (`student_hub_fixtures.dart`). "Paying" a due only writes a fake receipt on the device; no payment gateway. Lost & Found reports are per device and never shared. |
| 3 | **Resources** — libraries, past papers, academic calendar, handbook | Static content | Hard-coded in `resource_models.dart`. Not editable and not backed by the API. |
| 4 | **Clubs** | Backend only | `GET /clubs`, join and leave exist, but the mobile app never calls them and has no screen. |
| 5 | **AI Assistant on the deployed web build** | Local fallback only | `GEMINI_API_KEY` is intentionally not baked into the web build (`render.yaml`), so it always uses the rule engine. In that engine the shuttle, MoMo, wifi, food and stress replies are generic text, not data. |
| 6 | **Backend grading scale** | Known mismatch | The server computes `summary.gpa` on a fixed 4.0 scale that differs from the UG scale. The app recomputes client-side, so the two GPA numbers can disagree. Open question is in `docs/schema-notes.md`. |
| 7 | **Unused backend routes** | Dead from the app's side | `GET /schedule/today` and `POST /admin/provision-user` are never called by the mobile app. |
| 8 | **Default API URL** | Works only on an Android emulator | Defaults to `http://10.0.2.2:4000/api`. A physical device or desktop run needs `--dart-define=API_BASE_URL=...`. |
| 9 | **Backend tests** | Thin | One smoke script that needs a live server and database. No unit tests. |

## 4. Cleanup candidates

Not deleted yet — confirm before removing.

1. **Legacy Kotlin app `app/`** (about 50 files: Room, Firebase, Compose) plus the root Gradle files
   (`build.gradle.kts`, `settings.gradle.kts`, `gradle.properties`, `gradle/`, `.gradle/`),
   `metadata.json`, and the root `.env.example` (AI Studio Gemini placeholder). Nothing in
   `mobile/` builds against them. Some Dart comments and `docs/phase-2-plan.md` cite the
   Kotlin files as "ported from", so tidy those references in the same pass.
2. **Empty `assets/` folder** and `.claude/scheduled_tasks.lock`.
3. **Build output in the tree**: `mobile/build/` is ignored by git but takes space.
4. **`docs/phase-2-plan.md`** is a scoping doc written before implementation; its "no implementation yet" framing is stale.
5. **Git hygiene**: the repo has a single commit and about 34 modified files (roughly 1,200 added lines) uncommitted. Commit before any deletion so cleanup is reversible.

Checked and clean: `flutter analyze` reports no issues, and no unreferenced Dart files exist
under `mobile/lib/` apart from the `main.dart` entry point.

## 5. Corrections to the old audit

The August report listed these as problems. They are no longer accurate:

- `backend/.env` and `backend/.env.example` exist.
- Retrofit, Hilt, Room, WorkManager and `google-services.json` gaps no longer apply; the app is Flutter with Dio and Riverpod.
- Course listing (`GET /courses`), quizzes and a `lecturer` role now exist.
- A Render deploy config (`render.yaml`) now exists for the API, the web build and Postgres.

## 6. Suggested next steps

1. Start Postgres and the API (`.\start-dev.ps1`), then run `npm run test:smoke` to confirm the backend.
2. Commit the current working tree.
3. Remove or archive the legacy Kotlin module and root Gradle files.
4. Decide, for each item in section 3, whether to finish it, label it "demo data" in the UI, or remove it.
5. Settle the grading scale so server and client GPA agree.
