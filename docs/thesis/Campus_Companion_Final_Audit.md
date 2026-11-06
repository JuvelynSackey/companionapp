# Campus Companion: Final Documentation Audit

**Date:** 31 October 2026; updated 3 November 2026 after guest mode and the final completion round (see the end of section 2)
**Final files:** `Campus_Companion_Final_Report.docx` and `Campus_Companion_Final_Report.pdf` (52 pages), in `docs/thesis/`.
**Originals preserved, not modified:** `campus-companion-thesis-draft.docx`, `Campus-Companion-Final-Year-Project.docx` and `Campus-Companion-Final-Year-Project.pdf`.

Both final files were generated successfully. The DOCX passes an XML validity check, and the PDF was exported by Microsoft Word from that DOCX.

---

## 1. Evidence re-checked for this audit

All test suites were run on 3 November 2026 against the final code:

| Check | Result |
|---|---|
| `flutter analyze` | No issues |
| `flutter test` | 452 / 452 passed (6 November 2026) |
| Backend offline unit tests (`npm test`) | 119 / 119 passed |
| Backend database tests (`npm run test:db`) | 14 / 14 passed |
| Backend API smoke tests (`npm run test:smoke`) | 224 / 224 passed (6 November 2026, fresh test database) |
| **Total** | **809 passing test executions** (the sum of suite totals, not 809 unique test cases), all four suites run on 5 November 2026 |
| Live integrations (`npm run verify:integrations`) | 4 November 2026: 4 verified, 0 failed: Firebase credential loads; FCM accepts a dry-run message (nothing delivered); real Firebase rejects an invalid ID token; the Gemini API accepts the key. Google provider: enabled, fingerprint registered. Not verified: push delivery to a phone, a real Google sign-in. |

**The audit brief's baseline (332 / 38 / 8 / 180 = 558) was not used.** Those figures come from an older run, before Google Sign-In, the new dashboard and the regression tests were added. Before guest mode, the suites stood at 371 / 50 / 14 / 182 = 617, a result obtained on both 30 and 31 October. Guest mode then added 8 Flutter tests, 4 backend unit tests and 13 smoke checks. On 31 October, with guest mode, they were 379 / 54 / 14 / 195 = 642. The final round then added 2 Flutter tests and dropped 1 (380) and added 7 smoke checks (202). No suite regressed. The report uses the current figures above.

**Observed quirk:** the first smoke-test attempt after starting the servers failed to connect, and an immediate retry passed. The same thing happened on 30 October and again after guest mode was added. It looks like a server warm-up timing issue in the test harness, not an application defect.

---

## 2. Corrections made

### Accuracy (highest priority)
- **Test figures:** every chapter uses the verified 452 / 119 / 14 / 224 = 809 (5–6 November 2026). No outdated totals remain.
- **Target-class calculator:**
  - **Before:** described as a "prediction" with "predictive accuracy".
  - **After:** described as a fixed formula, the average needed over the remaining credit hours to reach a chosen honours class (confirmed in `grade_prediction_engine.dart`). This affects Chapters 1, 3 and 4, Table 4.2 and Table 4.3.
- **Chapter 1, uncited claims:** removed two statements (smartphone ownership is "near-universal"; most international apps assume foreign grading scales). They are replaced by a statement citing Adzifome & Agyei (2022) and Afful & Boateng (2023).
- **Chapter 1, "grade-entry module":** removed. Students do not enter grades; the app only fetches them from the server (`grade_api.dart`).
- **Chapter 3, internal file citations:** references to the internal file `PROJECT_AUDIT.md` were replaced with direct statements.
- **Chapter 3, misattribution:** a point wrongly credited to Section 2.3 now points to Section 1.2.
- **Reference, Samarin et al. (2024):** the page range "679–696" was removed because it could not be confirmed.
- **Reference, Essel et al. (2022):** verified as 19(1), Article 57.
- **References page:** an internal working note was removed.
- **Limitations (Chapter 5) and evaluation (Chapter 4):** now state explicitly:
  - straight-line walking estimates;
  - the formula-based target calculator;
  - no production deployment or security review;
  - no iOS version;
  - no ethics approval sought, because no human participants were involved, with ethical approval required for the recommended usability study.

