# Noor home-screen widget device check

Run this on a physical Android phone before treating the widget as release-ready.

1. Long-press the launcher, add **Noor occasion plan**, and confirm its default empty state renders without clipping.
2. Open Noor, create or edit the next occasion and its budget, return to Home, then confirm the widget title, days left, and remaining amount refresh.
3. Tap both the widget body and **OPEN PLAN**. With Noor open and closed, each must open Noor directly to the Plans tab.
4. Reboot the phone. Confirm the widget still appears, has readable fallback content, and opens Noor.
5. On a battery-restricted device, repeat step 2 after backgrounding Noor. If the launcher delays an update, reopening Noor must refresh it on the next dashboard load.

The widget deliberately has no periodic background wake-up (`updatePeriodMillis=0`): it refreshes from real planner data when the dashboard is loaded, avoiding a battery-heavy repeating Android job.
