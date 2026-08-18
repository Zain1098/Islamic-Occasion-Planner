# Implementation Tasks

## Phase 0 — Project Setup
- [ ] Create Flutter Android project
- [ ] Set Android application ID
- [ ] Configure linting
- [ ] Add Riverpod
- [ ] Select lightweight local storage
- [ ] Add local notification package
- [ ] Add only required date/Hijri dependency
- [ ] Create theme and app shell
- [ ] Add bottom navigation

Acceptance:
- app launches
- flutter analyze passes
- no unnecessary packages

## Phase 1 — Data Layer
- [ ] IslamicEvent model
- [ ] BudgetItem model
- [ ] SavingEntry model
- [ ] ReminderPreference model
- [ ] AppSettings model
- [ ] local repositories
- [ ] seed default occasions

Acceptance:
- data persists after restart
- models serialize correctly

## Phase 2 — Date Engine
- [ ] current Hijri date
- [ ] current Gregorian date
- [ ] Hijri global adjustment
- [ ] next occurrence calculation
- [ ] custom event date
- [ ] manual override
- [ ] days remaining

Acceptance:
- unit tests cover month/year transitions
- -1/0/+1 setting works

## Phase 3 — Dashboard UI
- [ ] match provided UI reference direction
- [ ] current dates
- [ ] next-event hero card
- [ ] savings progress
- [ ] upcoming events
- [ ] yearly summary

Acceptance:
- no overflow at common phone widths
- works offline

## Phase 4 — Event Management
- [ ] events list
- [ ] event details
- [ ] create custom event
- [ ] edit event
- [ ] disable/delete custom event
- [ ] yearly recurrence

## Phase 5 — Budget Planner
- [ ] create budget item
- [ ] edit/delete budget item
- [ ] calculate target
- [ ] saved amount
- [ ] remaining amount
- [ ] daily/weekly/monthly saving calculation
- [ ] saving history

Acceptance:
- calculations have unit tests

## Phase 6 — Calendar
- [ ] month calendar
- [ ] Hijri secondary dates
- [ ] highlight events
- [ ] selected/current states
- [ ] open event details

## Phase 7 — Notifications
- [ ] notification permission
- [ ] schedule reminder offsets
- [ ] cancel/reschedule on edits
- [ ] notification tap opens relevant event if practical
- [ ] test reboot/restart behavior where supported

## Phase 8 — Settings
- [ ] Hijri -1/0/+1 adjustment
- [ ] notification master switch
- [ ] currency display
- [ ] theme mode

## Phase 9 — Backup
- [ ] export JSON
- [ ] import JSON
- [ ] schema version
- [ ] validation
- [ ] replace-data confirmation
- [ ] error handling

## Phase 10 — Polish
- [ ] loading states
- [ ] empty states
- [ ] error states
- [ ] accessibility review
- [ ] app icon
- [ ] splash
- [ ] remove debug content
- [ ] remove unused assets/dependencies

## Phase 11 — Play Store Release
- [ ] set version
- [ ] release signing
- [ ] build AAB
- [ ] test release build
- [ ] inspect size
- [ ] privacy policy if required
- [ ] screenshots
- [ ] store description
- [ ] data safety form
- [ ] verify permissions