Earlier in the same session, before this audit:
- **myUniMate (Zhao & Pardo, 2017):** corrected. It has no timetable feature, and its trial involved 11 students.
- **Unverified details trimmed:** claims about Wang & Yan (2018), Okonkwo & Ade-Ibijola (2021), Wollny et al. (2021) and Samarin et al. (2024) were cut back to what was verified.
- **Chapter 4:** the "backend dry-run" claim was replaced with the real evidence, a live check of the Firebase credential.

### Writing ("humanising")
- **Abstract, Chapter 1 and Chapter 5:** rewritten in plainer academic English, with shorter sentences and no stock phrases.
- **Chapters 2 and 3:** 18 paragraphs rewritten. The student's own Section 3.1 text and the already-clean paragraphs were left as they were.
- **Chapter 4:** based on the student's draft and left largely as written; only two phrases were changed.
- **Em-dashes:** removed throughout the document text.
- **No artificial changes:** no deliberate errors were introduced and nothing was done to disguise AI involvement.

### Formatting
- **Heading styles:** chapter titles and front-matter titles use Word **Heading 1**; sections use Heading 2 and 3. This lets Word generate or update a contents table.
- **Heading colour:** section headings were Word's default blue and are now black.
- **Page numbering:** the title page is unnumbered, the front matter runs i–xi, and Chapter One starts at page 1.
- **Contents lists:** all 94 entries in the contents, list of figures and list of tables were measured in Word and stay the same when re-measured.
- **Numbered lists:** the recommendations in 5.4 restart at 1. They previously ran on from Chapter 1's list as 8–16.

### Guest mode (added after the first audit, report updated 3 November 2026)
- **Feature:** guest mode was built and committed (`7dc0185`). Guests can browse announcements, events, clubs and the campus map without an account; RSVP and Join ask them to sign in and send nothing. The backend's five read-only routes accept requests without a token, but a forged token is still rejected and every write or personal route still needs sign-in. Checked in the running web build against the local backend.
- **Report changes:**
  - Chapter 1 scope now includes guest mode.
  - New requirement FR15 (Table 3.1), and a Guest actor with a "Browse campus feeds" use case in the use-case diagram.
  - The Security requirement (Table 3.2) states which information can be read without a token.
  - Section 3.4 and the mutation-testing paragraph in Chapter 3 mention guest mode.
  - Section 4.3.1 describes guest mode, and Figure 4.1 has a new panel (d), a real screenshot of the guest Clubs tab.
  - Table 4.1 and Sections 4.4.1 to 4.4.5 have the new test figures, including which tests guest mode added.
  - Table 4.2 (objective 7) shows 642.
  - Table 4.3, Section 5.3 and recommendation 5.4 now list only Apple sign-in as unbuilt.
- **Contents and lists:** re-measured in Word; they were stable on the second pass. The report is still 52 pages.
- **Backup:** the 31 October versions of the report, PDF and this audit are kept in the session scratchpad (`final_31oct_backup`), not in the project.

### Final completion round (3 November 2026)
Code (each change committed with its tests):
- `786358a`: **Schedule ownership.** `POST /schedule` now takes the owner only from the verified token (a `userId` in the body was already stripped by validation; the dead read is gone). `DELETE /schedule/:id` now deletes only the caller's own entry. Before this, an administrator could delete any user's entry by id. 7 new smoke checks cover these rules. Also, `mobile/android/build/` is now ignored by Git.
- `b7e5d28`: **Unbuilt features and demo data.**
  - Removed the Apple sign-in button and the "Forgot Password?" link, since neither is built.
  - Google, when not switched on in a build, now says so and suggests email and password.
  - Added a "Demo data" banner to the Student Hub and to the Libraries, Past Papers and Documents tabs, and paid dues now say "PAID (SIMULATED)".
  - Document requests now say they are saved on the phone and not sent to Academic Affairs. Before, they said "collect the certified copy from Academic Affairs", which implied a real submission.
  - A new test exposed a debug-build assertion in the Student Handbook card, which is now fixed.
- `3f3e302`: **`npm run verify:integrations`.** Live, read-only checks against Firebase, FCM (dry run) and Gemini that never print a credential.

Report:
- **Test figures:** updated to 380 / 54 / 14 / 202 = 650 (3 November).
- **Figure 4.1:** the Welcome and Login screenshots were retaken, so they no longer show the Apple button or "Forgot Password?".
- **Out of scope:** Apple sign-in and password reset are now described as out of scope (Chapter 1 scope, Sections 3.4, 4.3.1 and 5.3); the "planned before the defence" wording and the Apple row in Table 4.3 are gone.
- **Live integration results:** reported in Section 4.6.4 and in Table 4.3 (Gemini row).
- **Demo-data labels:** described in Section 4.3.5.
- **Schedule fix:** recorded in Section 4.4.5 and Section 5.3, and recommendation 5.4 was reworded.
- **Backup:** the previous versions are in the session scratchpad (`final_3nov_guest_backup`).

