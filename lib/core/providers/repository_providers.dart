import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/budget/data/budget_repository.dart';
import '../../features/budget/data/hive_budget_repository.dart';
import '../../features/events/data/event_repository.dart';
import '../../features/events/data/hive_event_repository.dart';
import '../../features/reminders/data/hive_reminder_preference_repository.dart';
import '../../features/reminders/data/reminder_preference_repository.dart';
import '../../features/savings/data/hive_saving_repository.dart';
import '../../features/savings/data/saving_repository.dart';
import '../../features/settings/data/hive_settings_repository.dart';
import '../../features/settings/data/settings_repository.dart';
import '../storage/hive_app_storage.dart';
import '../services/date_service.dart';
import '../services/notification_service.dart';
import '../services/reminder_coordinator.dart';

final appStorageProvider = Provider<HiveAppStorage>(
  (ref) => throw UnimplementedError(),
);
final dateServiceProvider = Provider<DateService>((ref) => DateService());
final notificationServiceProvider = Provider<NotificationService>(
  (ref) => NotificationService(),
);
final eventRepositoryProvider = Provider<EventRepository>(
  (ref) => HiveEventRepository(ref.watch(appStorageProvider)),
);
final budgetRepositoryProvider = Provider<BudgetRepository>(
  (ref) => HiveBudgetRepository(ref.watch(appStorageProvider)),
);
final savingRepositoryProvider = Provider<SavingRepository>(
  (ref) => HiveSavingRepository(ref.watch(appStorageProvider)),
);
final reminderPreferenceRepositoryProvider =
    Provider<ReminderPreferenceRepository>(
      (ref) => HiveReminderPreferenceRepository(ref.watch(appStorageProvider)),
    );
final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => HiveSettingsRepository(ref.watch(appStorageProvider)),
);
final reminderCoordinatorProvider = Provider<ReminderCoordinator>(
  (ref) => ReminderCoordinator(
    events: ref.watch(eventRepositoryProvider),
    budgets: ref.watch(budgetRepositoryProvider),
    savings: ref.watch(savingRepositoryProvider),
    preferences: ref.watch(reminderPreferenceRepositoryProvider),
    settings: ref.watch(settingsRepositoryProvider),
    dates: ref.watch(dateServiceProvider),
    notifications: ref.watch(notificationServiceProvider),
  ),
);
