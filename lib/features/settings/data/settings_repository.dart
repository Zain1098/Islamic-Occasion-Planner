import '../../../shared/models/app_settings.dart';

abstract interface class SettingsRepository {
  Future<AppSettings> get();
  Future<void> save(AppSettings settings);
}