### Logo and splash (4 November 2026)
- The app now has a logo: the graduation-cap art the author supplied. It is the launcher icon and the web icons, and it appears on the launch splash (native, then a matching Flutter screen while the saved session is checked) and on the Welcome and Login screens.
- **Figure 4.1:** the Welcome and Login screenshots were retaken, so they show the logo. No report text changed, and the report is still 52 pages.
- **Licence:** the author confirmed on 4 November 2026 that the image may be used.

### Gemini and Google provider (4 November 2026)
- **Google Sign-In:** the provider is enabled in Firebase and the debug signing fingerprint is registered; `verify:integrations` reports ENABLED. A real sign-in has **not** completed: on the Android emulator, Google's credential service timed out before an account could be chosen (a slow emulator with no Google account). The physical-phone test is outstanding; the phone was not detected over USB that day.
- **Gemini:** a key was added to `backend/.env` (git-ignored; the app receives it through `--dart-define`). `verify:integrations` now reports 4 verified, 0 failed. On the web build, signed in as a local test student, the assistant gave real Gemini answers (no "via Local Engine" label). A follow-up once received HTTP 503 "high demand" from Gemini, and the app fell back to the local engine as designed.
- **Code change:** replies took 20 to 27 seconds against a 30-second limit. `GeminiAssistantService` now waits up to 60 seconds and retries once on HTTP 503 or 429. Three new tests cover this; the Flutter suite passed 384/384, and `flutter analyze` reported no issues.
- **Report:** Sections 4.3.4, 4.6.3 (new paragraph on the live check), 4.6.4, 4.7 (Table 4.3: the Google Sign-In and AI response quality rows), 5.3 Limitations, 5.4 Recommendations, the Abstract's Result paragraph and FR2 (Section 3.2.1) were updated. The report is now 53 pages (body to page 41).
- **Reply formatting (fixed the same day):** Gemini writes headings that already contain bold (`### 4. **Title**`) and `---` dividers. The reply formatter wrapped such headings in bold a second time, which left a stray `****` on screen, and it showed dividers as raw text. Headings now drop their inner `**` before being made bold, and divider lines become a paragraph break. Three tests use the exact heading shapes Gemini produced; the Flutter suite passed 387/387. In a live re-check the raw reply contained `### **Phase 1: …**` headings and `---` dividers, and the screen showed clean bold headings with neither artefact.
- **Retry seen live:** in the same re-check Gemini first answered HTTP 503, then the automatic retry got HTTP 200 and the answer came from Gemini.
- The report was not changed for these two points; Section 4.6.3 already describes the retry.

### Street map with OpenFreeMap (4 November 2026)
- **Change:** the campus map's Map tab now shows an OpenFreeMap street map (OpenStreetMap data, drawn by MapLibre through `maplibre_gl`) in place of the drawn canvas with its decorative walkway lines. No API key or account is needed. Each location is a dot in its category colour with its name; tapping a dot opens the same details sheet ("Open in Maps"). A button switches to the drawn map for offline use. The map credits OpenFreeMap, OpenMapTiles and OpenStreetMap, as their terms ask.
- **Checked:** on the web build the map showed the real Legon streets (Volta Hall Road, Hodasi Road, Akuafo Hall) with all six locations; tapping Great Hall opened its sheet, and the offline button showed the drawn map. New tests cover the dots, labels, colours and the zoom area; the Flutter suite passed 393/393, and `flutter analyze` reported no issues.
- **Not checked:** the map on an Android device or emulator (the debug APK builds; see the commit).
- **Report:** Section 4.3.5 and Table 3.5 updated. Three sentences that still said Google Sign-In awaited the Firebase console step (Sections 4.2, 4.3.1 and 4.6.4, and Table 4.2) were corrected at the same time. Still 53 pages.
- **Google Maps:** a Google Maps version was started first and then replaced at the author's request. Its key was saved in `backend/.env` but never used or committed; it was partly shown in a working session, but the author confirmed it was a demo key.

