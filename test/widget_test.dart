import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:islamic_occasion_planner/app/app.dart';
import 'package:islamic_occasion_planner/core/services/date_service.dart';
import 'package:islamic_occasion_planner/features/dashboard/domain/dashboard_data.dart';
import 'package:islamic_occasion_planner/features/dashboard/presentation/dashboard_provider.dart';
import 'package:islamic_occasion_planner/features/events/presentation/events_provider.dart';

void main() {
  testWidgets('app shell shows all primary destinations', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dashboardProvider.overrideWith(
            (ref) async => DashboardData(
              today: DateTime(2026, 8, 18),
              hijriToday: const HijriDate(year: 1448, month: 3, day: 5),
              upcomingEvents: const [],
              totalPlannedAmount: 0,
            ),
          ),
          eventsProvider.overrideWith((ref) async => const []),
        ],
        child: const IslamicOccasionPlannerApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Assalamu Alaikum'), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Calendar'), findsOneWidget);
    expect(find.text('Plans'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
    await tester.tap(find.text('Plans'));
    await tester.pumpAndSettle();
    expect(find.text('Occasion plans'), findsOneWidget);
  });
}
