# Product Requirements Document

## 1. Product Name
Working name: Islamic Occasion Planner

Alternative names can be decided later.

## 2. Problem
Users often remember important Islamic occasions only shortly before they arrive. The issue is not merely remembering the date; many occasions involve planned spending such as:
- Niaz
- lighting/decorations
- sadaqah
- dawat
- Ramadan preparation
- Eid expenses
- Qurbani-related expenses
- family/custom religious-event expenses

By the time the event is remembered, there may not be enough money available.

## 3. Core Solution
A lightweight Android app that:
1. Shows current Gregorian and Hijri dates.
2. Shows upcoming Islamic occasions.
3. Warns users well in advance.
4. Lets users assign a target budget to each occasion.
5. Calculates how much they should save per day/week/month.
6. Tracks saved amount and remaining target.
7. Provides a yearly view of upcoming planned Islamic expenses.

## 4. Target User
Primary:
- Muslim Android users
- Pakistan-focused initially
- users who want simple Hijri occasion planning and budgeting

The product should remain usable internationally later.

## 5. V1 Scope

### Home Dashboard
Display:
- current Gregorian date
- current Hijri date
- next Islamic occasion
- number of days remaining
- target budget
- saved amount
- remaining amount
- recommended daily saving
- upcoming events list

### Calendar
- Gregorian and Hijri date display
- monthly navigation
- Islamic occasions highlighted
- tap date/event to view details

### Events
Default Islamic occasions.
Allow:
- custom event creation
- custom title
- Hijri or Gregorian date
- repeat yearly
- manual date override
- notes

### Event Budget
Each event can contain categories such as:
- Niaz
- Lighting
- Decoration
- Dawat
- Sadqah
- Clothes
- Qurbani
- Transport
- Other

User can:
- add category
- set planned amount
- edit/delete category
- view total target

### Saving Tracker
For each event:
- target amount
- saved amount
- remaining amount
- days remaining
- save per day
- save per week
- save per month
- progress percentage

User can add or subtract saved money.

### Reminder System
User-selectable reminders:
- 30 days before
- 15 days before
- 7 days before
- 3 days before
- 1 day before
- event day

Reminder should mention:
- event name
- days remaining
- remaining target when applicable

### Yearly Planner
Display:
- all upcoming planned occasions
- target amount for each
- total planned annual amount
- approximate monthly amount needed to prepare

### Settings
- Hijri adjustment: -1 / 0 / +1
- notification toggle
- currency default: PKR
- backup export
- backup import
- theme: system/light/dark if implemented in V1

## 6. Important Date Rule
Hijri calendars can differ based on moon sighting.

Therefore:
- calculated Hijri date is a convenience, not an absolute religious declaration
- app must allow -1 / 0 / +1 day adjustment
- specific occasion date can be manually overridden
- UI should include a short note where appropriate:
  "Hijri dates may vary by local moon sighting."

## 7. Data Persistence
V1:
- local device storage
- offline-first
- no mandatory account
- no mandatory internet

Backup:
- export app data to a local JSON file
- restore from that JSON file

## 8. Out of Scope for V1
Do NOT build:
- Quran reader
- prayer times
- Qibla
- Hadith library
- Islamic articles
- live streaming
- community/social features
- chat
- AI assistant
- cloud account
- subscription
- ads
- web admin panel

## 9. Success Criteria
V1 is successful if a user can:
1. install the app
2. see today's Hijri date
3. see an upcoming Islamic occasion
4. create/edit an occasion
5. assign a budget
6. record savings
7. see required daily/monthly saving
8. receive advance local notification
9. adjust Hijri date
10. close/reopen the app without losing data
11. export and restore backup

## 10. Play Store Goals
- Android-first
- fast cold start
- low storage footprint
- no unnecessary permissions
- privacy-friendly
- no backend dependency in V1
- release as AAB
