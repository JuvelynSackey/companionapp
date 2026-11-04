# Push notifications (Firebase Cloud Messaging)

Everything on the code side is built and tested. What is left is creating the
Firebase project and handing the app and the server their credentials. Until
you do, push is **off** and the app behaves exactly as before: the announcement
poll (every 5 minutes while the app is open) still delivers alerts.

## How it works

```
Admin posts an announcement
        |
        v
API saves it ──> notificationService.notifyAnnouncement() (runs in the background)
                        |  every device token whose owner has push switched on
                        v
                 FcmSender ──> Firebase Cloud Messaging ──> the phone
                        ^                                      |
     dead tokens are    |                                      +- app closed / in background:
     deleted afterwards |                                      |     Android shows it, tap -> opens Alerts
                                                               +- app open: PushCoordinator shows it
                                                                     as a local notification, refreshes Alerts
```

* **Registering a device.** When a user signs in (and the build has push on),
  the app asks for notification permission, gets its FCM token, and sends it to
  `POST /api/users/me/device-token`. It re-sends whenever Firebase rotates the
  token. A token belongs to **one** account: if someone else signs in on the
  same phone, the token moves to them.
* **Signing out** unregisters the device on the server first, then deletes the
  local token, so the next person on that phone never gets your alerts.
* **The switch.** *Alerts > Push notifications* is a per-user setting stored on
  the server (`users.push_enabled`, `GET/PUT /api/users/me/notification-preferences`).
  It is hidden in builds without push.
* **The poll is the safety net.** While a device is registered for push the poll
  only keeps its cursor up to date. If registration fails (offline, permission
  refused) the poll notifies as it always did, so nobody loses alerts.
* **Emergencies** use the `emergency_announcements` channel (maximum importance)
  and a 🚨 in the title, matching the app's own local notifications. If a user
  switches push off, emergencies are not exempt.

## What you need to do

### 1. Decide the app id first

The Android application id is currently **`com.example.mobile`** (set in
`mobile/android/app/build.gradle.kts`; the iOS bundle id is the same). Firebase
ties `google-services.json` to that exact id, and Google Play rejects ids that
start with `com.example`. If you want a real id (e.g. `edu.yourschool.campuscompanion`),
change it **before** registering the app in Firebase; changing it later means
registering again and downloading a new file. Whatever you pick, use the same
string in step 2.

### 2. Create the Firebase project and register the app

1. <https://console.firebase.google.com> > **Add project**.
2. **Add app > Android**. Package name = the application id from step 1
   (today: `com.example.mobile`). Nickname is free text.
3. Download **`google-services.json`** into `mobile/android/app/`.
   It is git-ignored; it holds this project's public client config, not a secret.

**Easier alternative:** install the FlutterFire CLI and let it do steps 2-3 and
the Gradle changes below:

```
dart pub global activate flutterfire_cli
cd mobile
flutterfire configure
```

It writes `lib/firebase_options.dart`. If you use it, pass the options in
`main.dart`: `createPushMessaging(options: DefaultFirebaseOptions.currentPlatform)`.

### 3. Android Gradle (already done)

