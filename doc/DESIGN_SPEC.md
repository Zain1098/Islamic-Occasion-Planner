# Design Specification

## 1. UI Reference
The user will provide Codex with a UI reference image.

That image should be treated as visual guidance for:
- visual hierarchy
- card layout
- spacing
- typography feel
- navigation structure
- component proportions
- icon treatment
- corner radius
- overall premium/minimal character

Do not copy irrelevant content from the reference.

## 2. Visual Direction
Style:
- modern
- clean
- calm
- premium but lightweight
- Islamic identity without visual clutter
- finance/planning information must remain easy to scan

Avoid:
- excessive mosque/crescent ornament
- glowing effects everywhere
- gradients on every card
- giant decorative illustrations
- dense dashboards
- tiny text

## 3. Home Screen Hierarchy

Top:
- greeting optional
- Gregorian date
- Hijri date

Primary card:
- next event title
- days remaining
- progress ring/bar
- target
- saved
- remaining
- required daily saving

Actions:
- Add Saving
- View Plan

Then:
- Upcoming Events section
- yearly planning summary

## 4. Event Card
Should show:
- event title
- Hijri/Gregorian date
- days remaining
- budget target
- saving progress

Do not overload cards.

## 5. Budget Detail Screen
Sections:
1. event header
2. target summary
3. savings progress
4. planned expense categories
5. saving history
6. reminder settings

## 6. Calendar
Requirements:
- month navigation
- Gregorian date legible
- Hijri date secondary
- events clearly marked
- selected date state
- current date state

## 7. Typography
Prefer system/default Flutter typography unless the UI reference strongly requires another typeface.

Keep:
- clear title hierarchy
- readable minimum sizes
- high contrast
- tabular/clear number presentation for money where possible

## 8. Spacing
Use a consistent spacing scale such as:
4, 8, 12, 16, 20, 24, 32

Do not use arbitrary spacing everywhere.

## 9. Radius
Use consistent radii such as:
- small: 8
- medium: 12
- card: 16
- prominent card: 20

Adjust based on reference image.

## 10. Responsive Rules
Design for common Android widths including:
- ~320dp
- 360dp
- 390dp
- 411dp+

No horizontal overflow.

Use SafeArea appropriately.

## 11. Accessibility
- do not rely on color alone
- sufficient contrast
- tap targets roughly 48dp
- support text scaling reasonably
- meaningful semantic labels for buttons/icons

## 12. Dark Mode
If implemented:
- do not simply invert colors
- preserve hierarchy
- ensure money/status colors remain readable

## 13. Empty States
Examples:
No event budget:
"Plan this occasion before the expense reaches you."

No upcoming custom plans:
"Add an occasion you want to prepare for."

Keep wording short.

## 14. Image Reference Workflow for Codex
When the reference image is supplied:
1. inspect it first
2. identify reusable visual patterns
3. map those patterns to this app's actual screens
4. implement one screen at a time
5. compare output visually
6. keep business logic separate from visual matching
