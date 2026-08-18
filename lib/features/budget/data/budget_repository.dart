import '../../../shared/models/budget_item.dart';

abstract interface class BudgetRepository {
  Future<List<BudgetItem>> getAll();
  Future<List<BudgetItem>> getForEvent(String eventId);
  Future<void> save(BudgetItem item);
  Future<void> delete(String itemId);
  Future<void> deleteForEvent(String eventId);
}
