import 'package:flutter_test/flutter_test.dart';
import 'package:islamic_occasion_planner/core/services/date_service.dart';
import 'package:islamic_occasion_planner/features/calendar/domain/calendar_data.dart';
import 'package:islamic_occasion_planner/shared/models/islamic_event.dart';

final timestamp = DateTime(2026, 1, 1);

void main() {
  final calculator = CalendarCalculator(DateService());

  test('monthly calendar highlights annual and one-time Gregorian events', () {
    final annual = _gregorianEvent('annual', DateTime(2020, 5, 10), true);
    final oneTime = _gregorianEvent('one-time', DateTime(2026, 5, 11), false);

    final calendar = calculator.build(
      month: DateTime(2026, 5),
      events: [annual, oneTime],
      hijriAdjustmentDays: 0,
    );

    expect(calendar.days, hasLength(31));
    expect(calendar.days[9].events.single.id, 'annual');
    expect(calendar.days[10].events.single.id, 'one-time');
  });

  test('manual override takes precedence over an event Hijri date', () {
    final event = IslamicEvent(
      id: 'override',
      title: 'Override',
      dateType: EventDateType.hijri,
      hijriMonth: 9,
      hijriDay: 1,
      manuallyOverriddenDate: DateTime(2026, 5, 20),
      repeatsYearly: true,
      enabled: true,
      createdAt: timestamp,
      updatedAt: timestamp,
    );

    final calendar = calculator.build(
      month: DateTime(2026, 5),
      events: [event],
      hijriAdjustmentDays: 0,
    );

    expect(calendar.days[19].events.single.id, 'override');
  });
}

IslamicEvent _gregorianEvent(String id, DateTime date, bool repeatsYearly) =>
    IslamicEvent(
      id: id,
      title: id,
      dateType: EventDateType.gregorian,
      gregorianDate: date,
      repeatsYearly: repeatsYearly,
      enabled: true,
      createdAt: timestamp,
      updatedAt: timestamp,
    );
