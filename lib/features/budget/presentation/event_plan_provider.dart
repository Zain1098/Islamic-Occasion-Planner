import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/repository_providers.dart';
import '../../../core/services/savings_service.dart';
import '../../../shared/models/budget_item.dart';
import '../../../shared/models/islamic_event.dart';
import '../../../shared/models/saving_entry.dart';

class EventPlanData {
  const EventPlanData({
    required this.event,
    required this.budgetItems,
    required this.savingEntries,
    required this.savingsPlan,
  });

  final IslamicEvent event;
  final List<BudgetItem> budgetItems;
  final List<SavingEntry> savingEntries;
  final SavingsPlan savingsPlan;
}

final eventPlanProvider = FutureProvider.family<EventPlanData, String>((
  ref,
  eventId,
) async {
  final events = await ref.watch(eventRepositoryProvider).getAll();
  final event = events.where((item) => item.id == eventId).firstOrNull;
  if (event == null) throw StateError('Occasion no longer exists.');
  final budgetItems = await ref
      .watch(budgetRepositoryProvider)
      .getForEvent(eventId);
  final savingEntries = await ref
      .watch(savingRepositoryProvider)
      .getForEvent(eventId);
  final settings = await ref.watch(settingsRepositoryProvider).get();
  final dateService = ref.watch(dateServiceProvider);
  final target = budgetItems.fold(
    0,
    (total, item) => total + item.plannedAmount,
  );
  final saved = savingEntries.fold(
    0,
    (total, entry) => entry.entryType == SavingEntryType.add
        ? total + entry.amount
        : total - entry.amount,
  );
  final days = dateService.daysRemaining(
    event,
    hijriAdjustmentDays: settings.hijriAdjustmentDays,
  );
  return EventPlanData(
    event: event,
    budgetItems: List.unmodifiable(budgetItems),
    savingEntries: List.unmodifiable(
      savingEntries..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
    ),
    savingsPlan: SavingsPlan(
      targetAmount: target,
      savedAmount: saved < 0 ? 0 : saved,
      daysRemaining: days,
    ),
  );
});
