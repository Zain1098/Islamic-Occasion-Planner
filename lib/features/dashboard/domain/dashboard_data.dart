import '../../../core/services/date_service.dart';
import '../../../shared/models/budget_item.dart';
import '../../../shared/models/islamic_event.dart';
import '../../../shared/models/saving_entry.dart';

class DashboardEventSummary {
  const DashboardEventSummary({
    required this.event,
    required this.date,
    required this.daysRemaining,
    required this.targetAmount,
    required this.savedAmount,
  });

  final IslamicEvent event;
  final DateTime date;
  final int daysRemaining;
  final int targetAmount;
  final int savedAmount;

  int get remainingAmount =>
      (targetAmount - savedAmount).isNegative ? 0 : targetAmount - savedAmount;
  double get progress =>
      targetAmount == 0 ? 0 : (savedAmount / targetAmount).clamp(0, 1);
  int get dailySavingRequired {
    if (remainingAmount == 0 || daysRemaining <= 0) return 0;
    return (remainingAmount / daysRemaining).ceil();
  }
}

class DashboardData {
  const DashboardData({
    required this.today,
    required this.hijriToday,
    required this.upcomingEvents,
    required this.totalPlannedAmount,
  });

  final DateTime today;
  final HijriDate hijriToday;
  final List<DashboardEventSummary> upcomingEvents;
  final int totalPlannedAmount;

  DashboardEventSummary? get nextEvent =>
      upcomingEvents.isEmpty ? null : upcomingEvents.first;
  int get monthlyAmountNeeded =>
      totalPlannedAmount == 0 ? 0 : (totalPlannedAmount / 12).ceil();
}

class DashboardCalculator {
  DashboardCalculator(this._dateService);

  final DateService _dateService;

  DashboardData build({
    required List<IslamicEvent> events,
    required List<BudgetItem> budgetItems,
    required List<SavingEntry> savingEntries,
    required int hijriAdjustmentDays,
    DateTime? now,
  }) {
    final today = _dateService.dateOnly(now ?? _dateService.today());
    final summaries =
        events
            .where((event) => event.enabled)
            .map((event) {
              final targetAmount = budgetItems
                  .where((item) => item.eventId == event.id)
                  .fold(0, (total, item) => total + item.plannedAmount);
              final savedAmount = savingEntries
                  .where((entry) => entry.eventId == event.id)
                  .fold(
                    0,
                    (total, entry) => entry.entryType == SavingEntryType.add
                        ? total + entry.amount
                        : total - entry.amount,
                  );
              final date = _dateService.resolveEventDate(
                event,
                from: today,
                hijriAdjustmentDays: hijriAdjustmentDays,
              );
              return DashboardEventSummary(
                event: event,
                date: date,
                daysRemaining: _dateService.daysRemaining(
                  event,
                  from: today,
                  hijriAdjustmentDays: hijriAdjustmentDays,
                ),
                targetAmount: targetAmount,
                savedAmount: savedAmount < 0 ? 0 : savedAmount,
              );
            })
            .where((summary) => summary.daysRemaining >= 0)
            .toList()
          ..sort((a, b) => a.date.compareTo(b.date));

    return DashboardData(
      today: today,
      hijriToday: _dateService.hijriDateFor(
        today,
        adjustmentDays: hijriAdjustmentDays,
      ),
      upcomingEvents: List.unmodifiable(summaries),
      totalPlannedAmount: summaries.fold(
        0,
        (total, summary) => total + summary.targetAmount,
      ),
    );
  }
}
