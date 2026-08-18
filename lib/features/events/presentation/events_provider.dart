import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/repository_providers.dart';
import '../../../shared/models/islamic_event.dart';

final eventsProvider = FutureProvider<List<IslamicEvent>>((ref) async {
  final events = await ref.watch(eventRepositoryProvider).getAll();
  final settings = await ref.watch(settingsRepositoryProvider).get();
  final dateService = ref.watch(dateServiceProvider);
  final today = dateService.today();
  events.sort((first, second) {
    final firstDate = dateService.resolveEventDate(
      first,
      from: today,
      hijriAdjustmentDays: settings.hijriAdjustmentDays,
    );
    final secondDate = dateService.resolveEventDate(
      second,
      from: today,
      hijriAdjustmentDays: settings.hijriAdjustmentDays,
    );
    return firstDate.compareTo(secondDate);
  });
  return events;
});
