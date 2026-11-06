# Usability study: tester guide and feedback form

A short trial with friends or classmates (5 to 10 people is enough) gives the
report a real usability evaluation. Each tester needs about 15 minutes.

Ethics: responses are anonymous (no names, emails or student IDs are asked),
and taking part is voluntary. Mention the study to your supervisor; the report
currently says no human participants were involved, so it will need updating
once results come in.

---

## 1. Get the app to testers

**Android phones** (most testers):

1. Send them the install file (APK). Use the one for modern phones:
   `app-arm64-v8a-release.apk` (about 20 to 30 MB). If it says "App not
   installed" on an older phone, send `app-armeabi-v7a-release.apk` instead.
   Share it on WhatsApp (as a document) or upload it to Google Drive and send
   the link.
2. On their phone they open the file. Android asks to allow installing from
   that app (WhatsApp, Drive or Files): tap **Settings**, turn on **Allow from
   this source**, go back and tap **Install**.
3. If Play Protect warns about an unknown app, tap **More details** then
   **Install anyway**. (The app is not on the Play Store, so this is normal.)

**iPhones:** the app cannot be installed on iPhones without Apple's developer
programme. iPhone users can watch over a friend's shoulder or skip the study.

**Before they start:** open
https://campus-companion-backend-1bye.onrender.com/api/health in a browser and
wait for `"status":"ok"`. The free server sleeps after 15 minutes without use;
this wakes it up.

---

## 2. Message to send testers (copy and paste)

> Hi! I'm testing Campus Companion, the app for my final-year project. It
> takes about 15 minutes. Please install it (file attached), try the tasks
> below, then fill in the anonymous form: [FORM LINK]
>
> 1. Open the app, choose University of Ghana, and sign up (email or Google).
> 2. Timetable: add one or two of your classes.
> 3. Exams: add an exam.
> 4. Grades & GPA: tap **Add a result** and add two courses you've done. Look at
>    your CGPA and class, then try **What if?**.
> 5. AI Assistant: ask "When is my next exam?" or "What is my GPA?"
> 6. AI Tutor: pick a course and ask it to explain something (you can attach
>    lecture slides as a PDF).
> 7. Resources > Lost & Found: post something you lost (a photo is optional).
> 8. Events: open an event and RSVP.
>
> Use made-up data if you prefer. Thank you!

---

## 3. The form (create it in Google Forms)

Go to https://forms.google.com, start a blank form, title it
**"Campus Companion: user feedback"**, and add these questions. Under
Settings, turn **off** "Collect email addresses".

**Section 1: About you**

1. Consent (required, checkbox): *I agree to take part. My answers are
   anonymous and will be used only in a final-year project report.*
2. Which level are you in? (Multiple choice: Level 100, 200, 300, 400, Other)
3. Which phone did you use? (Multiple choice: Android, I watched someone else use it)
4. Which tasks did you try? (Checkboxes: Sign up, Timetable, Exams, Add a
   result / GPA, What if?, AI Assistant, AI Tutor, Lost & Found, Events)

**Section 2: Campus Companion features**

Use a **Multiple choice grid**. Rows are the statements below; columns are
*Strongly disagree, Disagree, Neutral, Agree, Strongly agree*.

- S1. The app was easy to install and sign up for.
- S2. The app is easy to navigate.
- S3. Adding my classes and exams was easy.
- S4. The GPA, FGPA and class figures were clear.
- S5. The AI Assistant and Tutor gave useful answers.
- S6. Lost & Found was easy to use.
- S7. The app responded quickly.
- S8. I would use this app during the semester.

**Section 3: System Usability Scale**

Another **Multiple choice grid**, same five columns. Keep the wording exactly
as below (it is a standard questionnaire, and some items are negative on
purpose):

- U1. I think that I would like to use this system frequently.
- U2. I found the system unnecessarily complex.
- U3. I thought the system was easy to use.
- U4. I think that I would need the support of a technical person to be able to use this system.
- U5. I found the various functions in this system were well integrated.
- U6. I thought there was too much inconsistency in this system.
- U7. I would imagine that most people would learn to use this system very quickly.
- U8. I found the system very cumbersome to use.
- U9. I felt very confident using the system.
- U10. I needed to learn a lot of things before I could get going with this system.

**Section 4: Your comments** (paragraph answers, optional)

- What did you like most?
- What problems did you run into?
- What would you add or change?

Tap **Send**, then the link icon, to copy the form link into the message above.

---

## 4. When the responses are in

In Google Forms open **Responses**, then the green Sheets icon, then
**File > Download > Comma-separated values (.csv)**. Save the file in the
project folder and tell Claude its name. The analysis will give:

- counts and percentages for each statement (like Tables 4.5 and 4.6 in the
  comparison report),
- each tester's SUS score (0 to 100) and the average, compared with the usual
  benchmark of 68,
- the common themes in the comments,

and the report's Section 4 and limitations will be updated to match.
