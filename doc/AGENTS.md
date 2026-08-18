# AGENTS.md

## Project
Islamic Occasion Planner — lightweight Android app built with Flutter + Dart.

## Primary Goal
Build a fast, offline-first Android app that helps users prepare financially for important Islamic occasions by combining:
- Hijri + Gregorian dates
- Islamic occasion reminders
- event budgets
- savings targets
- local notifications
- yearly expense planning

The app is NOT a generic prayer/Quran super-app.

## Platform
- Android first
- Flutter stable
- Dart stable
- Google Play Store release target
- Build as Android App Bundle (AAB)
- Keep APK/AAB size as small as reasonably possible

## Important Product Rules
1. Offline-first by default.
2. No login in V1.
3. No cloud backend in V1 unless explicitly requested later.
4. Store user data locally.
5. Local notifications must work without requiring the app to stay open.
6. Hijri dates must support manual adjustment: -1 / 0 / +1 day.
7. Users must be able to override an event date manually.
8. Do not add Quran, Qibla, prayer times, Hadith, audio, social feed, AI assistant, ads, or unnecessary features unless requested.
9. Keep UI simple, modern, respectful, and fast.
10. Preserve all existing working functionality while making changes.

## Coding Rules
- Use null-safe Dart.
- Prefer simple architecture over unnecessary abstraction.
- Avoid oversized files.
- Keep widgets small and reusable.
- Separate UI, domain logic, storage, and services.
- No hardcoded magic numbers for business logic.
- No business logic inside build() methods.
- Use const widgets wherever possible.
- Avoid rebuilding large widget trees unnecessarily.
- Avoid large third-party packages when a small implementation is practical.
- Do not introduce a dependency without explaining why it is needed.
- Remove unused imports, assets, packages, and dead code.
- Handle errors gracefully.
- All dates must be timezone-safe for the user's local device timezone.
- Money calculations must avoid floating-point errors where possible.
- Currency should default to PKR but remain configurable later.

## State Management
Preferred: Riverpod.
If the project already uses another reasonable state-management approach, do not migrate unless there is a clear benefit.

## Local Storage
Preferred:
- Hive CE or Isar for structured local data, OR
- SharedPreferences only for tiny settings.
Choose the lightest suitable option.

Do not add SQLite unless relational queries truly require it.

## Notifications
Use local notifications.
Users should be able to enable reminders such as:
- 30 days before
- 15 days before
- 7 days before
- 3 days before
- 1 day before
- day of event

Notification scheduling must survive normal app restarts.
Handle Android notification permission requirements.

## Performance & App Size
- Avoid unnecessary native SDKs.
- Avoid Firebase in V1.
- Prefer vector icons over large images.
- Compress any raster assets.
- Do not bundle large fonts unless necessary.
- Use system fonts where possible.
- Use tree-shakeable icons.
- Test release size.
- Build release with:
  flutter build appbundle --release
- Consider:
  --split-debug-info
  --obfuscate
  only when appropriate for release.

## UI Reference Image
The user will provide a frontend/UI image reference to Codex.

When an image reference is provided:
1. Treat it as the primary visual direction.
2. Match hierarchy, spacing, cards, typography feel, navigation, radius, icon usage, and visual density.
3. Do not blindly copy text/data from the image.
4. Adapt visuals to this app's real features.
5. Keep accessibility and Android responsiveness intact.
6. Do not sacrifice usability merely to pixel-match a reference.

## Development Behavior
Before coding:
1. Read PRD.md.
2. Read ARCHITECTURE.md.
3. Read DESIGN_SPEC.md.
4. Read TASKS.md.
5. Inspect existing source before editing.

For every meaningful change:
- state what files will change
- implement the smallest complete solution
- run format/analyze/tests
- fix errors before stopping
- do not leave placeholder code unless task explicitly allows it

## Quality Gate
Before considering a task done:
- flutter format / dart format
- flutter analyze passes
- tests pass
- app launches
- no overflow on common Android phone sizes
- dark/light behavior is correct if supported
- local data survives restart
- notifications are schedulable
- no obvious broken states
