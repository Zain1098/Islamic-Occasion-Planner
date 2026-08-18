import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/repository_providers.dart';
import '../domain/dashboard_data.dart';

final dashboardProvider = FutureProvider<DashboardData>((ref) async {
  final settings = await ref.watch(settingsRepositoryProvider).get();
  final events = await ref.watch(eventRepositoryProvider).getAll();
  final budgetItems = await ref.watch(budgetRepositoryProvider).getAll();
  final savingEntries = await ref.watch(savingRepositoryProvider).getAll();
  return DashboardCalculator(ref.watch(dateServiceProvider)).build(
    events: events,
    budgetItems: budgetItems,
    savingEntries: savingEntries,
    hijriAdjustmentDays: settings.hijriAdjustmentDays,
  );
});
