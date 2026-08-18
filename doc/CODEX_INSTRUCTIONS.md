# Codex Execution Instructions

You are implementing a production-quality Flutter Android app called Islamic Occasion Planner.

## Read First
Before editing any code:
1. AGENTS.md
2. PRD.md
3. ARCHITECTURE.md
4. DESIGN_SPEC.md
5. TASKS.md
6. the user-provided UI reference image

## Working Method
Work phase-by-phase.

For each phase:
1. inspect current code
2. identify exact files to modify
3. implement the smallest complete version
4. format code
5. run flutter analyze
6. run relevant tests
7. fix all introduced errors
8. summarize what was changed

Do not rewrite unrelated working code.

## UI Image Reference
A UI image will be attached/provided.

Use it as the visual source of truth where compatible with the PRD.

Analyze:
- layout hierarchy
- card shapes
- margins
- spacing
- typography scale
- icon placement
- navigation
- visual density

Then translate that design into Flutter widgets.

Do not create fake functionality merely to match the screenshot.

## Product Priority
Priority order:
1. correctness
2. reliable reminders
3. data persistence
4. simple UX
5. performance
6. app size
7. visual polish

## Dependency Rule
Before adding any package, check:
- is it actually necessary?
- does Flutter/Dart already provide enough?
- is there a smaller maintained package?
- does it add native SDK weight?
- does it require unnecessary permissions?

Avoid package accumulation.

## Forbidden Scope Creep
Do not add:
- Firebase
- Supabase
- authentication
- analytics
- ads
- Quran
- prayer timings
- Qibla
- AI
- cloud sync
unless the user explicitly changes scope.

## Completion Standard
Never mark a task complete merely because code was written.

A phase is complete only if:
- code compiles
- analyze passes
- relevant tests pass
- no obvious runtime breakage
- acceptance criteria in TASKS.md are satisfied

## Release Goal
Final Android release command:
flutter build appbundle --release

Before release:
- remove debug logs
- verify app name/package/version
- verify notification permission behavior
- verify no unnecessary Android permissions
- check AAB/release size
