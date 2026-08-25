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
    'uses a confirmed official month to save the matching adjustment',
    () async {
      final repository = _FakeSettingsRepository(const AppSettings());
      final service = HijriSyncService(
        settingsRepository: repository,
        dateService: DateService(clock: () => DateTime(2026, 8, 25)),
        request: (_, __) async => '''[
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
      expect(repository.settings.lastHijriSyncIso, '2026-08-25');
      expect(repository.settings.hijriAdjustmentDays, -1);
    },
  );
}
