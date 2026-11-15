# Դասացուցակ (School Schedule)

Native iOS 17+ app: scan a timetable with the camera, per-lesson notes and photos, automatic homework checklist, evening reminder with tomorrow's schedule, and a widget.

## Setup
1. `brew install xcodegen`
2. In `project.yml` set `DEVELOPMENT_TEAM` (Apple Team ID) and `BUNDLE_ID_BASE`.
3. `xcodegen generate && open SchoolSchedule.xcodeproj`

## Architecture
- **MVVM**: `@Observable` view models per feature (`App/Features/*`), Combine for change streams, debounce and timers.
- **Data**: SwiftData in the App Group (`Shared/Persistence`), shared with the widget. `DataStore` is the only writer; `ScheduleReader` is the read model reused by app, widget and notifications.
- **Rules**: `Shared/Schedule/Timetable.swift` (pure, unit-tested): focus day (today until the last lesson ends, then the next school day), next lesson of a subject, widget refresh boundaries.
- **Scan**: VisionKit document camera → Vision OCR → `TimetableParser` (layout-based grid) → editable review.
- **Notifications**: `NotificationScheduler` precomputes 14 evenings of "tomorrow" content and rebuilds on every save.
- **Widget**: `Widget/` timeline entries at each lesson start/end.

> Vision OCR may not recognise Armenian script on every iOS version; the review screen lets the user fix results.
