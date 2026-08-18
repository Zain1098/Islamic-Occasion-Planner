import 'dart:convert';

import '../../../core/storage/hive_app_storage.dart';
import '../../../shared/models/budget_item.dart';
import 'budget_repository.dart';

class HiveBudgetRepository implements BudgetRepository {
  HiveBudgetRepository(this._storage);

  final HiveAppStorage _storage;

  @override
  Future<List<BudgetItem>> getAll() async => _storage.budgetItems.values
      .map(
        (value) =>
            BudgetItem.fromMap(jsonDecode(value) as Map<String, dynamic>),
      )
      .toList(growable: false);

  @override
  Future<List<BudgetItem>> getForEvent(String eventId) async => (await getAll())
      .where((item) => item.eventId == eventId)
      .toList(growable: false);

  @override
  Future<void> save(BudgetItem item) =>
      _storage.budgetItems.put(item.id, jsonEncode(item.toMap()));

  @override
  Future<void> delete(String itemId) => _storage.budgetItems.delete(itemId);

  @override
  Future<void> deleteForEvent(String eventId) async {
    final keys = _storage.budgetItems.keys
        .where((key) {
          final item = BudgetItem.fromMap(
            jsonDecode(_storage.budgetItems.get(key)!) as Map<String, dynamic>,
          );
          return item.eventId == eventId;
        })
        .toList(growable: false);
    await _storage.budgetItems.deleteAll(keys);
  }
}