The Google-services Gradle plugin (4.5.0) is applied in
`mobile/android/settings.gradle.kts` and `mobile/android/app/build.gradle.kts`;
it turns `google-services.json` into app config at build time. Consequence: **the
Android app will not build without `mobile/android/app/google-services.json`**, and
that file is git-ignored, so a fresh clone (or a teammate's machine) needs it
copied in from the Firebase console (Project settings > Your apps > Android).
The web build and the backend do not need it.

The file's `package_name` must equal the app's `applicationId`
(`com.example.mobile`); a mismatch fails the build with "No matching client found".

### 4. Give the server permission to send

1. Firebase console > **Project settings > Service accounts > Generate new
   private key**. This downloads a JSON file. **It is a secret**: anyone with it
   can send notifications as your app. Never commit it (the repo's `.gitignore`
   blocks the usual file names) and never paste it into chat.
2. Turn it into one line: `node -e "console.log(JSON.stringify(require('./the-key.json')))"`.
3. On Render (dashboard > `campus-companion-backend` > Environment) set:
   * `FCM_ENABLED` = `true`
   * `FIREBASE_SERVICE_ACCOUNT` = the one-line JSON

   Locally, the same two variables go in `backend/.env`.
4. On boot the API logs which mode it is in:
   * `Push notifications: on (Firebase project <id>).` — working
   * `Push notifications: off (FCM_ENABLED is not "true")...` — off, by choice
   * `Push notifications: FCM_ENABLED is true but ... Falling back to log-only.`
     — a setup problem; the message says which (key missing, not valid JSON,
     Firebase refused it). The API keeps running either way.

### 3b. Upgrade an existing database

A database created before this change needs the new table and column
(`npm run db:setup` on a fresh database already has them; it wipes data):

```
cd backend
npm run db:apply -- db/migrations/2026-09-push-notifications.sql
```

### 5. Build the app with push on

```
cd mobile
flutter run --dart-define=API_BASE_URL=http://<host>:4000/api --dart-define=FCM_ENABLED=true
```

Without `FCM_ENABLED=true` Firebase is never started. The deployed web build
leaves it off (web push needs separate setup that is not done).

## Checking it works end to end

**Status on 3 November 2026.** `cd backend && npm run verify:integrations`
confirmed that the server's credential loads and that FCM accepts a dry-run
message sent with it (FCM validates and authorises it but delivers nothing).
**4 November 2026:** delivery was confirmed on a physical phone (Samsung Galaxy
A16, Android 16, debug build against the local backend over USB): after signing
in, the phone registered its token, and an announcement posted with the app in
the background arrived as a notification. Not yet checked: a notification while
the app is open, and delivery from a deployed server. Note that with
`npm run dev` a server restart straight after posting can drop that
announcement's push, since the fan-out runs after the response.

1. Sign in on a real Android phone (an emulator needs Google Play services).
   Allow notifications when asked.
2. `GET /api/users/me/notification-preferences` (see `docs/api-testing.http`)
   should now show `registeredDevices: 1`. If it is 0, look at step "If it does
   not work" below.
3. Close the app. As an admin, post an announcement from another device or with
   `POST /api/announcements`. The phone should show a notification within
   seconds; tapping it opens the app on the Alerts tab.
4. Post one with category `emergency`. It should use the emergency channel
   (louder, with the 🚨).
5. Open *Alerts*, switch **Push notifications** off, post another: nothing
   arrives. Switch it on again.
6. Sign out and back in as a different account on the same phone: only that
   account's alerts arrive.

## If it does not work

| Symptom | Likely cause |
|---|---|
| `registeredDevices` stays 0 | Notification permission refused; app built without `--dart-define=FCM_ENABLED=true`; `google-services.json` or the Gradle plugin missing (the app then logs "Firebase could not start" and carries on with push off); server asleep on Render's free tier (open the app again once it is up). |
| Registered, but nothing arrives | `FCM_ENABLED`/`FIREBASE_SERVICE_ACCOUNT` not set on the server (check the boot log); the service account belongs to a different Firebase project than the app's `google-services.json`; the user switched push off; battery optimisation is killing the app on that phone. |
| Notification arrives but is silent / low priority | The `announcements` channel was changed in the phone's app settings. |
| Arrives twice | Should not happen: while registered, the poll does not notify, and both paths use one notification id per announcement. Report it. |

## Limits and what is not built

* Android only. iOS needs an APNs key and Apple setup; web needs a VAPID key and
  a service worker. Neither is done, and both builds run with push off.
* One kind of push: new announcements, to everyone with push on. No
  per-category switches, no messages to one user or one class, no reminders by
  push (class and exam reminders stay local notifications).
* A device that fails to register (offline at launch) is not retried until the
  next launch or token refresh; the poll covers the gap.
* Up to 10 devices per account (the newest); FCM is sent in batches of 500.
* A signed-out session that *expired* cannot unregister its device (there is no
  valid login to do it with). Its token is removed the next time FCM reports it
  dead, or moves to whoever signs in next on that phone.
* The Firebase-backed adapter (`firebase_push_messaging.dart`) is the one piece
  not covered by automated tests, because it needs a real Firebase project. It
  is a thin conversion layer; everything around it is tested against a fake.
