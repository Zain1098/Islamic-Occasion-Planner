import 'package:flutter_test/flutter_test.dart';
import 'package:islamic_occasion_planner/core/services/date_service.dart';
import 'package:islamic_occasion_planner/features/dashboard/domain/dashboard_data.dart';
import 'package:islamic_occasion_planner/shared/models/budget_item.dart';
import 'package:islamic_occasion_planner/shared/models/islamic_event.dart';
import 'package:islamic_occasion_planner/shared/models/saving_entry.dart';

void main() {
  test('dashboard sorts upcoming events and calculates planning totals', () {
    final timestamp = DateTime(2026, 1, 1);
    final calculator = DashboardCalculator(DateService());
    final earlyEvent = _event('early', DateTime(2020, 2, 1), timestamp);
    final lateEvent = _event('late', DateTime(2020, 3, 1), timestamp);

    final dashboard = calculator.build(
      events: [lateEvent, earlyEvent],
      budgetItems: const [
        BudgetItem(
          id: 'budget-1',
          eventId: 'early',
          category: 'Niaz',
          plannedAmount: 10000,
        ),
        BudgetItem(
          id: 'budget-2',
          eventId: 'late',
          category: 'Transport',
          plannedAmount: 4000,
        ),
      ],
      savingEntries: [
        SavingEntry(
          id: 'saving-1',
          eventId: 'early',
          amount: 2500,
          entryType: SavingEntryType.add,
          createdAt: timestamp,
        ),
        SavingEntry(
          id: 'saving-2',
          eventId: 'early',
          amount: 500,
          entryType: SavingEntryType.subtract,
          createdAt: timestamp,
        ),
      ],
      hijriAdjustmentDays: 0,
      now: DateTime(2026, 1, 1),
    );

    expect(dashboard.nextEvent?.event.id, 'early');
    expect(dashboard.nextEvent?.targetAmount, 10000);
    expect(dashboard.nextEvent?.savedAmount, 2000);
    expect(dashboard.totalPlannedAmount, 14000);
  });
}

IslamicEvent _event(String id, DateTime date, DateTime timestamp) =>
    IslamicEvent(
      id: id,
      title: id,
      dateType: EventDateType.gregorian,
      gregorianDate: date,
      repeatsYearly: true,
      enabled: true,
      createdAt: timestamp,
      updatedAt: timestamp,
    );
