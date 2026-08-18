import 'package:flutter_test/flutter_test.dart';
import 'package:islamic_occasion_planner/core/services/date_service.dart';
import 'package:islamic_occasion_planner/shared/models/islamic_event.dart';

void main() {
  final service = DateService();
  final timestamp = DateTime(2026, 8, 18);

  IslamicEvent hijriEvent({
    required int month,
    required int day,
    bool repeatsYearly = true,
  }) => IslamicEvent(
    id: 'hijri-event',
    title: 'Hijri event',
    dateType: EventDateType.hijri,
    hijriMonth: month,
    hijriDay: day,
    repeatsYearly: repeatsYearly,
    enabled: true,
    createdAt: timestamp,
    updatedAt: timestamp,
  );

  test('Hijri adjustment is applied to the device-local date', () {
    final date = DateTime(2026, 8, 18);
    final expected = service.hijriDateFor(DateTime(2026, 8, 19));

    final adjusted = service.hijriDateFor(date, adjustmentDays: 1);

    expect(
      (adjusted.year, adjusted.month, adjusted.day),
      (expected.year, expected.month, expected.day),
    );
  });

  test('a passed yearly Hijri event resolves in the next Hijri year', () {
    final from = DateTime(2026, 8, 18);
    final current = service.hijriDateFor(from);
    final passedMonth = current.day == 1
        ? (current.month == 1 ? 12 : current.month - 1)
        : current.month;
    final passedDay = current.day == 1 ? 1 : current.day - 1;
    final passed = hijriEvent(month: passedMonth, day: passedDay);

    final nextDate = service.resolveEventDate(passed, from: from);
    final nextHijri = service.hijriDateFor(nextDate);

    expect(nextDate.isAfter(from), isTrue);
    expect(nextHijri.year, current.year + 1);
  });

  test('manual override wins over the calculated recurring date', () {
    final event = hijriEvent(
      month: 10,
      day: 1,
    ).copyWithOverride(DateTime(2026, 9, 1));

    expect(
      service.resolveEventDate(event, from: timestamp),
      DateTime(2026, 9, 1),
    );
  });

  test('Gregorian annual recurrence handles leap-day events', () {
    final event = IslamicEvent(
      id: 'leap-day',
      title: 'Leap day',
      dateType: EventDateType.gregorian,
      gregorianDate: DateTime(2024, 2, 29),
      repeatsYearly: true,
      enabled: true,
      createdAt: timestamp,
      updatedAt: timestamp,
    );

    expect(
      service.resolveEventDate(event, from: DateTime(2025, 1, 1)),
      DateTime(2025, 2, 28),
    );
  });

  test('days remaining stays correct across a Gregorian year boundary', () {
    final event = IslamicEvent(
      id: 'new-year',
      title: 'New year',
      dateType: EventDateType.gregorian,
      gregorianDate: DateTime(2020, 1, 2),
      repeatsYearly: false,
      enabled: true,
      createdAt: timestamp,
      updatedAt: timestamp,
    );

    expect(service.daysRemaining(event, from: DateTime(2019, 12, 31)), 2);
  });
}

extension on IslamicEvent {
  IslamicEvent copyWithOverride(DateTime date) => IslamicEvent(
    id: id,
    title: title,
    notes: notes,
    dateType: dateType,
    hijriMonth: hijriMonth,
    hijriDay: hijriDay,
    gregorianDate: gregorianDate,
    manuallyOverriddenDate: date,
    repeatsYearly: repeatsYearly,
    enabled: enabled,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );
}
