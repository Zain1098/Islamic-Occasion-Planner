import 'dart:convert';

import '../../../core/storage/hive_app_storage.dart';
import '../../../shared/models/reminder_preference.dart';
import 'reminder_preference_repository.dart';

class HiveReminderPreferenceRepository implements ReminderPreferenceRepository {
  HiveReminderPreferenceRepository(this._storage);

  final HiveAppStorage _storage;

  @override
  Future<ReminderPreference?> getForEvent(String eventId) async {
    final value = _storage.reminderPreferences.get(eventId);
    return value == null
        ? null
        : ReminderPreference.fromMap(jsonDecode(value) as Map<String, dynamic>);
  }

  @override
  Future<void> save(ReminderPreference preference) => _storage
      .reminderPreferences
      .put(preference.eventId, jsonEncode(preference.toMap()));

  @override
  Future<void> delete(String eventId) =>
      _storage.reminderPreferences.delete(eventId);
}
