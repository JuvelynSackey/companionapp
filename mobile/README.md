# Campus Companion — Flutter app

Layout of `lib/`:

- `core/` — API client, secure token storage, notifications, theme, `.ics` and schedule utilities.
- `data/` — `api/` (one client per backend module), `models/`, `logic/` (GPA and grade engines), `repositories/`.
- `features/` — one folder per screen area: auth, onboarding, dashboard, timetable, exams, alerts,
  events, locations (custom-painter map), analytics, quizzes, resources, student_hub, assistant,
  tutor, profile (digital ID), shell (bottom navigation).

Run and setup instructions are in the [root README](../README.md). Quick checks:

```
flutter analyze
flutter test
```

Data that lives only on the device (exams, Student Hub content, Lost & Found reports, resources)
is listed in [PROJECT_AUDIT.md](../PROJECT_AUDIT.md).
