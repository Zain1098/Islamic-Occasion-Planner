import 'package:flutter_test/flutter_test.dart';
import 'package:islamic_occasion_planner/core/services/date_service.dart';
import 'package:islamic_occasion_planner/core/services/hijri_sync_service.dart';
import 'package:islamic_occasion_planner/features/settings/data/settings_repository.dart';
import 'package:islamic_occasion_planner/shared/models/app_settings.dart';

class _FakeSettingsRepository implements SettingsRepository {
  _FakeSettingsRepository(this.settings);

  AppSettings settings;

  @override
  Future<AppSettings> get() async => settings;

  @override
  Future<void> save(AppSettings value) async {
    settings = value;
  }
}

void main() {
  test(
    'uses a confirmed Pakistan record to save the matching adjustment',
    () async {
      final repository = _FakeSettingsRepository(const AppSettings());
      final service = HijriSyncService(
        settingsRepository: repository,
        dateService: DateService(clock: () => DateTime(2026, 8, 25)),
        request: (_, _) async => '''[
        {
          "hijri_year": 1448,
          "hijri_month": 3,
          "starts_on": "2026-08-15",
          "authority_name": "Central Ruet-e-Hilal Committee Pakistan",
          "source_url": "https://www.radio.gov.pk/announcement",
          "announced_at": "2026-08-13T13:00:00Z"
        }
      ]''',
      );

      final result = await service.syncHijriDate(force: true);

      expect(result.success, isTrue);
      expect(
        result.officialMonth?.authorityName,
        'Central Ruet-e-Hilal Committee Pakistan',
      );
      expect(repository.settings.lastHijriSyncIso, '2026-08-25');
      expect(repository.settings.hijriAdjustmentDays, -1);
    },
  );

  test('does not sync when automatic Hijri sync is disabled', () async {
    final repository = _FakeSettingsRepository(
      const AppSettings(autoSyncHijri: false),
    );
    final service = HijriSyncService(
      settingsRepository: repository,
      dateService: DateService(clock: () => DateTime(2026, 8, 25)),
    );

    final result = await service.syncHijriDate();

    expect(result.success, isFalse);
    expect(result.message, 'Official Hijri auto-sync is disabled in settings.');
    expect(repository.settings.lastHijriSyncIso, isNull);
    expect(repository.settings.hijriAdjustmentDays, 0);
  });

  test('rejects a confirmed record after the thirtieth Hijri day', () async {
    final repository = _FakeSettingsRepository(const AppSettings());
    final service = HijriSyncService(
      settingsRepository: repository,
      dateService: DateService(clock: () => DateTime(2026, 9, 14)),
      request: (_, _) async => '''[
        {
          "hijri_year": 1448,
          "hijri_month": 3,
          "starts_on": "2026-08-15",
          "authority_name": "Central Ruet-e-Hilal Committee Pakistan",
          "source_url": "https://www.radio.gov.pk/announcement",
          "announced_at": "2026-08-13T13:00:00Z"
        }
      ]''',
    );

    final result = await service.syncHijriDate(force: true);

    expect(result.success, isFalse);
    expect(
      result.message,
      'Latest official Hijri record does not cover today. Using calculated date.',
    );
    expect(repository.settings.lastHijriSyncIso, isNull);
  });
}
