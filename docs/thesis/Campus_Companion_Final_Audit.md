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
| `flutter test` | 380 / 380 passed |
| Backend offline unit tests (`npm test`) | 54 / 54 passed |
| Backend database tests (`npm run test:db`) | 14 / 14 passed |
| Backend API smoke tests (`npm run test:smoke`) | 202 / 202 passed |
| **Total** | **650 passing test executions** (the sum of suite totals, not 650 unique test cases) |
| Live integrations (`npm run verify:integrations`) | 4 November 2026: 4 verified, 0 failed: Firebase credential loads; FCM accepts a dry-run message (nothing delivered); real Firebase rejects an invalid ID token; the Gemini API accepts the key. Google provider: enabled, fingerprint registered. Not verified: push delivery to a phone, a real Google sign-in. |

**The audit brief's baseline (332 / 38 / 8 / 180 = 558) was not used.** Those figures come from an older run, before Google Sign-In, the new dashboard and the regression tests were added. Before guest mode, the suites stood at 371 / 50 / 14 / 182 = 617, a result obtained on both 30 and 31 October. Guest mode then added 8 Flutter tests, 4 backend unit tests and 13 smoke checks. On 31 October, with guest mode, they were 379 / 54 / 14 / 195 = 642. The final round then added 2 Flutter tests and dropped 1 (380) and added 7 smoke checks (202). No suite regressed. The report uses the current figures above.

**Observed quirk:** the first smoke-test attempt after starting the servers failed to connect, and an immediate retry passed. The same thing happened on 30 October and again after guest mode was added. It looks like a server warm-up timing issue in the test harness, not an application defect.

---

## 2. Corrections made

### Accuracy (highest priority)
- **Test figures:** every chapter uses the verified 380 / 54 / 14 / 202 = 650. No outdated totals remain.
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
- **Google Maps:** a Google Maps version was started first and then replaced at the author's request. Its key was saved in `backend/.env` but never used or committed; it was partly shown in a working session, so it should be deleted in Google Cloud Console.

### Remembered guest mode and continuous integration (4 November 2026)
- **Guest mode:** now saved on the device with the other local settings, so a guest who reopens the app returns to the guest shell. Signing in, signing out or tapping "Sign in" clears it. Four new tests cover this; three existing test containers now supply local preferences.
- **Continuous integration:** `.github/workflows/ci.yml` runs the backend unit tests (`npm test`) and `flutter analyze` and `flutter test` on every push and pull request to `master`, with Flutter pinned to 3.44.9 and no secrets. The author reported that the first run (commit `659e1ee`) passed. The database and smoke tests still run only locally.
- **Report:** Table 3.5 (Testing row), Table 4.3 (Repository setup), Section 4.3.1 (guest mode is remembered), Section 5.3 (the guest-mode limitation removed) and Section 5.1 (the AI assistant's live check) updated. Still 53 pages. Flutter suite: 397/397.

---

## 3. Feature classification (verified against the code and tests)

| Status | Features |
|---|---|
| **1. Implemented and verified** (automated tests, and for some, the running app) | Guest mode (read-only browsing of announcements, events, clubs and the map; sign-in prompts for account-only actions); email/password registration and login; JWT sessions; bcrypt hashing; Zod request validation; backend role checks for students, lecturers and administrators; administrator account provisioning; GPA/CWA on the UG scale (shared fixture checked by backend and Flutter tests); events with ownership-based deletion; clubs (search, join, leave); announcements feed and admin posting; campus locations list and map; quiz lifecycle, including hidden answer keys; digital student ID with QR code; timetable `.ics`/CSV parsing and `.ics` export; onboarding and dashboard; AI assistant local engine and handling of unreachable data sources |
| **2. Implemented but not fully verified** | Push notifications (backend fan-out, device tokens and preferences tested; delivery to a physical device not confirmed); Google Sign-In (backend verification checked against the live Firebase project; provider enabled on 4 November 2026, but no real sign-in has completed yet); Gemini-backed assistant and tutor (a live key answered in a short check on the web build; answer quality not evaluated); Gemini past-paper extraction (parsing tested, live extraction quality not evaluated); local reminders and notifications on a real device (not observed); Android build (compiles, installs and launches on an emulator; full walkthrough done on the web build because of the machine's memory limits) |
| **3. Partially implemented** | Student Hub (static fixture data, simulated dues payments); Resources (static content); server-side timetable routes (exist and are restricted to each user's own entries, but are unused by the app); target-class calculator (works, but honours thresholds not checked against current regulations) |
| **4. Planned or outstanding** | Apple sign-in and password reset (out of scope, no buttons shown); timetable synchronisation across devices; production deployment; security review; iOS version; usability study; continuous integration |

---

## 4. Claims that could not be fully verified

- **Wang & Yan (2018):** the full text could not be read (the PDF failed to extract), so the report describes only what the published abstract states.
- **Okonkwo & Ade-Ibijola (2021):** the findings were verified through the abstract and citing summaries, not the full text.
- **Baras et al. (2018):** the description is based on the abstract and indexing summaries.
- **University of Ghana grading scale:** taken from the scale supplied by the student earlier in the project. It should be checked against the current official handbook.
- **Honours-class thresholds:** the thresholds in the target-class calculator have not been compared with current University regulations.
- **Six sources in the audit brief** (Crompton & Burke, 2018; Ifenthaler & Yau, 2020; Labadze, Grigolia & Machaidze, 2023; Namoun & Alshanqiti, 2021; Pimmer, Mateescu & Gröhbiel, 2016; Ramandanis & Xinogalos, 2023): none is cited in the current report. Following the instruction not to add references just to increase the count, they were **not added and not verified**. If they belong to another draft, verify each one before using it.

All 19 references in the final report are cited in the text, and every in-text citation has a reference entry.

---

## 5. Remaining limitations (as stated in the report)

- **Push notifications:** delivery to a physical device is unconfirmed.
- **Google Sign-In:** enabled in Firebase (4 November 2026), but no real sign-in has completed on a device yet.
- **Apple sign-in and password reset:** out of scope; the app shows no option for either.
- **Production readiness:** no production deployment and no security review.
- **Timetable:** local-first and not synchronised with the backend.
- **Static content:** Student Hub and Resources content is static, and payments are simulated.
- **Walking times:** estimated by straight-line distance.
- **Target-class calculator:** a formula, not a validated prediction model.
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
4. **Grading scale and honours thresholds:** both need confirmation against the current official regulations (Section 4 above).
5. **Source control:** the redesign, the three bug fixes (`b6d7266`) and guest mode (`7dc0185`) are committed, so the code matches the report. On 3 November 2026 the repository was pushed to a private GitHub remote (`master` at `915c2fa` at the time of the push), after a check that no secret files or keys are tracked or in the history. The repository was briefly public after it was created and was made private the same day; no secrets or thesis files were in it. The report folder (`docs/thesis/`) was then committed and pushed too. Table 4.3 now records the remote.
