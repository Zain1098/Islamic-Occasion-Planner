import 'package:flutter_test/flutter_test.dart';
import 'package:islamic_occasion_planner/shared/models/app_settings.dart';

void main() {
  group('Hijri Sync & AppSettings Tests', () {
    test('AppSettings serializes and deserializes autoSyncHijri and lastHijriSyncIso', () {
      const settings = AppSettings(
        hijriAdjustmentDays: 1,
        currencyCode: 'PKR',
        autoSyncHijri: true,
        lastHijriSyncIso: '2026-08-25',
      );

      final map = settings.toMap();
      expect(map['autoSyncHijri'], true);
      expect(map['lastHijriSyncIso'], '2026-08-25');

      final deserialized = AppSettings.fromMap(map);
      expect(deserialized.hijriAdjustmentDays, 1);
      expect(deserialized.autoSyncHijri, true);
      expect(deserialized.lastHijriSyncIso, '2026-08-25');
    });

    test('AppSettings copyWith handles autoSyncHijri correctly', () {
      const settings = AppSettings();
      expect(settings.autoSyncHijri, true);

      final updated = settings.copyWith(autoSyncHijri: false);
      expect(updated.autoSyncHijri, false);
      expect(updated.hijriAdjustmentDays, 0);
    });
  });
}
