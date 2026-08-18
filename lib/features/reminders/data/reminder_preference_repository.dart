import '../../../shared/models/reminder_preference.dart';

abstract interface class ReminderPreferenceRepository {
  Future<ReminderPreference?> getForEvent(String eventId);
  Future<void> save(ReminderPreference preference);
  Future<void> delete(String eventId);
}
