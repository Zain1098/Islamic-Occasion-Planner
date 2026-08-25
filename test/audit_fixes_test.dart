import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:islamic_occasion_planner/core/providers/planner_data_refresh.dart';
import 'package:islamic_occasion_planner/core/services/date_service.dart';
import 'package:islamic_occasion_planner/core/utils/currency_formatter.dart';
import 'package:islamic_occasion_planner/features/dashboard/domain/dashboard_data.dart';
import 'package:islamic_occasion_planner/shared/models/islamic_event.dart';

void main() {
  group('Audit Fixes & PRD Gaps Unit Tests', () {
    test('formatCurrency formats amounts correctly per currency code', () {
      expect(formatCurrency(5000, 'PKR'), 'Rs 5,000');
      expect(formatCurrency(1250, 'USD'), '\$ 1,250');
      expect(formatCurrency(300, 'EUR'), '€ 300');
      expect(formatCurrency(0, 'PKR'), 'Rs 0');
      expect(formatCurrency(1000000, 'SAR'), 'SR 1,000,000');
    });

    test('DashboardEventSummary calculates dailySavingRequired correctly', () {
      final event = IslamicEvent(
        id: 'test_event',
        title: 'Ramadan',
        dateType: EventDateType.hijri,
        hijriMonth: 9,
        hijriDay: 1,
        repeatsYearly: true,
        enabled: true,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      final summary = DashboardEventSummary(
        event: event,
        date: DateTime(2026, 3, 1),
        daysRemaining: 10,
        targetAmount: 20000,
        savedAmount: 5000,
      );

      expect(summary.remainingAmount, 15000);
      expect(summary.dailySavingRequired, 1500); // 15000 / 10
    });

    test('DashboardData calculates monthlyAmountNeeded correctly', () {
      final data = DashboardData(
        today: DateTime(2026, 1, 1),
        hijriToday: const HijriDate(year: 1447, month: 7, day: 15),
        upcomingEvents: const [],
        totalPlannedAmount: 60000,
      );

      expect(data.monthlyAmountNeeded, 5000); // 60000 / 12
    });

    test('refreshPlannerData executes without error', () {
      final container = ProviderContainer();
      expect(() => refreshPlannerData(container), returnsNormally);
    });
  });
}
