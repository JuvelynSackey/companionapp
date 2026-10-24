# Google Sign-In

Reuses the Firebase project and the service-account key already set up for
[push notifications](push-notifications.md) (`campus-companion-61eb5`) — there
is no second project to create. What's left is small: enable one sign-in
provider in the console, and register this app's signing fingerprint so
Google will talk to it.

Everything on the code side is built and tested. Until you do the console
step, Google sign-in is **off** and the app behaves exactly as before:
"Continue with Google" shows, but is disabled, labelled "Coming soon."

## How it works

```
App: "Continue with Google"
        |
        v
Google's native account picker (google_sign_in plugin)
        |
        v
Firebase exchanges that for a Firebase ID token (firebase_auth)
        |
        v
POST /api/auth/google { idToken }
        |
        v
Backend verifies the token against Firebase (same service-account credential
push notifications use, a separate permission scope) ──> the account's
Google identity (uid, email, name)
        |
        v
Look up by email (case-insensitive, same rule every other lookup uses):
  - found  -> link this Google account to it (adds a login method, keeps
              the existing name/role/password untouched)
  - not found -> create a new account, always as a student, no password yet
        |
        v
Issue our own JWT, same shape login/register already return
```

A few deliberate choices:

* **Account linking is automatic and by email.** If a password account already
  exists for that email, signing in with Google links to it rather than making
  a second account — Google has already verified the email, so this is the
  same trust Firebase itself relies on. The existing name, role and password
  are left alone; linking only adds a second way in.
* **New accounts are always students**, exactly like self-registration — the
  identity Google hands back has no role in it, and nothing from the client is
  ever trusted for that.
* **One Google account can only ever belong to one user.** The database
  enforces this (`google_uid` is `UNIQUE`); a conflict comes back as 409, not
  a corrupted link.
* **Backend only — Apple sign-in and Guest mode are not built.** They're shown
  in the UI, styled to match, but disabled ("Coming soon") until there is a
  reason to build them for real.

## What you need to do

### 1. Enable Google as a sign-in provider

Firebase console > your project (`campus-companion-61eb5`) > **Authentication**
> **Sign-in method** > **Add new provider** > **Google** > enable it, pick a
support email, save.

### 2. Register this app's signing fingerprint

Google Sign-In on Android checks the APK was signed by a fingerprint you've
registered, or it refuses to return a credential at all. Firebase console >
**Project settings** > your Android app (`com.example.mobile`) > **Add
fingerprint**, and paste this debug-build SHA-1 (computed from
`mobile`'s local debug keystore, safe to share — it's a standard, publicly
known-password local development certificate, not a secret):

```
SHA-1:   BC:42:EB:25:A1:52:9C:BE:83:43:E4:A0:AD:65:05:68:05:16:D1:09
SHA-256: FE:0D:02:52:16:22:68:3B:70:60:02:BF:07:74:90:0F:6A:22:65:1C:44:9E:44:C8:F2:BD:1B:17:C1:52:7A:83
```

This is the **debug** certificate — fine for everything in this doc's
checklist (running from Android Studio or `flutter run`). A **release** build
(a signed APK/AAB meant for real distribution, e.g. uploaded to Google Play)
is signed with a different keystore and needs its own fingerprint added the
same way once that keystore exists; it doesn't exist yet in this project.

### 3. Re-download `google-services.json`

Adding a fingerprint changes the file (it embeds an OAuth client keyed to
it). Firebase console > **Project settings** > your Android app > download
`google-services.json` again, replace `mobile/android/app/google-services.json`
with it. Send me the new file's path afterwards and I'll pull the one new
value the app needs out of it (see step 5) without you having to go find it
yourself in the Google Cloud console.

### 4. Turn it on for the backend

Reuses `FIREBASE_SERVICE_ACCOUNT`, already set for push. Just add the flag:

* Locally: `GOOGLE_SIGN_IN_ENABLED=true` in `backend/.env`.
* Render: dashboard > `campus-companion-backend` > Environment >
  `GOOGLE_SIGN_IN_ENABLED` = `true`.

Boot log confirms:

* `Google sign-in: on (Firebase project campus-companion-61eb5).` — working
* `Google sign-in: off (GOOGLE_SIGN_IN_ENABLED is not "true").` — off, by choice
* `Google sign-in: GOOGLE_SIGN_IN_ENABLED is true but ... Google sign-in stays
  off.` — a setup problem; the message says which.

This was verified against the **live** credential while building this: a
deliberately garbage token sent to `POST /api/auth/google` came back
`401 Invalid or expired Google sign-in token` (not 503), which only happens if
Firebase actually accepted the service-account credential for token
verification — a separate permission scope from the one push notifications
use, so this confirms it works independently.

### 5. Turn it on for the app

The "Web client ID" from the re-downloaded `google-services.json` (not a
secret — it identifies the app to Google, the same way a package name does)
goes into `GoogleAuthService`'s configuration. Once you've done step 3, tell
me and I'll read the new file and wire it in, then build with:

```
cd mobile
flutter run --dart-define=GOOGLE_SIGN_IN_ENABLED=true --dart-define=API_BASE_URL=http://<host>:4000/api
```

Without the flag, Firebase Auth/Google Sign-In are never touched and the
button stays disabled — same off-by-default pattern as push.

## Checking it works end to end

1. Steps 1-5 above done, app built with the flag.
2. Tap **Continue with Google**, pick an account in the native picker.
3. You land signed in. `GET /api/auth/me` (`docs/api-testing.http`) shows the
   account; its `role` is `student` unless it's one that already existed with
   a different role.
4. Sign out, register a *different* account by email/password using the
   *same* email address as a Google account you already used, then try
   **Continue with Google** again with that Google account — you should land
   on the password account (linked), not a second one.

## If it does not work

| Symptom | Likely cause |
|---|---|
| The button stays disabled | App not built with `--dart-define=GOOGLE_SIGN_IN_ENABLED=true`, or `google-services.json` missing/stale. |
| Picker opens, then fails immediately | Fingerprint (step 2) not registered for the keystore the app was actually built with, or `google-services.json` wasn't re-downloaded after adding it. |
| `Invalid or expired Google sign-in token` right after picking an account | The backend's `GOOGLE_SIGN_IN_ENABLED`/`FIREBASE_SERVICE_ACCOUNT` aren't set, or belong to a different Firebase project than the app's `google-services.json`. |
| `Google sign-in is not configured on this server` (503) | `GOOGLE_SIGN_IN_ENABLED` isn't `true` on the server you're pointed at. |
| Linking didn't happen — two accounts for one email | Check the emails actually matched exactly (case doesn't matter, but check for typos/an alias). |

## Limits and what is not built

* Android only — iOS needs its own Firebase app registration and an APNs-style
  setup for the native picker; not done.
* No password-reset or "set a password" flow for a Google-only account yet —
  it signs in with Google and nothing else until one is added.
* Apple sign-in and Guest mode are visual only (disabled, "Coming soon") — see
  the note at the top. Say if you want either built for real.
* No account unlinking in the app yet (removing a Google link while keeping
  the password, or vice versa).