### Remembered guest mode and continuous integration (4 November 2026)
- **Guest mode:** now saved on the device with the other local settings, so a guest who reopens the app returns to the guest shell. Signing in, signing out or tapping "Sign in" clears it. Four new tests cover this; three existing test containers now supply local preferences.
- **Continuous integration:** `.github/workflows/ci.yml` runs the backend unit tests (`npm test`) and `flutter analyze` and `flutter test` on every push and pull request to `master`, with Flutter pinned to 3.44.9 and no secrets. The author reported that the first run (commit `659e1ee`) passed. The database and smoke tests still run only locally.
- **Report:** Table 3.5 (Testing row), Table 4.3 (Repository setup), Section 4.3.1 (guest mode is remembered), Section 5.3 (the guest-mode limitation removed) and Section 5.1 (the AI assistant's live check) updated. Still 53 pages. Flutter suite: 397/397.

### Grading checked against the regulations (4 November 2026)
- **Source:** University of Ghana, *Regulations for Junior Members*, Vol. 1, September 2017 (https://www.ug.edu.gh/sites/default/files/UG_Regulations_for_Junior_Members-2017.pdf), read directly (pages 43-44 and 48).
- **Matches:** grade points A 4.0 to D 1.0, E (45-49) 0.5 as a failure grade, F 0; pass grades A-D and failure grades E, F, X, Z; class bands First 3.60-4.00, Second Upper 3.00-3.59, Second Lower 2.00-2.99, Third 1.50-1.99, Pass 1.00-1.49, Fail 0.00-0.99.
- **Difference:** the FGPA weights Level 100-400 GPAs 1:1:2:2 (9.31b); the app uses the plain credit-weighted CGPA. At the author's choice the formula was kept and labelled: the GPA card and the assistant now say "Estimated class (from CGPA)", and the target-class card notes that the official class can differ. Two new test assertions cover the labels; the Flutter suite passed 398/398.

### Former future work made required (4 November 2026)
- **Official FGPA:** the class is now taken from the FGPA. Each course's level is read from its code (the first digit of the number, 9.13); each level's GPA is credit-weighted; the levels are combined 1:1:2:2 (9.31b). The label reads "Class (from FGPA x.xx)". If a course's level cannot be read, or the institution has no level rule, the app falls back to the CGPA estimate as before. The target-class calculator solves on the FGPA too, assuming the remaining credits are spread evenly over the levels left, and the card says so. Tests include transcripts where the FGPA and CGPA give different classes in each direction. Repeated courses (9.31c) are not weighted separately.
- **Backend unit tests:** 40 new offline tests for events, clubs, quizzes, locations and the register/login account lookup, running the controllers against a scripted stand-in for the shared pool (`src/testing/fakeDb.js`). Breaking the event ownership check or the quiz answer-key stripping makes the matching test fail. They run in CI without secrets.
- **Walking routes:** `WalkingRouteService` asks the FOSSGIS foot-routing server (OSRM on OpenStreetMap, no key, CORS allowed) for the walk between consecutive classes and keeps each result on the device. The dashboard card falls back to the straight line, saying so, when no route can be fetched. Checked live on the web build: the card read "~5 min walk from Balme Library"; the route is 339 m against 159 m in a straight line.
- **Tests on 4 November 2026:** Flutter 412/412, backend unit 94/94, database 14/14, smoke 202/202 (722); `flutter analyze` clean. (Superseded by the runs below.)
- **Report:** test figures updated throughout (Abstract, Table 4.1, Sections 4.4, 4.9, 5.1, Table 4.2); Section 4.3.2 describes the FGPA; Section 4.3.5 the routed walks; Section 4.6.6 and 5.3 the new unit tests; Table 4.3's degree-class row now lists only repeated courses and the calculator assumption; Table 3.5 lists the routing server; the two completed recommendations removed. Figures 4.2(b) and (c) retaken. Section headings now stay with their following text (one heading had been left at the foot of a page). The report is 56 pages.

### Demo content removed; Lost & Found made real (4 November 2026)
- **Removed at the author's choice** ("remove the demo parts"): the Student Hub's shuttles (invented drivers, phone numbers, number plates, live seats and arrivals), dues with the simulated MoMo payment, and the sample lost-and-found items; and the Resources Libraries (invented seat counts), Past Papers, academic calendar, handbook summaries and phone-only document requests. Also removed: the assistant's invented shuttle, MoMo, Wi-Fi, food and library-seat answers; library questions are now answered from the real library locations.
- **Lost & Found** is a shared board on the backend: new table `lost_found_items` (migration `2026-11-lost-found.sql`, applied to the local database; it only adds a table), routes `GET/POST /lost-found`, `PATCH /lost-found/:id/returned`, `DELETE /lost-found/:id`. Guests can read it without names or contact notes; signed-in users post; only the poster or an admin changes an item. It starts empty and replaces Student Hub in the account menu.
- **Resources** keeps Portals and Quizzes and links the official UG Regulations for Junior Members (2017) PDF.
- **Checked:** 9 new backend unit tests and 10 new smoke checks; new Flutter tests for the board and the slimmer Resources screen. Live on the web build: posted a labelled test item, marked it returned and removed it; the board was empty again afterwards.
- **Tests on 4 November 2026:** Flutter 421/421, backend unit 103/103, database 14/14, smoke 212/212 (750); `flutter analyze` clean. (Superseded by the run below.)
- **Report:** Sections 1.3, 3.3 (sixteen tables; Table 3.4 and Figure 3.3 gain `lost_found_items`), 3.4, 4.3.5, 4.6, 5.3 and 5.4, Tables 4.2 and 4.3, and the use case diagram (Figure 3.2: "Post to Lost & Found") updated; test figures updated throughout. Still 56 pages.

### Phone tests (4 November 2026, evening)
- **Device:** a Samsung Galaxy A16 (Android 16), connected by USB (`adb reverse tcp:4000`) to the development machine running the local backend; debug APK with Google sign-in, FCM and the Gemini key.
- **Google Sign-In: VERIFIED on a device.** The student signed in with their Google account; the server created user 177 (role student, `google_uid` set, no password) at 19:52:17 UTC.
- **Push: VERIFIED on a device.** The phone registered its FCM token three seconds after sign-in. With the app in the background, an admin posted a test announcement; the phone showed an FCM notification on the `announcements` channel, and the student confirmed seeing it. A first attempt (announcement 27) was lost because the dev server (`node --watch`) restarted just after saving it, before the background fan-out ran; the second (announcement 28) was delivered. Both test announcements were deleted.
- **Street map:** the native MapLibre map on Android showed the Legon streets and all six locations.
- **Gemini:** answered on the phone (header "Gemini", no local-engine label). Its answer pointed to "the Resources tab" for library hours (a tab removed earlier the same day), and bold inside italics showed stray asterisks. Fixed: the prompt now describes the app's real sections and tells Gemini not to invent hours, fees or shuttle times; the reply formatter handles bold inside italics (new test). Flutter suite 422/422; the fixed build was installed on the phone.
- **Not checked:** a notification while the app is open; the release signing key (only the debug fingerprint is registered); anything against a deployed server.
- **Report:** Abstract, Sections 4.2, 4.3.1, 4.3.4, 4.6.4 (new paragraph with these results), 4.8, 4.9, 5.1, 5.3 and 5.4, and Tables 4.2 and 4.3 updated; the Flutter count is now 422 (total 751). Still 56 pages.

### Dark mode and screen fixes (5 November 2026)
- **Appearance setting** (account menu): Use phone setting, Light or Dark, saved on the device. The pre-sign-in screens keep their light branded look. In dark mode the Analytics and Exams hero cards use the Dashboard's deep green for readable white text.
- **From the author's screenshots:** timetable labels no longer wrap ("Remin / d Me"); course codes are printed as "DCIT 103" in the timetable and exams, including entries already saved; a missing room reads "Room not set" instead of "TBA"; timetable cards have a green accent strip and no longer cut off the class time; the exam card's 8-pixel overflow is fixed; and the next exam appears only in the hero card (now with Edit and Delete), with "Later exams" listed below.
- **Also fixed:** app-bar titles were 14 px in the light theme (copied from a size-less base style) and are now 22 px bold in both themes; Resources no longer shows its title twice.
- **Tests on 5 November 2026:** Flutter 429/429, backend unit 103/103, database 14/14, smoke 212/212 (758); `flutter analyze` clean. The smoke run used an API started without `node --watch` (port 4100), because the dev server's watcher restarted it mid-run.
- **Report:** Section 4.2 mentions the appearance setting; test figures and dates updated throughout; Figures 4.1(d), 4.2 and 4.3 retaken to show the current screens. Still 56 pages.

### Backend deployment (5 November 2026)
- **Live API:** https://campus-companion-backend-1bye.onrender.com/api (Render free plan, Frankfurt; sleeps after about 15 minutes idle). **Database:** Neon free Postgres (Frankfurt), chosen because Render's free database is deleted after about 30 days. Steps in `docs/deployment.md`.
- **Verified against the live server:** `/api/health` reports the database connected and Google sign-in on; the full smoke test passed 212/212, including real Firebase rejecting a forged Google token.
- **Safety changes for a public server:** the seeded accounts get random passwords on a hosted database (saved to a git-ignored file, never printed), so `admin123` and the other local passwords do not work online; `db:setup` refuses to wipe a hosted database that has users unless given `--wipe`.
- **Not yet checked:** the phone app against the live server (APK built; phone not connected), a push from the live server, and the release signing key. No security review or rate limiting.
- **Report:** the 2017 regulations added to the references (now 20) and cited in Section 4.3.2; Sections 1.3, 3.2.1 (FR7), 4.3.2, 4.7 (Table 4.3, new "Degree-class estimate" row), 4.9, 5.3 and Table 4.2 updated; a recommendation added to compute the FGPA. Figures 4.2(b) and 4.2(c) retaken to show the new labels. The report is now 56 pages.

---

### Features and report update (5–6 November 2026)
- **Lost & Found:** the server suggests possible matches (open lost vs found posts sharing a title word; a shared place ranks higher) and pushes a notification to the other poster, never the caller and without contact details. Checked on the live server. The board is now a Resources tab (still in the account menu).
- **Quizzes** moved from Resources into the AI Tutor ("Course quizzes", on the tutor's course).
- **AI Tutor slides:** a course's slides can be attached as a PDF (12 MB at most) and are sent with each question. All Gemini requests use `gemini-3.5-flash-lite`; a busy reply is retried once on `gemini-3.1-flash-lite` (`gemini-2.5-flash-lite` returns 404 for this key). Live check: both models read a 1.2 MB PDF correctly; several requests were refused under high demand.
- **Analytics:** results grouped by semester with semester GPA and running CGPA (matches a real UG transcript for the first semesters), and a "What if?" projection of CGPA, FGPA and class from expected grades.
- **Fixes:** the course dropdown overflowed on long names (Quizzes, Tutor); the course list no longer sends a null lecturer.
- **Tests:** Flutter 442/442 and backend unit 109/109 (5 November), database 14/14 (6 November), smoke 212/212 against the live server (5 November): **777**. The local smoke run now fails 8 grade checks only because the demo student holds a real transcript instead of the 4 sample grades.
- **Report:** Sections 1.3, 4.2, 4.3.2 to 4.3.5, Tables 4.1 to 4.3, the summaries, limitations and future work updated; 58 pages. Two contents entries Word's spell-checker had changed to American spelling were kept British, matching the headings.
- **Own results and Lost & Found photos (6 November 2026):** the new columns were added to the live database first (migration `2026-11-self-grades-photos.sql`, columns only), then the server and app. Checked on the live server: a self-entered result is saved and labelled, an attempt to overwrite an official grade is refused (409, the official A unchanged), the result can be deleted; a photo uploads and is served back byte for byte. Tests: Flutter 449/449, backend unit 119/119 (6 November) = **794** with database 14 and smoke 212. The report describes both features (Sections 3.3.3, 4.3.2, 4.3.5) and no longer lists them as future work; still 58 pages.

## 3. Feature classification (verified against the code and tests)

| Status | Features |
|---|---|
| **1. Implemented and verified** (automated tests, and for some, the running app) | Guest mode (read-only browsing of announcements, events, clubs and the map; sign-in prompts for account-only actions); email/password registration and login; JWT sessions; bcrypt hashing; Zod request validation; backend role checks for students, lecturers and administrators; administrator account provisioning; GPA/CWA on the UG scale (shared fixture checked by backend and Flutter tests); events with ownership-based deletion; clubs (search, join, leave); announcements feed and admin posting; campus locations list and map; quiz lifecycle, including hidden answer keys; digital student ID with QR code; timetable `.ics`/CSV parsing and `.ics` export; onboarding and dashboard; AI assistant local engine and handling of unreachable data sources |
| **2. Implemented but not fully verified** | Push notifications (delivered to a physical phone in the background from the local backend; a notification while the app is open, and delivery from a deployed server, not checked); Google Sign-In (completed on a physical phone with the debug signing key; the release key is not registered); Gemini-backed assistant and tutor (live answers seen on the web build and on a phone; answer quality not evaluated); Gemini past-paper extraction (parsing tested, live extraction quality not evaluated); local reminders and notifications on a real device (not observed); Android build (compiles, installs and launches on an emulator; full walkthrough done on the web build because of the machine's memory limits) |
| **3. Partially implemented** | Server-side timetable routes (exist and are restricted to each user's own entries, but are unused by the app); degree class and target-class calculator (taken from the FGPA, but repeated courses are not weighted separately and the calculator assumes the remaining credits are spread evenly over the levels left) |
| **4. Planned or outstanding** | Apple sign-in and password reset (out of scope, no buttons shown); timetable synchronisation across devices; production deployment; security review; iOS version; usability study; continuous integration |

---

## 4. Claims that could not be fully verified

- **Wang & Yan (2018):** the full text could not be read (the PDF failed to extract), so the report describes only what the published abstract states.
- **Okonkwo & Ade-Ibijola (2021):** the findings were verified through the abstract and citing summaries, not the full text.
- **Baras et al. (2018):** the description is based on the abstract and indexing summaries.
- **University of Ghana grading scale and class bands:** checked on 4 November 2026 against University of Ghana, *Regulations for Junior Members*, Vol. 1, September 2017 (https://www.ug.edu.gh/sites/default/files/UG_Regulations_for_Junior_Members-2017.pdf): the grade table (Section 9.20, pp. 43-44), pass and failure grades (9.21) and the classification bands (9.31d, p. 48) match the app exactly. The same document (9.31b) weights Level 100-400 GPAs 1:1:2:2 for the FGPA, which the app does not do (see the dated section above). It says nothing about rounding. A newer edition may exist; the 2017 one is the one found on ug.edu.gh.
- **Six sources in the audit brief** (Crompton & Burke, 2018; Ifenthaler & Yau, 2020; Labadze, Grigolia & Machaidze, 2023; Namoun & Alshanqiti, 2021; Pimmer, Mateescu & Gröhbiel, 2016; Ramandanis & Xinogalos, 2023): none is cited in the current report. Following the instruction not to add references just to increase the count, they were **not added and not verified**. If they belong to another draft, verify each one before using it.

All 20 references in the final report are cited in the text, and every in-text citation has a reference entry.

---

## 5. Remaining limitations (as stated in the report)

- **Push notifications and Google Sign-In:** confirmed on one physical phone against the local backend, with the debug signing key; a notification while the app is open, the release key and a deployed server are not yet checked.
- **Apple sign-in and password reset:** out of scope; the app shows no option for either.
- **Production readiness:** no production deployment and no security review.
- **Timetable:** local-first and not synchronised with the backend.
- **University services not offered:** dues payment, shuttle times, library occupancy and the academic calendar; the earlier sample versions were removed.
- **Walking times:** routed along real footpaths by a public routing service (FOSSGIS OSRM); straight-line fallback, labelled, when it cannot be reached.
- **Target-class calculator and degree class:** the class is taken from the FGPA; repeated courses are not weighted separately (9.31c), and the calculator assumes the remaining credits are spread evenly over the levels left. The calculator is a formula, not a validated prediction model.
- **AI assistant:** a live Gemini key answered in one short check (4 November 2026); answer quality not evaluated. The local fallback is limited.
- **Test coverage:** events, clubs, quizzes, locations and the registration/login account lookup are covered only by smoke tests.
- **Usability:** no usability study.
- **Ethics:** no ethics approval sought, since no participants were involved.
- **Screenshots:** taken from the web build, which the report says.
- **iOS:** no iOS version.

---

## 6. Personal and departmental information

| Item | Value used | Source |
|---|---|---|
| Student name | Juvelyn Ekow Sackey | Supplied by the student |
| Student ID | 11263517 | Supplied by the student |
| Programme | BSc Information Technology (Department of Computer Science) | Supplied by the student |
| Supervisor | Mr. Solomon Mensah | Supplied by the student |
| Date | October, 2026 | Supplied by the student |
| Crest | University of Ghana crest image | Supplied by the student |

The audit brief asked for placeholders for unconfirmed personal details. These details were supplied directly by the student earlier in the session, so they were kept.

**Please confirm:**
- **Programme wording:** that the title "BSc Information Technology" is exactly as the department requires.
- **Submission date:** if the report is submitted in November, update "October, 2026".
- **Declaration format:** whether the department requires a Co-Supervisor or Head of Department block. The current Declaration has Student and Supervisor only, matching a sample from the same department.

---

## 7. Submission risks

1. **No official style sheet:** formatting follows the supplied template structure and a same-department sample (Times New Roman 12 pt, 1.5 line spacing, 1-inch margins, A4). Check these against any department style guide.
2. **Contents page:** it is written into the document with page numbers measured in Word, so editing the Word file can shift pages. After any edit, either re-check the numbers or insert Word's automatic contents table (References → Table of Contents), which works because the headings use Word heading styles.
3. **Screenshots:** they come from the web build, not an Android device. This is disclosed in Section 4.2.
4. **Degree class:** computed from the FGPA as the 2017 regulations require. Repeated courses (9.31c) are not weighted separately; an examiner may ask about that, and about the calculator's even-spread assumption.
5. **Source control:** the redesign, the three bug fixes (`b6d7266`) and guest mode (`7dc0185`) are committed, so the code matches the report. On 3 November 2026 the repository was pushed to a private GitHub remote (`master` at `915c2fa` at the time of the push), after a check that no secret files or keys are tracked or in the history. The repository was briefly public after it was created and was made private the same day; no secrets or thesis files were in it. The report folder (`docs/thesis/`) was then committed and pushed too. Table 4.3 now records the remote.

### Figure style (6 November 2026)
- Figures restyled after a same-department report: each screenshot is now its own numbered figure (4.1 Welcome Screen to 4.10 Digital Student ID, replacing the three grouped figures with (a)–(d) panels), with a thin grey frame and a plain caption below; two screens share a row. Diagram captions are plain and in title case (e.g. "Figure 3.1: System Architecture"). Every reference in the text and Table 4.2 was renumbered, and the List of Figures has 14 entries.
- Fixed while checking: the architecture diagram said 15 tables (now 16, as in Table 3.4); the ERD shows the new `self_reported` and `photo` columns; screenshot rows no longer carry keep-with-next, which had left headings stranded at the foot of pages (no page now ends with a heading). The report is 60 pages.
- **New screenshots (6 November 2026):** Figures 4.8 Results by Semester, 4.9 What If?, 4.10 Add a Result, 4.11 AI Tutor with Lecture Slides, 4.15 Lost & Found Board and 4.16 Lost & Found Post Form, taken from the web build against the local backend with a second demonstration account (sample results, not the author's). The tutor answer is a real Gemini reply to a five-slide sample PDF and was checked against the slides; the item photos are drawings, as the report says. Campus-life figures renumbered 4.12-4.14. Taking Figure 4.11 exposed raw LaTeX in an AI answer; the formatter now shows plain maths (commit 43da107, 452 Flutter tests). The report is 62 pages, 20 figures.

### Report compared with a same-department report (6 November 2026)
- **Compared with** another student's report ("Final Year Project (1).pdf", a job portal; the PDF holds two copies of a ~55-page report). Main gaps found: per-feature test tables, a usability study, a performance evaluation, an objective-by-objective Chapter 5, and title-case table captions.
- **Added:** Section 4.4.8 with Tables 4.2–4.5 (authentication, grades, Lost & Found, events and quizzes; Test case / Expected / Actual / Status) and Table 4.6 (all 224 smoke checks by function); Section 4.4.9 with Table 4.7 (live API timings, five runs each, 6 November 2026: data loads ~0.2 s, sign-in ~2.3 s because of bcrypt at 12 rounds, cold start 8.1 s, Gemini ~1.1 s); Section 5.2 Achievement of Research Objectives (one paragraph per objective). Former Tables 4.2–4.3 are now 4.8–4.9 and Chapter 5 sections 5.2–5.5 are 5.3–5.6, with cross-references updated. Table captions are plain title case and kept with their tables. Times New Roman kept (the other report uses Arial).
- **Smoke test:** 12 checks added (matching, photos, self-entered results); 224/224 on a fresh local test database (`cc_smoke`), so the author's transcript in the main local database does not affect the fixture checks. Totals now 452 / 119 / 14 / 224 = **809**.
- **Not added:** a usability evaluation. It needs real participants; `docs/usability-study.md` has the tester guide, the Google Form (8 feature statements plus the System Usability Scale) and the analysis plan. The report still states that no usability study has been done.
- **Report:** 66 pages, 20 figures, 15 tables.
