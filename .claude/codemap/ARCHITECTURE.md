# School Schedule architecture (map)

`README.md` ("Architecture") has the detail; this page is only the shape.

```
DasacucakApp ─ AppEnvironment ─ RootView (tabs): Today · Calendar · Tasks · Notes · Settings
  App/Features/<Feature>/: <Feature>View + @Observable <Feature>ViewModel; Scan (VisionKit → Vision OCR → TimetableParser)
  Profile: first-launch OnboardingView (name, photo, theme) · AppTheme (Ծիրան/Կավիճ/Աստղիկ: colors, type, alt icon via \.theme)
  Share: SharePackage (.dasacucak JSON + readable text) via ShareLink in Tasks/Settings · onOpenURL → ShareInboxView (preview, then place)
  Today: NowCard (Timetable.phase: lesson/break countdowns) · Backpack (BackpackStore in App Group, per-day ticks)
App/Data/: AppEnvironment, DataStore (the only SwiftData writer), BackpackStore, ProfileStore (name/theme + photo file), NotificationScheduler (14 evenings of "tomorrow")
Shared/: models, SwiftData container in the App Group, ScheduleReader (read model for app, widget, notifications),
         Schedule/Timetable rules (pure), DaySnapshot values
Widget/: ScheduleProvider (timeline at lesson boundaries) · ScheduleWidget
Tests/:  TimetableTests, TimetableParserTests
```
