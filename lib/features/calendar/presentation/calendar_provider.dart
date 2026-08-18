import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/repository_providers.dart';
import '../domain/calendar_data.dart';

final calendarProvider = FutureProvider.family<CalendarData, DateTime>((
  ref,
  month,
) async {
  final events = await ref.watch(eventRepositoryProvider).getAll();
  final settings = await ref.watch(settingsRepositoryProvider).get();
  return CalendarCalculator(ref.watch(dateServiceProvider)).build(
    month: month,
    events: events,
    hijriAdjustmentDays: settings.hijriAdjustmentDays,
  );
});
