# Phase 2 Architecture Plan — Student Hub, Digital ID, AI Assistant, GPA Engine

Scoping only — no implementation yet. Companion to the Phase 1 migration plan (`mobile/` Flutter app, wired to the Express backend). Ported source references are in `app/src/main/java/com/example/`.

## 1. Student Hub (shuttles, MoMo dues, lost & found, campus events, portals)

**Current state:** `StudentHubScreen.kt` (2089 lines) is 100% local/mock — all data comes from `GhanaCampusCompanionData`'s per-institution generators (shuttles, dues, lost & found, events), regenerated fresh on every load. `FirestoreRepository` has real DTOs for some of this (`CampusDueItemDto`, `MoMoPaymentReceiptDto`) but nothing in the codebase actually wires Firestore to this screen. The backend has **zero** tables for shuttles, dues, or lost & found — the only real overlap is **Events & Clubs**, which the backend already supports (`GET/POST /api/events`, `GET /api/clubs` + join/register endpoints, unused so far).

**Decision: split the sub-tabs by what's actually backable.**

| Sub-tab | Phase 2 approach | Why |
|---|---|---|
| Campus Events | Wire to existing `GET/POST /api/events`, `GET /api/clubs` + register/join endpoints | Real backend support already exists and is unused — this is the cheapest real integration in Phase 2 |
| Shuttles/Trotros, MoMo Dues, Lost & Found | **Local-only fixture data**, ported from `GhanaCampusCompanionData` as static Dart consts (7 institutions × category) | No backend model exists; a real MoMo payment flow needs an actual payment gateway integration, which is out of scope. Keep these as clearly-labeled simulated campus-life content, matching current fidelity, not a real payments feature |
| Student Portals | Already covered in Phase 1 Resources — no new work | — |
| Digital Student ID | New, trivial — see §2 | — |

Local mutable actions (report a lost item, mark a due "paid" and generate a receipt) persist via `shared_preferences`/a small JSON blob, same pattern as Phase 1's local Exams feature — per-device, not synced.

**Porting effort:** the bulk of this section is *content* porting (`GhanaCampusCompanionData`'s hand-authored generators → Dart consts), not logic. `CampusCompanionModels.kt` (`StudentProfile`, `CampusShuttleRoute`, `LostAndFoundItem`, `CampusDueItem`, `MoMoPaymentReceipt`, `CampusEvent`) map to plain Dart data classes.

## 2. Digital Student ID

Pure presentation — no new backend or persistence. Reads the signed-in `AppUser` (fullName, email, role) plus the selected `InstitutionProfile`'s branding (name, logo/color) plus a deterministic display ID derived from `userId`. Lowest-effort Phase 2 item; do it early as a quick win.

## 3. AI Assistant (Gemini REST + local fallback)

**Current state (`CampusAssistantService.kt`):** two-tier design — if a real Gemini API key is configured, POST directly to `generativelanguage.googleapis.com` (raw REST, not the SDK) with a context prompt built from the student's live data; on missing key or any failure, fall back to a ~12-branch keyword-matched local response generator built from the same data. This fallback is substantial and fully deterministic — no external dependency.

**Port plan:**
- `GeminiAssistantService`: `dio` POST to the same endpoint/shape (`contents[].parts[].text`), key sourced via `--dart-define=GEMINI_API_KEY` (never hardcoded), 30s timeout, swallow errors into the fallback path — mirrors the Kotlin try/catch structure exactly.
- `LocalAssistantFallback`: port the 12 keyword branches (library/seats, exam/leave-time, class/timetable, location lookup, GPA/CGPA, portal/registration, shuttle/fare, MoMo/dues, wifi/eduroam, food/canteen, stress/motivation, general help) near-verbatim — pure string building, no architecture risk.
- `AssistantContextBuilder`: **new** — the old app read everything from one local Room DB; Phase 1+2 data is now split across backend-driven providers (schedule, announcements, grades, locations) and local-only ones (exams, hub fixtures). This builder reads from the existing Riverpod providers (`ref.read`, not a duplicate data layer) to assemble the same context shape the prompt/fallback expects.
- Chat UI (`AssistantScreen`) ports 1:1 — message list, quick-suggestion chips, typing indicator, auto-scroll. Chat history is session-only (in-memory), matching current behavior.

**Dependency:** the context builder wants schedule (Phase 1, done), exams (Phase 1, done), locations (needs `GET /api/locations` wiring — not yet done), GPA summary (§4), and Student Hub library fixtures (Phase 1 Resources, done). Sequence this after locations + GPA land, or ship with a partial context and backfill.

## 4. GPA / Grading Engine + Analytics

**Backend today:** `GET/POST /api/grades` returns per-course `score`/`letterGrade` plus a server-computed `summary.gpa` — but on a **single fixed scale** (A+/A=4.0 … F=0.0), with no concept of institution-specific grading systems, CWA, or honours classification. `PROJECT_AUDIT.md` already flags this scale as mismatched against the real UG standard.

**Old Android (`GradingEngine.kt`):** richer — supports 4 grading system types (`GPA_4_0`, `KNUST_CWA`, `SCALE_5_0`, `SCALE_4_3`) keyed off `InstitutionProfile.gradingSystem`, computes an honours classification from each institution's own threshold table, and converts letter grades to point/percentage values per system (`gradeToValue`).

**Decision: compute institution-aware GPA/CWA + honours classification client-side in Dart**, using the backend only as the raw data source (per-course `score`/`letterGrade`/`creditHours`). This ports `GradingEngine.calculateAcademicMetric`/`getHonoursClassification`/`gradeToValue` almost verbatim (all pure functions) and correctly reflects that "which institution/grading system" is a client-only concept in this migration (backend is single-tenant). The backend's own scale mismatch is a separate, backend-only fix to revisit later — not a blocker here.

**Scope cut:** the backend has no assessments table (one `score` per course/semester, not a weighted breakdown), so `CourseGradeTrackerComponent`'s full weighted-assessment planner (`GpaCourseEntity`/`CourseAssessmentEntity`, target-grade simulation) doesn't have data to back it. Phase 2 ships the simpler version the backend actually supports — GPA/honours scorecard + per-course grade list on the Analytics screen — and defers the weighted-assessment tracker unless/until the backend grows an assessments table.

## Suggested sequencing

1. `GET /api/locations` wiring (small; unblocks both a simplified locations screen and the assistant's location lookups)
2. Events/Clubs wiring → powers Student Hub's Events sub-tab
3. Grades + client-side `GradingEngine` port → powers Analytics
4. Digital Student ID (independent, quick win — do anytime)
5. Student Hub fixture content port (Shuttles/MoMo Dues/Lost & Found) — independent of 1-3
6. AI Assistant (depends on 1-3 for a complete context; can ship with partial context sooner if desired)
7. Custom campus map (`CampusNavigationMapComponent` → `CustomPainter`) — the largest standalone effort; only real dependency is #1
8. `.ics` calendar export + background class reminders — smallest, slot in anywhere

Each numbered item should get its own detailed build-order pass (like Phase 1's) when picked up — this document is the architecture/decision layer, not an execution plan.
