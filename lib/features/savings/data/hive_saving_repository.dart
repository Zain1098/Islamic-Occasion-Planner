import 'dart:convert';

import '../../../core/storage/hive_app_storage.dart';
import '../../../shared/models/saving_entry.dart';
import 'saving_repository.dart';

class HiveSavingRepository implements SavingRepository {
  HiveSavingRepository(this._storage);

  final HiveAppStorage _storage;

  @override
  Future<List<SavingEntry>> getAll() async => _storage.savingEntries.values
      .map(
        (value) =>
            SavingEntry.fromMap(jsonDecode(value) as Map<String, dynamic>),
      )
      .toList(growable: false);

  @override
  Future<List<SavingEntry>> getForEvent(String eventId) async =>
      (await getAll())
          .where((entry) => entry.eventId == eventId)
          .toList(growable: false);

  @override
  Future<void> save(SavingEntry entry) =>
      _storage.savingEntries.put(entry.id, jsonEncode(entry.toMap()));

  @override
  Future<void> delete(String entryId) => _storage.savingEntries.delete(entryId);

  @override
  Future<void> deleteForEvent(String eventId) async {
    final keys = _storage.savingEntries.keys
        .where((key) {
          final entry = SavingEntry.fromMap(
            jsonDecode(_storage.savingEntries.get(key)!)
                as Map<String, dynamic>,
          );
          return entry.eventId == eventId;
        })
        .toList(growable: false);
    await _storage.savingEntries.deleteAll(keys);
  }
}
