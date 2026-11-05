# Campus Companion: Defence Preparation

Everything here matches the code and the final report as of 3 November 2026. Where something is not verified, it says so. Answer the same way in the defence: examiners trust a candidate who states limits plainly.

---

## 1. Project overview (about 60 seconds)

**Problem.** University of Ghana students use separate, general-purpose tools for their timetable, exams, grades and campus life. None of them follows the University's own rules, such as its grading scale.

**What I built.** Campus Companion is a Flutter mobile application (Android and web), backed by a Node.js/Express REST API and a PostgreSQL database. It brings together, behind one account:
- a timetable, with `.ics` import and export and class reminders;
- exam countdowns;
- GPA/CWA on the UG grading scale, with a target-class calculator;
- announcements, events and clubs;
- a campus map;
- quizzes, including questions extracted from past papers;
- an AI assistant and tutor;
- a digital student ID card.

There are three roles (student, lecturer and administrator), plus a read-only guest mode.

**Evidence.** On 5 November 2026 all 758 automated test executions passed:

| Suite | Passed |
|---|---|
| Flutter tests | 429 |
| Backend unit tests | 103 |
| Database tests | 14 |
| API smoke tests | 212 |

Flutter static analysis was clean. Mutation testing confirmed that the key tests fail when the code they check is broken.

**Honest status.** It is a working prototype, not a production system.
- **Push notifications:** delivered to a real phone (Samsung Galaxy A16) with the app in the background, on 4 November 2026.
- **Google Sign-In:** a real sign-in on the same phone created the student's account.
- **Gemini:** a key is configured, and a live Gemini answer was seen in a short check. Answer quality has not been evaluated.
- **Usability:** no usability study has been done.

---

## 2. System architecture

```
Flutter app (Android / web)          Node.js + Express API             PostgreSQL
 - screens (features/*)      HTTPS    - routes -> middleware ->         - 15 tables
 - Riverpod state           ------>     controllers                     - constraints enforce
 - repositories / API clients  JSON   - JWT auth, role checks             integrity
 - device storage (timetable,         - zod request validation
   exams, profile)                    - Firebase Admin SDK --------> Firebase (FCM push,
                                                                     Google ID tokens)
 - Gemini (assistant/tutor) or local fallback engine
```

- **Three layers, defined interfaces.** The app never touches the database; everything goes through the REST API. The same API serves the Android and web builds.
- **Mobile structure:**
  - Screens read state from Riverpod providers (`AsyncNotifier`, `StateProvider`).
  - Providers call repositories and API classes (for example, `AuthRepository` wraps `AuthApi` and the token store).
  - This keeps networking out of the screens, and tests can swap a repository for a fake.
- **Backend structure:** a request passes through the route, then `requireAuth` or `optionalAuth`, then `requireRole`, then `validateBody` (zod), then the controller, and finally parameterised SQL.
- **Local-first data.** The timetable, exams and optional profile live on the device, so the core daily features work offline. Grades, events, clubs, announcements, quizzes and locations come from the server.
- **One grading definition.** The UG grading scale is defined once (`docs/grading-scale-ug.json`). Both the backend tests and the Flutter tests check against that file, so the app and the server cannot disagree on a grade.

---

## 3. Demonstration sequence (about 8 to 10 minutes)

**Before the defence:**
1. Run `start-dev.ps1`, which starts PostgreSQL on port 5433 and the API on port 4000.
2. Run `npm run db:setup` once, for clean seed data. This resets the local database, so anything created since is lost.
3. Build and open the app.
4. Log in as the administrator and create one or two upcoming events (Events, then the + button). The seeded events are dated April 2026, so without this the Events tab is empty and there is nothing to RSVP to.
5. Have `npm run test:smoke` and `npm run verify:integrations` ready in a terminal.

**Demo accounts (local seed data only):**

| Role | Email | Password |
|---|---|---|
| Student | `student@ug.edu.gh` | `student123` |
| Administrator | `admin@ug.edu.gh` | `admin123` |

**Steps:**

1. **Welcome, then institution picker.** Choosing the University of Ghana sets the grading scale and branding. *Point out that the app offers only Google and Guest: no button for anything that is not built.*
2. **Continue as Guest.**
   - Browse Alerts, Events, Clubs and the Map without an account.
   - Tap **Join** on a club: the app asks you to sign in and sends nothing to the server.
   - Tap **Sign in** in the guest bar.
