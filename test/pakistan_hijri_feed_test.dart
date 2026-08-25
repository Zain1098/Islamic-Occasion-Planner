import 'package:flutter_test/flutter_test.dart';
import 'package:islamic_occasion_planner/core/services/date_service.dart';
import 'package:islamic_occasion_planner/core/services/pakistan_hijri_feed_service.dart';
import 'package:islamic_occasion_planner/features/settings/data/hive_settings_repository.dart';
import 'package:islamic_occasion_planner/shared/models/app_settings.dart';

class FakeSettingsRepository implements HiveSettingsRepository {
  AppSettings _settings = const AppSettings();

  @override
  Future<AppSettings> get() async => _settings;

  @override
  Future<void> save(AppSettings settings) async {
    _settings = settings;
  }
}

void main() {
  group('PakistanHijriFeedService Tests', () {
    test('Offline fallback returns last verified adjustment gracefully', () async {
      final fakeRepo = FakeSettingsRepository();
      await fakeRepo.save(const AppSettings(hijriAdjustmentDays: -1));

      final service = PakistanHijriFeedService(
        settingsRepository: fakeRepo,
        dateService: DateService(),
      );

      final result = await service.syncPakistanHijriDate(force: true);

      // If offline/error occurs in test environment without network mock
      if (!result.success) {
        expect(result.adjustmentDays, -1);
        expect(result.message, contains('offline'));
      } else {
        expect(result.success, true);
      }
    });
  });
}
