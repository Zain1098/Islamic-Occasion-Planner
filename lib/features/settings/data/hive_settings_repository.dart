import 'dart:convert';

import '../../../core/storage/hive_app_storage.dart';
import '../../../shared/models/app_settings.dart';
import 'settings_repository.dart';

class HiveSettingsRepository implements SettingsRepository {
  HiveSettingsRepository(this._storage);

  static const _settingsKey = 'app_settings';
  final HiveAppStorage _storage;

  @override
  Future<AppSettings> get() async {
    final value = _storage.settings.get(_settingsKey);
    return value == null
        ? const AppSettings()
        : AppSettings.fromMap(jsonDecode(value) as Map<String, dynamic>);
  }

  @override
  Future<void> save(AppSettings settings) =>
      _storage.settings.put(_settingsKey, jsonEncode(settings.toMap()));
}