3. **Log in as the student.**
   - **Dashboard:** greeting, today's classes, stats and the Explore grid.
   - **Grades and GPA:** a CWA/GPA of 3.64, First Class Honours. Show the target-class calculator, and explain that it is a formula, not a prediction.
   - **Timetable:** import an `.ics` file, or add a class; show the reminder and the `.ics` export.
   - **Exams:** countdowns.
   - **AI assistant:** ask "Calculate my GPA". In a build without the Gemini key, the answer is labelled "via Local Engine". In a build with the key (`--dart-define=GEMINI_API_KEY=...`), Gemini answers; replies take about 20 to 30 seconds.
   - **Events:** RSVP, then show the event pass. **Clubs:** join and leave.
   - **Campus map:** list and map views; open a location in a maps app.
   - **Digital student ID:** flip the card to show the QR code.
   - **Lost & Found:** post an item, mark it returned, then remove it. Point out that a guest sees the board without names or contact notes.
4. **Log in as the administrator.** Post an emergency announcement and show it in Alerts. Open the admin panel and show account provisioning: lecturer and admin accounts can only be created here.
5. **Evidence in the terminal:**
   - `npm run test:smoke`: shows **212 passed, 0 failed**.
   - `npm run verify:integrations`: shows 3 verified and 0 failed, and lists exactly what is not verified.

> If the first smoke-test run says "fetch failed", run it again. The very first request after the server starts sometimes fails to connect; this happened consistently on 30 October and 3 November.

---

## 4. Security design

- **Passwords:** stored only as bcrypt hashes, never in plain text. The `/auth/me` response never includes the hash; a smoke test checks this.
- **Sessions:** the server signs its own JSON Web Token (JWT). A bad, expired or forged token always gets a 401, and the message never says which of those it was, so an attacker learns nothing.
- **Roles:** enforced on the server for every request (`requireRole` and `requireAdmin`), not just hidden in the interface.
  - Students can only register themselves as students, whatever role the request asks for.
  - Lecturer and admin accounts can only be created by an administrator.
  - A lecturer can delete only their own events; an admin can delete any.
- **Validation:** every request body is validated with zod before any controller runs. Unknown fields are stripped, so the client cannot inject a `userId` or a `role`.
- **Identity always comes from the token.** For example, a timetable entry always belongs to the authenticated user. A `userId` in the request is ignored, and nobody can delete another user's entry.
- **Google Sign-In:** follows the lesson of Chen et al. (2014). The backend never trusts the client's claim of who the user is. It verifies the Firebase ID token itself, with the Firebase Admin SDK, and only then issues its own session token.
- **Guest access:** only four campus-wide feeds can be read without a token (announcements, events, clubs and locations). If a request does carry a token and it is invalid, it is still rejected, so an expired session is never quietly treated as a guest.
- **Push privacy:** following Samarin et al. (2024), push messages carry no announcement content. The app fetches the content after it is woken.
- **Secrets:** `backend/.env` and the Firebase service-account key are ignored by Git. I checked that no credential has ever been committed.
- **Quizzes:** answer keys are never sent to students before they submit.

**Not done (say it plainly):** a production security review, rate limiting, deployment hardening and HTTPS on a public server.

---

## 5. Database design

There are 15 PostgreSQL tables:
- `users`, `courses`, `schedules` and `grades`;
- `announcements`, `events` and `event_registrations`;
- `clubs` and `club_memberships`;
- `locations` and `device_tokens`;
- `quizzes`, `quiz_questions`, `quiz_attempts` and `quiz_attempt_answers`.

How the database protects data integrity:
- **Unique emails:** a case-insensitive unique index on `LOWER(email)`.
- **One account per Google identity:** `google_uid` is `UNIQUE`, so one Google account can never belong to two users. A database test checks this.
- **Grades cannot be wrong:** the `letter_grade` column is `GENERATED ALWAYS AS` from the numeric score, so a letter can never disagree with its score.
- **No duplicates:** examples include `UNIQUE (user_id, course_id, day_of_week, start_time)` for timetable slots and `UNIQUE (user_id, course_id, semester)` for grades.
- **Clean deletes:** foreign keys use `ON DELETE CASCADE`, so deleting a user or course removes their dependent rows.
- **No SQL injection:** all queries are parameterised (`$1`, `$2`, …).

