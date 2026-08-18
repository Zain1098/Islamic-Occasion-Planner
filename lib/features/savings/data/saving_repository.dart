import '../../../shared/models/saving_entry.dart';

abstract interface class SavingRepository {
  Future<List<SavingEntry>> getAll();
  Future<List<SavingEntry>> getForEvent(String eventId);
  Future<void> save(SavingEntry entry);
  Future<void> delete(String entryId);
  Future<void> deleteForEvent(String eventId);
}
