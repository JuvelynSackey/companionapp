# Running the demo on the phone (defence checklist)

All commands are typed in a VS Code terminal (Terminal, then New Terminal).
Start every time by going to the project folder:

```
cd "C:\Users\Makel\Desktop\Final Year Project\campus-companion-app"
```

## A. The day before: install the latest app

1. Plug the phone into the laptop with a USB **data** cable.
2. On the phone, unlock it. If it asks "Allow USB debugging?", tick
   "Always allow from this computer" and tap **Allow**.
3. Check the laptop sees it:
   ```
   adb devices
   ```
   You should see one line ending in `device`. If the list is empty, see
   section E.
4. Install the app (takes a few minutes; it opens the app when done):
   ```
   .\run-on-phone.ps1
   ```
5. Sign in once to check it works. The app now uses the live server, so it
   works anywhere with internet, even unplugged.

## B. On the day, before you present

1. **Wake the server** (it sleeps after about 15 minutes idle). Open this in
   any browser and wait until it shows `"status":"ok"` (up to a minute):
   https://campus-companion-backend-1bye.onrender.com/api/health
2. Connect the laptop to the projector.
3. Plug the phone in and unlock it.

## C. Show the phone on the screen

```
.\show-phone.ps1
```

A window called **Campus Companion** shows the phone live. Drag it onto the
projector screen.

| To do this | Do this in the window |
|---|---|
| Tap | Left-click |
| Swipe or scroll | Click and drag, or the mouse wheel |
| Go back | Right-click |
| Type | Use the laptop keyboard |
| Full screen | Alt+F (press again to leave) |
| Stop mirroring | Close the window |

The cable must stay plugged in while mirroring. You can also just use the
phone itself; the window follows it.

## D. Accounts

- **Google:** tap Continue with Google and pick your account.
- **Demo student / admin / lecturer on the live server:** the passwords are
  in `backend\seed-credentials.local.txt` (open it in VS Code). The local
  passwords (`student123`, `admin123`) do **not** work on the live server.
- **Push notification demo:** sign in as admin on another device (or the web
  build), post an announcement, and it arrives on the phone.

## E. If something goes wrong

**`adb devices` shows nothing**
1. Unplug and replug, try another USB port.
2. Use a data cable (some cables only charge).
3. On the phone, pull down the notifications, tap the USB notification and
   choose **Transferring files**.
4. Settings, Developer options: **USB debugging** must be on. Turn it off
   and on again if needed.
5. Run `adb kill-server`, then `adb devices` again.

**`adb devices` says `unauthorized`**: unlock the phone and tap **Allow** on
the prompt. If there is no prompt, Developer options, Revoke USB debugging
authorisations, then replug.

**The app says it cannot reach the server**: open the health link in section
B and wait for it to load, then try again in the app.

**No internet at the venue** (backup, uses this laptop as the server):
1. In one terminal: `.\start-dev.ps1` (leave it running).
2. In a second terminal: `.\run-on-phone.ps1 -Local`
3. Keep the cable plugged in. The accounts are then the local ones:
   `student@ug.edu.gh` / `student123` and `admin@ug.edu.gh` / `admin123`.
   Google sign-in and push still need internet.
4. To go back to the live server later, run `.\run-on-phone.ps1` again.

**The mirror window doesn't open**: close it, unplug and replug the phone,
and run `.\show-phone.ps1` again. If scrcpy is missing:
`winget install Genymobile.scrcpy`, then open a new terminal.
