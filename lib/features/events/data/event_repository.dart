import '../../../shared/models/islamic_event.dart';

abstract interface class EventRepository {
  Future<List<IslamicEvent>> getAll();
  Future<IslamicEvent?> getById(String eventId);
  Future<void> save(IslamicEvent event);
  Future<void> delete(String eventId);
  Future<void> seedDefaults();
}