The ER diagram is Figure 3.2 in the report.

---

## 6. Testing evidence

| Level | Tool | Result (5 Nov 2026) | What it proves |
|---|---|---|---|
| Static analysis | `flutter analyze` | No issues | No analyser-detected errors |
| Mobile unit and widget tests | `flutter test` | 429 / 429 | Logic and screens, including grading and the FGPA, timetable parsing, walking routes, guest mode and the demo labels |
| Backend unit tests (offline) | `node --test` | 103 / 103 | Grading scale, push fan-out, token verification, `optionalAuth`, and the events, clubs, quizzes, locations, Lost & Found and login controllers |
| Database tests | `npm run test:db` | 14 / 14 | Real SQL against PostgreSQL: device tokens, Google account linking |
| End-to-end API | `npm run test:smoke` | 212 / 212 | Real user journeys through the running API, including the role and ownership rules |
| Live integrations | `npm run verify:integrations` | 3 verified, 0 failed | Firebase credential, FCM authorisation (dry run), Firebase token rejection |

**Mutation testing.** For key rules, I deliberately broke the real code and checked that the tests then failed. The rules covered were:
- event-deletion ownership;
- self-registration never granting a higher role;
- the session-expiry flag;
- the Google cancel path;
- the guest sign-in checks.

**Defects found by running the whole app, not only the tests:**
- the dashboard title was truncated;
- a failed login replaced the whole form with an error page;
- onboarding returned to the wrong screen;
- a debug assertion fired in the Student Handbook card.

All of these are fixed, with regression tests.

**How the suites grew.** The 24 October snapshot was 366 / 50 / 14 / 182. Since then, tests were added for those defects, guest mode, the demo-data labels and timetable ownership. No suite ever regressed.

---

## 7. Known limitations (say these before you are asked)

1. **Push notifications:** delivered to one phone with the app in the background. A notification while the app is open, and delivery from a deployed server, are not yet checked.
2. **Google Sign-In:** works on one phone, with the debug signing key. The release key still has to be registered before publishing.
3. **AI assistant:** a live Gemini key answered in one short check. Response quality has not been evaluated.
4. **No usability study** has been done with students. A future study would need ethics approval.
5. **Timetable:** stored on the device and not synchronised across devices. The server routes exist, but the app does not use them.
6. **University services:** dues payment, shuttle times, library occupancy and the academic calendar are not offered. Earlier sample versions were removed rather than shown with invented data.
7. **Degree class:** taken from the FGPA, as in the UG *Regulations for Junior Members* (2017): Levels 300 and 400 count double. Repeated courses are not weighted separately. The target-class calculator is a formula, not a validated prediction, and assumes the remaining credits are spread evenly over the levels left.
8. **Walking times:** along real footpaths from a public routing service; if it cannot be reached and no route is saved, the app falls back to a straight-line estimate and says so.
9. **Not deployed:** no production deployment and no security review. Android and web only; no iOS version.
10. **Out of scope:** Apple sign-in and in-app password reset.
11. **Screenshots:** taken from the web build. The Android build runs on an emulator, but this machine (7.7 GB of RAM) could not keep the emulator responsive.

---

## 8. Future work

1. Register the release signing key, deploy the backend, and repeat the Google sign-in and push checks there, including a notification while the app is open.
2. Evaluate Gemini's answers against a set of representative questions.
3. Run a usability study, with ethics approval.
4. Add timetable synchronisation using the existing server routes, which are already restricted to each user's own entries.
5. Add dues payment, shuttle times and library occupancy once the University's data (or access to its systems) and a payment provider are available.
6. Add password reset and, if an iOS version is built, Apple sign-in.
7. Deploy to production: hosting, HTTPS, secrets management, backups, rate limiting and a security review.
8. Weight repeated courses as the regulations require (9.31c), and let students say how many credits remain at each level.

---

## 9. Likely questions and defensible answers

**Q: Why Flutter rather than native Android?**
One codebase serves Android and the web, and the screens are drawn from the same widget code on both. That let me demonstrate the full app even when the emulator could not run on this machine. The trade-off is a larger app size and less direct access to platform features.

**Q: Why your own backend instead of using only Firebase?**
The rules that matter are relational and must be enforced on the server: roles, event ownership, grades tied to courses, and quiz attempts. PostgreSQL constraints and server-side role checks give integrity that a client-trusted database would not. Firebase is used only where it is the right tool: push notifications and verifying Google identity.

