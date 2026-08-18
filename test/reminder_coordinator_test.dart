import 'package:flutter_test/flutter_test.dart';
import 'package:islamic_occasion_planner/core/services/reminder_coordinator.dart';
import 'package:islamic_occasion_planner/shared/models/islamic_event.dart';

void main() {
  final event = IslamicEvent(
    id: 'eid-test',
    title: 'Eid al-Adha',
    dateType: EventDateType.gregorian,
    gregorianDate: DateTime(2027, 6, 7),
    repeatsYearly: false,
    enabled: true,
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
  );

  test('builds sorted future reminder schedules with remaining target', () {
    final schedules = buildReminderSchedules(
      event: event,
      eventDate: DateTime(2027, 6, 7),
      offsetsInDays: const [0, 7, 3],
      remainingAmount: 12500,
      now: DateTime(2027, 5, 1),
    );

    expect(schedules.map((item) => item.scheduledAt.day), [31, 4, 7]);
    expect(schedules.first.scheduledAt.hour, 9);
    expect(schedules.first.body, contains('Rs 12500 still to plan'));
  });

  test('does not schedule past reminders or unsupported offsets', () {
    final schedules = buildReminderSchedules(
      event: event,
      eventDate: DateTime(2027, 6, 7),
      offsetsInDays: const [31, 7, 0],
      remainingAmount: 0,
      now: DateTime(2027, 6, 1, 10),
    );

    expect(schedules, hasLength(1));
    expect(schedules.single.scheduledAt, DateTime(2027, 6, 7, 9));
  });

  test('notification identifiers are stable and offset-specific', () {
    expect(notificationIdFor('eid-test', 7), notificationIdFor('eid-test', 7));
    expect(
      notificationIdFor('eid-test', 7),
      isNot(notificationIdFor('eid-test', 3)),
    );
  });
}
