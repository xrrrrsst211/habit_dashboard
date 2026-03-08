# Habit Dashboard

Habit Dashboard is a polished Flutter habit tracker built for two common use cases in one app: **building good habits** and **quitting bad ones**.

## What the app includes
- Build habits and quit habits
- Streaks, milestones, skip days, slips, and relapse tracking
- History, insights, heatmap analytics, trend storytelling, and recovery metrics
- Smart reminders, weekly review, focus suggestions, and exportable progress cards
- Notes, motivation, archive, sorting, filters, and settings/preferences
- Backup, restore, restore points, and JSON export/import
- Onboarding, splash, privacy policy, about screen, and support details

## Tech stack
- Flutter
- SharedPreferences for local persistence
- Local notifications
- File picker for import/export workflows

## Run locally
```bash
flutter pub get
flutter run -d chrome
```

## Release builds
```bash
flutter build apk
flutter build web
```

## Project hygiene
Before zipping or pushing the project, avoid including generated folders such as:
- `.dart_tool/`
- `build/`
- `**/ephemeral/`
- browser device profiles created by Flutter web runs

## Privacy
A local privacy policy is included at `assets/privacy_policy.md`.

## Product note
This project is designed as a strong indie-style habit tracker MVP+ with a local-first foundation and Play Market prep in mind.
