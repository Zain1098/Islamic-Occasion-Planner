
import '../../features/budget/presentation/event_plan_provider.dart';
import '../../features/calendar/presentation/calendar_provider.dart';
import '../../features/dashboard/presentation/dashboard_provider.dart';
import '../../features/events/presentation/events_provider.dart';
import 'repository_providers.dart';

/// Invalidates every view derived from locally persisted planner data.
///
/// This keeps backup restore and event changes immediately visible without
/// requiring an app restart.
void refreshPlannerData(dynamic ref) {
  ref.invalidate(appSettingsProvider);
  ref.invalidate(dashboardProvider);
  ref.invalidate(eventsProvider);
  ref.invalidate(calendarProvider);
  ref.invalidate(eventPlanProvider);
}
