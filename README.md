# Islamic Occasion Planner

An offline-first Flutter Android planner for important Islamic occasions. It combines Hijri and Gregorian dates, local reminders, event budgets, saving targets, a yearly planning view, and local JSON backup/restore.

## Privacy-first V1

- No account or cloud backend
- No analytics, ads, or Internet permission
- Planner data stays on the device
- Backup export and import happen only when the user selects them
- Hijri dates support a global -1/0/+1-day adjustment and per-occasion manual overrides

## Run locally

```powershell
flutter pub get
flutter run
```

## Quality checks

```powershell
flutter analyze
flutter test
```

## Android release

Release builds require a private Android upload keystore. Copy `android/key.properties.example` to `android/key.properties`, set the local keystore values, and follow the detailed [Play Store release checklist](doc/PLAY_STORE_RELEASE.md).
