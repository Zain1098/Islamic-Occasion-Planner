// ignore_for_file: prefer_initializing_formals

import '../../features/budget/data/budget_repository.dart';
import '../../features/events/data/event_repository.dart';
import '../../features/reminders/data/reminder_preference_repository.dart';
import '../../features/savings/data/saving_repository.dart';
import '../../features/settings/data/settings_repository.dart';
import '../../shared/models/islamic_event.dart';
import '../../shared/models/saving_entry.dart';
import 'date_service.dart';
import 'notification_service.dart';

const reminderOffsets = <int>[30, 15, 7, 3, 1, 0];

class ReminderCoordinator {
  ReminderCoordinator({
    required EventRepository events,
    required BudgetRepository budgets,
    required SavingRepository savings,
    required ReminderPreferenceRepository preferences,
    required SettingsRepository settings,
    required DateService dates,
    required NotificationService notifications,
  }) : _events = events,
       _budgets = budgets,
       _savings = savings,
       _preferences = preferences,
       _settings = settings,
       _dates = dates,
       _notifications = notifications;

  final EventRepository _events;
  final BudgetRepository _budgets;
  final SavingRepository _savings;
  final ReminderPreferenceRepository _preferences;
  final SettingsRepository _settings;
  final DateService _dates;
  final NotificationService _notifications;

  Future<void> rescheduleEvent(IslamicEvent event) async {
    await cancelEvent(event.id);
    final preference = await _preferences.getForEvent(event.id);
    final settings = await _settings.get();
    if (!event.enabled ||
        !settings.notificationsEnabled ||
        preference == null ||
        !preference.enabled) {
      return;
    }

    final eventDate = _dates.resolveEventDate(
      event,
      hijriAdjustmentDays: settings.hijriAdjustmentDays,
    );
    final remaining = await _remainingAmount(event.id);
    for (final reminder in buildReminderSchedules(
      event: event,
      eventDate: eventDate,
      offsetsInDays: preference.offsetsInDays,
      reminderTimeMinutes: preference.reminderTimeMinutes,
      remainingAmount: remaining,
    )) {
      await _notifications.schedule(
        id: reminder.id,
        title: reminder.title,
        body: reminder.body,
        scheduledAt: reminder.scheduledAt,
        eventId: event.id,
      );
    }
  }

  Future<void> rescheduleByEventId(String eventId) async {
    final event = await _events.getById(eventId);
    if (event != null) {
      await rescheduleEvent(event);
    }
  }

  Future<void> rescheduleAll() async {
    for (final event in await _events.getAll()) {
      await rescheduleEvent(event);
    }
  }

  Future<void> cancelEvent(String eventId) async {
    for (final offset in reminderOffsets) {
      await _notifications.cancel(notificationIdFor(eventId, offset));
    }
  }

  Future<int> _remainingAmount(String eventId) async {
    final budgetItems = await _budgets.getForEvent(eventId);
    final entries = await _savings.getForEvent(eventId);
    final target = budgetItems.fold(0, (sum, item) => sum + item.plannedAmount);
    final saved = entries.fold(
      0,
      (sum, item) =>
          sum +
          (item.entryType == SavingEntryType.add ? item.amount : -item.amount),
    );
    return (target - saved).clamp(0, target);
  }
}

class ReminderSchedule {
  const ReminderSchedule({
    required this.id,
    required this.scheduledAt,
    required this.title,
    required this.body,
  });

  final int id;
  final DateTime scheduledAt;
  final String title;
  final String body;
}

List<ReminderSchedule> buildReminderSchedules({
  required IslamicEvent event,
  required DateTime eventDate,
  required List<int> offsetsInDays,
  required int remainingAmount,
  int reminderTimeMinutes = 540,
  DateTime? now,
}) {
  final current = now ?? DateTime.now();
  return offsetsInDays
      .where((offset) => reminderOffsets.contains(offset))
      .toSet()
      .map((offset) {
        final day = eventDate.subtract(Duration(days: offset));
        final scheduledAt = DateTime(day.year, day.month, day.day, reminderTimeMinutes ~/ 60, reminderTimeMinutes % 60);
        final lead = offset == 0
            ? 'today'
            : 'in $offset day${offset == 1 ? '' : 's'}';
        final money = remainingAmount > 0
            ? ' Rs $remainingAmount still to plan.'
            : '';
        return ReminderSchedule(
          id: notificationIdFor(event.id, offset),
          scheduledAt: scheduledAt,
          title: '${event.title} is $lead',
          body: 'Take a moment to review your occasion plan.$money',
        );
      })
      .where((schedule) => schedule.scheduledAt.isAfter(current))
      .toList()
    ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
}

int notificationIdFor(String eventId, int offsetInDays) {
  var hash = 2166136261;
  for (final code in '$eventId:$offsetInDays'.codeUnits) {
    hash = (hash ^ code) * 16777619;
  }
  return hash & 0x3fffffff;
}
