# Campus Companion — Project Audit

**Updated:** 3 November 2026 (final completion round: schedule ownership, no unbuilt sign-in options, demo-data labels, live integration checks)
**Stack:** Flutter app (`mobile/`) + Node/Express API (`backend/`) + PostgreSQL

This replaces the August audit, which described an Android/Kotlin/Firebase app. The
live app is now Flutter; the legacy Kotlin module `app/` was removed (see section 4).

## 1. Verified today

| Check | Result |
|---|---|
| `flutter analyze` | No issues |
| `flutter test` | 452 / 452 pass (6 November 2026) |
| Backend `npm test` (offline) | 119 / 119 pass: the events, clubs, quizzes, locations, Lost & Found and register/login controllers against a scripted stand-in for the database (`src/testing/fakeDb.js`); `optionalAuth`, the gate on the guest-readable routes; the grading scale in `schema.sql`, the migration and `GRADE_POINTS` all match `docs/grading-scale-ug.json`; the push fan-out and FCM sender against in-memory fakes; the Google ID token verifier (including that push and Google sign-in share one Firebase app) |
| Backend `npm run test:db` | 14 / 14 pass against local Postgres: the device-token/push-preference SQL, and the Google user-store SQL (linking, create, the uniqueness conflict) — both clean up after themselves |
| Backend `npm run verify:integrations` | Live, read-only, 4 November 2026: 4 verified, 0 failed (Firebase credential loads; FCM accepts a dry-run message, nothing delivered; real Firebase rejects an invalid ID token; the Gemini API accepts the key). Google provider: ENABLED, with the debug signing fingerprint registered. On a physical phone (Samsung Galaxy A16, Android 16, local backend over USB) on 4 November 2026: a real Google sign-in created the account, and a push was delivered with the app in the background. Not yet checked: a notification while the app is open, the release signing key, a deployed server. |
| Backend `npm run test:smoke` | 212 / 212 pass against local Postgres (port 5433) after `npm run db:setup`. It covers schedule ownership (a body `userId` is ignored; students get 403 and no token 401 on create/delete; an admin cannot delete another user's entry), guest browsing (the five public reads work without a token, show nothing as registered or joined, still reject a bad token, and every write or personal route still needs sign-in), auth (including `POST /auth/google` against the **live** Firebase credential — a garbage token comes back 401, not 503), dashboard, schedule, grades, announcements, events (including lecturer create/delete and ownership), clubs, locations, admin provisioning, role permissions, self-registration never granting a role, and the quiz lifecycle. Re-runnable: it deletes its quizzes and events, but leaves a `smoke-lecturer-*` and a `smoke-register-*` account per run. |

## 2. Features that work (implemented and wired end to end)

Each of these has a UI in `mobile/lib/features/`, an API client or local store, and,
where noted, tests.

- **Auth** — register, login, session restore, 401 handling (`/auth/*`). Roles: student, lecturer, admin. A new Welcome screen (shown once per device, before onboarding) and a redesigned Login/Create-account flow, in a green/light look deliberately separate from the rest of the app's cyan/slate theme (`core/theme/landing_theme.dart`) — the user asked for this specific visual direction for the pre-sign-in screens only. "Continue as Guest" opens a guest shell (Alerts, Events, Clubs, Map) backed by public read-only routes (`optionalAuth`); RSVP and Join ask a guest to sign in and send nothing, and guest mode is not kept across launches. There is no Apple sign-in button and no "Forgot Password?" link, because neither feature is built. Google, when not switched on in a build, says so and suggests email and password. Tested (`sign_in_screen`, `sign_up_screen`, `welcome_screen`, `guest_mode`).
- **Google Sign-In (built, not live)** — "Continue with Google" on both the Welcome and Login screens, wired through `GoogleAuthService` (Noop by default, a Firebase-backed adapter behind `--dart-define=GOOGLE_SIGN_IN_ENABLED=true`) to `POST /api/auth/google`. An existing password account is linked by email (adds a login method, nothing is overwritten); a new one is always a student. `POST /auth/google` was verified against the **live** Firebase credential (see the smoke-test row above). Everything except the Firebase-backed adapter itself (`firebase_google_auth_service.dart` — needs a real Firebase project and Google Play services, the same exemption `firebase_push_messaging.dart` has) is tested against fakes, including the cancel/success/error paths and the UI's loading/disabled states. **It cannot sign anyone in until the Google provider is enabled in the same Firebase project push notifications already use, and one more value (the Web client ID) is read out of a re-downloaded `google-services.json`** — see `docs/google-sign-in.md`. Android only.
- **Onboarding** — institution picker and profile setup; per-institution branding.
- **Dashboard** — aggregated backend data (`/dashboard`).
- **Timetable** — local-first: the student adds, edits, deletes and imports classes (`.ics`/CSV) on the device, and exports to `.ics`; class reminders, the Today list and the walk-time/conflict cards all read that local copy. The server's `/schedule` routes, including `/schedule/today`, are **deliberately unused** by the app and kept working (and smoke-tested) as a possible cloud-backup layer. Wiring the dashboard to `/schedule/today` was considered and rejected: the server timetable is normally empty, so it would replace a student's real classes with nothing. Tested (`schedule_parser`, `ics_exporter`).
- **Exams** — local exams, countdown, exam mode, `.ics` export, reminder notifications. Stored on the device only.
- **Alerts / announcements** — feed, admin broadcast, server-side sync cursor, local notifications from a foreground poll.
- **Push notifications (built, not live)** — device-token registration, a per-user on/off switch (Alerts tab), announcement fan-out from the server (`FCM_ENABLED`-gated, log-only until then), foreground display, tap-to-open-Alerts, unregister on sign-out, dead-token cleanup, and the poll staying quiet while push works. Everything except the Firebase-backed adapter (`firebase_push_messaging.dart`) is tested against fakes, and both the release web build and a debug Android APK compile with the new packages (Flutter warns that `firebase_core` uses the old Kotlin plugin, a future-version notice, not an error). **It cannot deliver anything until you create a Firebase project** — see `docs/push-notifications.md`. Android only.
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
| 1 | **Push notifications** | Built, waiting for a Firebase project | The app and server are ready (see section 2). A Firebase project exists (`campus-companion-61eb5`) and `google-services.json` is in place locally (git-ignored), with the Gradle plugin applied and a debug APK building against it. Still to do: put the service-account key on the server (`FCM_ENABLED`, `FIREBASE_SERVICE_ACCOUNT`), apply the migrations to the production database, deploy, and check on a real phone. Until then nothing is delivered to a closed app: alerts still arrive only while the app polls in the foreground. Next steps are in `docs/push-notifications.md` (decide the Android app id first: it is `com.example.mobile`, a placeholder Google Play rejects). iOS and web push are not set up. |
| 2 | **Google Sign-In** | Built, waiting for one console step + one value | Same Firebase project and credential as push (already confirmed live for auth verification too — see the smoke-test row above). Still to do: enable Google as a sign-in provider, register the app's debug SHA-1/SHA-256 fingerprint, re-download `google-services.json`, and give the app the Web client ID from it. Until then, tapping the button says Google sign-in isn't switched on in this version. Exact steps and the computed fingerprint are in `docs/google-sign-in.md`. Android only; Apple sign-in is out of scope. |
| 3 | **Lost & Found** | Working | A shared board on the backend (`lost_found_items`; migration `2026-11-lost-found.sql`). Guests read it without names or contact notes; only the poster or an admin marks an item returned or removes it. The old Student Hub (sample shuttles, a simulated MoMo payment, device-only lost-and-found) was removed on 4 November 2026. |
| 4 | **Resources** | Working | Official portals (and, for UG, the Regulations for Junior Members PDF) and quizzes. The sample Libraries, Past Papers, calendar, handbook summaries and document requests were removed on 4 November 2026. |
| 5 | **AI Assistant on the deployed web build** | Local fallback only | `GEMINI_API_KEY` is intentionally not baked into the web build (`render.yaml`), so it always uses the rule engine. That engine no longer gives the old invented shuttle, MoMo, Wi-Fi, food or library-seat answers; library questions are answered from the real locations. |
| 6 | **Default API URL** | Works only on an Android emulator | Defaults to `http://10.0.2.2:4000/api`. A physical device or desktop run needs `--dart-define=API_BASE_URL=...`. |
| 7 | **Backend tests** | Covered | A smoke script that needs a live server and database, plus offline unit tests for every controller area: the grading scale, the push fan-out/sender, the Google ID token verifier, and (since 4 November 2026) events, clubs, quizzes, locations and the register/login account lookup. |
| 8 | **Server timetable routes** | Fixed 3 Nov 2026 | Entries belong to the token's user only: `POST /schedule` ignores any body `userId`, and `DELETE /schedule/:id` deletes only the caller's own entry (an admin could previously delete anyone's). Smoke-tested. The app still does not call these routes (it is local-first). |

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

## Dependency security

`npm audit fix` (non-forced, 21 September) moved `express` 4.22.2 -> 4.22.3, `body-parser` 1.20.6 -> 1.20.8, `morgan` 1.11.0 -> 1.12.1 and `qs` 6.15.3 -> 6.16.0 (patch/minor only), clearing 4 of 6 moderate advisories. Backend unit, database and smoke suites were re-run on a clean `npm ci` and stayed green.

Two moderate advisories remain, both `uuid` 9.0.1 pulled in by `firebase-admin` (through `@google-cloud/storage` and `gaxios`). They are not exploitable here: the advisory is about `uuid` v3/v5/v6 called with a caller-supplied buffer, while `gaxios` only calls `uuid.v4()` with none, and our push code never loads Cloud Storage. Fixing them needs a major-version change inside Google's libraries, so they are left until `firebase-admin` updates. Re-check with `npm audit --omit=dev` after each `firebase-admin` upgrade.

## 5. Corrections to the old audit

The August report listed these as problems. They are no longer accurate:

- `backend/.env` and `backend/.env.example` exist.
- Retrofit, Hilt, Room, WorkManager and `google-services.json` gaps no longer apply; the app is Flutter with Dio and Riverpod.
- Course listing (`GET /courses`), quizzes and a `lecturer` role now exist.
- A Render deploy config (`render.yaml`) now exists for the API, the web build and Postgres.

## 6. Suggested next steps

1. Push notifications: put the service-account key on the server, apply the migrations to the production database, deploy, and check it on a real phone (`docs/push-notifications.md`).
2. Google Sign-In: enable the provider and register the fingerprint in the same Firebase project (`docs/google-sign-in.md`), then check it on a real phone.
3. Dues payment, shuttle times and library occupancy: add only with the University's data (or system access) and a payment provider.
4. If the server timetable is used as a cloud backup, build the sync on the existing routes (now owner-only).
