# Deploying the backend

The API runs on Render's free plan, and the database is a free Neon Postgres.
Render's own free database is deleted about 30 days after creation, so it is
not used. The Flutter app is not deployed as a website; the phone app points
at the API.

Limits of the free plans: the Render service sleeps after about 15 minutes
without requests, so the first request after a pause takes up to a minute.
Neon's free database also pauses when idle and wakes on the next query.

## 1. Database (Neon)

1. Sign up at https://neon.tech and create a project, choosing the region
   **AWS Europe Central (Frankfurt)** to match the Render region.
2. Copy the connection string (Dashboard, Connect). It looks like
   `postgresql://USER:PASSWORD@HOST/neondb?sslmode=require`.
3. Put it in `backend/.env.neon` (git-ignored) as a single line:

   ```
   DATABASE_URL=postgresql://...
   ```

4. Create the tables and seed data from this computer:

   ```bash
   cd backend
   set -a; . ./.env.neon; set +a
   npm run db:setup
   ```

   Against a hosted database the script:
   - refuses to run if the database already has users (pass `--wipe` to
     really start again);
   - gives the student, admin and lecturer accounts random passwords and
     writes them to `backend/seed-credentials.local.txt` (git-ignored)
     instead of printing them. The local passwords (`admin123` and so on) are
     never used online.

## 2. API (Render)

1. Sign up at https://render.com with GitHub and allow access to the
   `companionapp` repository.
2. New, Blueprint, choose the repository. Render reads `render.yaml`.
3. When it asks for the secret values, paste:
   - `DATABASE_URL`: the Neon connection string;
   - `FIREBASE_SERVICE_ACCOUNT`: the Firebase key. Base64 is safest to paste
     (PowerShell: `[Convert]::ToBase64String([IO.File]::ReadAllBytes("key.json"))`);
     one-line JSON also works, and stray quotes around it are ignored.
4. Apply. When the deploy finishes, open
   `https://<service>.onrender.com/api/health`; it should answer
   `{"status":"ok","database":"connected"}`.

## 3. Check it

```bash
cd backend
API_BASE=https://<service>.onrender.com/api \
SMOKE_STUDENT_PASSWORD=... SMOKE_ADMIN_PASSWORD=... npm run test:smoke
```

The smoke test leaves a few `smoke-*` accounts behind, so afterwards reset the
database with `npm run db:setup -- --wipe` (with `.env.neon` loaded as above).
This also issues new passwords.

## 4. Point the phone app at it

```bash
flutter build apk --dart-define=API_BASE_URL=https://<service>.onrender.com/api ...
```

The other `--dart-define` values are the same as for local testing (see
`docs/google-sign-in.md`). No `adb reverse` is needed.

## Schema changes later

Apply a migration to the live database without wiping it:

```bash
set -a; . ./.env.neon; set +a
npm run db:apply -- db/migrations/<file>.sql
```
