# Play Store release checklist

## Version and identity

- Package ID: `com.islamicoccasionplanner.app`
- First release version: `1.0.0+1`
- Product name shown to users: Islamic Occasion Planner
- Before every upload, increment the `+build` number in `pubspec.yaml`.

## Signing

1. Generate and securely back up one upload keystore. Do not commit it.
2. Copy `android/key.properties.example` to `android/key.properties`.
3. Set the four values to the actual keystore details.
4. Keep both the keystore and `key.properties` outside Git and in a secure backup.

Release builds intentionally stop if `android/key.properties` is missing. This prevents accidentally shipping a debug-signed build.

## Build and inspect

Run these locally after Flutter is no longer held by another process:

```powershell
flutter clean
flutter pub get
flutter analyze
flutter test
flutter build appbundle --release
Get-Item build\app\outputs\bundle\release\app-release.aab |
  Select-Object FullName,Length,LastWriteTime
Get-FileHash build\app\outputs\bundle\release\app-release.aab -Algorithm SHA256
```

Upload `build/app/outputs/bundle/release/app-release.aab` to the Play Console internal test track first. Verify installation, both splash variants, launcher icon, the home widget, a backup round trip, and a scheduled reminder on a physical Android device before production rollout.

## Data safety and permissions

The app stores planner data only on the device. It has no account, cloud backend, analytics SDK, advertising SDK, or Internet permission.

| Permission | Why it is used |
| --- | --- |
| `POST_NOTIFICATIONS` | Lets the user receive selected occasion reminders on Android 13+. |
| `RECEIVE_BOOT_COMPLETED` | Restores locally scheduled reminders after a device restart or app update. |

The export action shares a user-selected local JSON backup through the Android share sheet. Imported data is selected by the user and replaces local planner data only after confirmation.

## Store listing draft

**Short description**: Plan Islamic occasions, budgets, savings, and reminders offline.

**Full description**: Islamic Occasion Planner helps you prepare for important occasions with Hijri and Gregorian dates, budgets, savings targets, advance reminders, and a yearly expense view. Your information stays on your device, works offline, and can be exported as a local backup whenever you choose. Hijri dates may vary by local moon sighting, so you can adjust the calendar by one day and override an individual occasion date.

## Privacy policy draft

Islamic Occasion Planner stores occasions, budgets, savings, reminder preferences, and settings locally on your device. The app does not require an account and does not send this data to a server. A backup is exported or imported only when you explicitly choose a file. Notification permission is requested only when you enable reminders. The app contains no ads, analytics SDK, or data sale mechanism.
