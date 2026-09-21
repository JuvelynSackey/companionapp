# Campus Companion

An academic scheduling and campus life app for Ghanaian university students: timetable, exams,
alerts, events, campus map, grade analytics, quizzes, and an AI assistant and tutor.

| Folder | What it is |
|---|---|
| `mobile/` | Flutter app (Riverpod, Dio). This is the app. |
| `backend/` | Node/Express REST API on PostgreSQL. |
| `docs/` | Schema notes, API examples (`api-testing.http`), phase-2 plan. |

See [PROJECT_AUDIT.md](PROJECT_AUDIT.md) for what works, what is simulated, and what is left to clean up.

## Run locally

**Backend**

1. `cp backend/.env.example backend/.env` and set `DB_PASSWORD` and `JWT_SECRET`.
2. Start PostgreSQL. `.\start-dev.ps1` starts the portable Postgres (port 5433) and the API (port 4000). Set `DB_PORT=5433` in `.env` to match.
3. First run only: `cd backend && npm install && npm run db:setup`.
4. Checks: `npm test` (offline unit tests) and `npm run test:smoke` (needs the API running).
5. Upgrading an existing database: `npm run db:apply -- db/migrations/<file>.sql` (the grading-scale change needs `2026-09-ug-grading-scale.sql`).

**Mobile**

```
cd mobile
flutter pub get
flutter run --dart-define=API_BASE_URL=http://<host>:4000/api --dart-define=GEMINI_API_KEY=<key>
```

- `API_BASE_URL` defaults to `http://10.0.2.2:4000/api`, which only works on an Android emulator.
- `GEMINI_API_KEY` is optional. Without it, the assistant uses its built-in local rule engine.
- Checks: `flutter analyze` and `flutter test`.

## Deploy

`render.yaml` defines the API, the Flutter web build and a Postgres database on Render.