**Q: How do you stop a student from making themselves an admin?**
Self-registration always creates a student account, whatever the request says. Validation strips unknown fields, and roles are checked on the server for every request. Lecturer and admin accounts can only be created by an existing admin. Smoke tests check all of this.

**Q: How do you know your tests actually test anything?**
Mutation testing: I broke the real logic on purpose, confirmed the relevant tests failed, then restored it. I also ran the whole application, which found four defects the tests had missed. I fixed them and added regression tests.

**Q: Did you evaluate it with users?**
No. I did not run interviews, surveys or a usability study, and the report does not claim any. The requirements came from my own analysis as a student at the University. A usability study, with ethics approval, is the first item of future work.

**Q: Does Google Sign-In / push / the AI work?**
Each one is built and tested in code. I also ran a live check against the real services:
- the Firebase credential works;
- FCM accepts a message from it (in a dry run);
- Firebase rejects fake tokens;
- Google is enabled as a sign-in provider;
- the Gemini API accepts the key, and the assistant gave a real Gemini answer in a short check.

On 4 November 2026 I also tested on a real phone (Samsung Galaxy A16): Google sign-in created my account on the server, a test announcement arrived as a notification while the app was in the background, the street map loaded, and Gemini answered. What is not verified: a notification while the app is open, the release signing key, and a deployed server. I report exactly that.

**Q: What happens if the AI service is down?**
The assistant draws on several data sources: grades, events, alerts, locations, and the timetable stored on the device. If one cannot be reached, it tells the student which one and answers from the rest. If Gemini is unavailable, a local keyword engine answers supported questions, and its replies are labelled "via Local Engine". This behaviour is tested, and I saw it happen for real: in the live check Gemini once replied "high demand" (HTTP 503), and the app fell back. Since then the app retries once when Gemini says it is busy, and waits up to 60 seconds for a reply. In a later check the retry worked for real: Gemini answered 503, the retry got through, and the student saw a Gemini answer.

**Q: Why is the timetable not on the server?**
Students edit their timetable often and need it offline, for reminders and walking-time cards, so it is stored on the device first. Early on, reading it from a mostly empty server timetable risked hiding a student's real classes. The server routes exist and are now owner-only, so cloud sync is a clear next step.

**Q: Why is there no dues payment or shuttle tracker?**
Earlier versions had them, built on sample data: invented drivers and phone numbers, live seat counts, and a simulated MoMo payment. I removed them before submission rather than show made-up information. They need the University's own data and a payment provider. Lost & Found, which needs neither, became a real shared board instead.

**Q: How accurate is the target-class "prediction"?**
It is not a prediction. It is a formula: the average a student needs over their remaining credit hours to reach a chosen honours class. Its class bands match the University's 2017 regulations, and it works on the FGPA, where Levels 300 and 400 count double. The app reads each course's level from its code. Because it cannot know which levels a student's remaining credits will fall in, it assumes they are spread evenly over the levels left, and the card says so.

**Q: What would you do differently?**
- Set up the remote repository and continuous integration at the start.
- Get a physical Android device early, so push and Google sign-in could be verified end to end.
- Plan the usability study, and its ethics approval, from the beginning.

**Q: What is the most important thing you learned?**
Passing tests are not the same as a working product. Running the whole application found four defects that the tests, which checked screens one at a time, had missed. I also learned that a report must state only what the evidence shows.

---

## 10. Checklist for the day

- [ ] Confirm the programme title, submission date and Declaration format with the department; the report currently says "BSc Information Technology" and "October, 2026".
- [x] Check the UG grading scale and honours thresholds against the regulations (2017 edition, 4 November 2026).
- [x] Push the repository to the private GitHub remote and update Table 4.3 ("Repository setup"). Done 3 November 2026.
- [ ] `start-dev.ps1`, then `npm run db:setup` (it needs PostgreSQL running), then run the smoke tests once to warm the server.
- [ ] Build the app, and log in as the student and the admin once beforehand.
- [ ] Have the report PDF, this document and a terminal open.
- [x] Enable Google in the Firebase console and add a Gemini key, re-run `npm run verify:integrations`, and update the report (4 November 2026).
- [x] Complete a Google sign-in and receive a push on a physical phone, then update the report (4 November 2026).
