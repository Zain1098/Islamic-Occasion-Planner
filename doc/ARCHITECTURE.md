# Architecture

## 1. Tech Stack
- Flutter
- Dart
- Riverpod
- Lightweight local persistence
- flutter_local_notifications or equivalent mature local-notification package
- timezone package only if required for reliable scheduled notification behavior
- lightweight Hijri date library OR a small internal conversion layer

Avoid network API dependency for core functionality if a reliable local calculation library is adequate.

## 2. Architectural Style
Feature-first, lightweight clean architecture.

Suggested structure:

lib/
  app/
    app.dart
    router.dart
    theme/
  core/
    constants/
    utils/
    extensions/
    services/
  features/
    dashboard/
      data/
      domain/
      presentation/
    calendar/
      data/
      domain/
      presentation/
    events/
      data/
      domain/
      presentation/
    budget/
      data/
      domain/
      presentation/
    reminders/
      data/
      domain/
      presentation/
    settings/
      data/
      domain/
      presentation/
    backup/
      data/
      domain/
      presentation/
  shared/
    widgets/
    models/
  main.dart

Do not create empty folders merely to satisfy this structure. Add them when needed.

## 3. Core Models

### IslamicEvent
Fields:
- id
- title
- description/notes
- dateType: hijri | gregorian
- hijriMonth
- hijriDay
- gregorianDate optional
- manuallyOverriddenDate optional
- repeatsYearly
- enabled
- createdAt
- updatedAt

### BudgetItem
Fields:
- id
- eventId
- category
- plannedAmountMinorUnits
- actualAmountMinorUnits optional

### SavingEntry
Fields:
- id
- eventId
- amountMinorUnits
- entryType: add | subtract
- createdAt
- note optional

### ReminderPreference
Fields:
- eventId
- offsetsInDays
- enabled

### AppSettings
Fields:
- hijriAdjustmentDays
- currencyCode
- notificationsEnabled
- themeMode

## 4. Money
Store money as integer minor units or integer PKR amounts, not double.

For PKR V1:
Rs 5000 can be stored as 5000 integer if decimals are not supported.

## 5. Date Engine
Responsibilities:
- current local Gregorian date
- Gregorian ↔ Hijri conversion
- apply global Hijri offset
- resolve next occurrence of repeating Hijri event
- apply manual event override
- calculate days remaining
- handle year transitions

Create one DateService so date logic is not duplicated across widgets.

## 6. Savings Engine
Given:
- target
- saved
- event date
- current date

Calculate:
- remaining
- progress %
- days remaining
- required per day
- required per week
- required per month

Rules:
- never divide by zero
- completed target => required saving = 0
- overdue event => clearly mark as passed/overdue
- negative saved total should be prevented or intentionally handled

## 7. Notification Service
Responsibilities:
- request notification permission
- schedule notifications
- cancel notifications
- reschedule after event/settings edits
- create stable notification IDs
- schedule using local timezone
- avoid duplicates

Notification title example:
"12 Rabi-ul-Awwal is 7 days away"

Body example:
"Rs 3,500 remains in your planned budget."

## 8. Persistence
Repository interfaces should isolate storage from UI.

Suggested repositories:
- EventRepository
- BudgetRepository
- SavingRepository
- SettingsRepository

Use a lightweight local store.
Do not require network access to open dashboard.

## 9. Backup
Export a versioned JSON structure:

{
  "schemaVersion": 1,
  "exportedAt": "...",
  "settings": {},
  "events": [],
  "budgetItems": [],
  "savingEntries": []
}

Import must:
- validate schema
- reject corrupt data gracefully
- avoid partial destructive restore
- confirm before replacing current data

## 10. Navigation
Recommended bottom navigation:
- Home
- Calendar
- Plans
- Settings

Avoid more than 4–5 primary destinations.

## 11. Testing
At minimum:
- DateService tests
- savings calculation tests
- next-event calculation tests
- Hijri adjustment tests
- backup serialization tests
- repository tests if practical

## 12. Size Optimization
- no Firebase in V1
- no analytics SDK initially
- no ad SDK
- no video/audio packages
- no large bundled asset collections
- no custom font family unless design requires it
- use Material icons selectively
- inspect dependencies before adding
- run release-size analysis before Play Store submission
