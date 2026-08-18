import 'package:hijri/hijri_calendar.dart';

import '../../shared/models/islamic_event.dart';

class HijriDate {
  const HijriDate({required this.year, required this.month, required this.day});

  final int year;
  final int month;
  final int day;
}

class DateService {
  DateService({DateTime Function()? clock}) : _clock = clock ?? DateTime.now;

  final DateTime Function() _clock;

  DateTime today() => dateOnly(_clock());

  DateTime dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

  HijriDate hijriDateFor(DateTime date, {int adjustmentDays = 0}) {
    _validateAdjustment(adjustmentDays);
    final adjustedDate = DateTime(
      date.year,
      date.month,
      date.day + adjustmentDays,
    );
    final calendar = HijriCalendar.fromDate(adjustedDate);
    return HijriDate(
      year: calendar.hYear,
      month: calendar.hMonth,
      day: calendar.hDay,
    );
  }

  DateTime resolveEventDate(
    IslamicEvent event, {
    DateTime? from,
    int hijriAdjustmentDays = 0,
  }) {
    _validateAdjustment(hijriAdjustmentDays);
    if (event.manuallyOverriddenDate != null) {
      return dateOnly(event.manuallyOverriddenDate!);
    }

    final fromDate = dateOnly(from ?? today());
    return switch (event.dateType) {
      EventDateType.gregorian => _resolveGregorianEvent(event, fromDate),
      EventDateType.hijri => _resolveHijriEvent(
        event,
        fromDate,
        hijriAdjustmentDays,
      ),
    };
  }

  int daysRemaining(
    IslamicEvent event, {
    DateTime? from,
    int hijriAdjustmentDays = 0,
  }) {
    final fromDate = dateOnly(from ?? today());
    final eventDate = resolveEventDate(
      event,
      from: fromDate,
      hijriAdjustmentDays: hijriAdjustmentDays,
    );
    return _utcDate(eventDate).difference(_utcDate(fromDate)).inDays;
  }

  bool isOverdue(
    IslamicEvent event, {
    DateTime? from,
    int hijriAdjustmentDays = 0,
  }) =>
      daysRemaining(
        event,
        from: from,
        hijriAdjustmentDays: hijriAdjustmentDays,
      ) <
      0;

  DateTime _resolveGregorianEvent(IslamicEvent event, DateTime from) {
    final original = event.gregorianDate!;
    if (!event.repeatsYearly) {
      return dateOnly(original);
    }

    var occurrence = _dateInYear(from.year, original.month, original.day);
    if (occurrence.isBefore(from)) {
      occurrence = _dateInYear(from.year + 1, original.month, original.day);
    }
    return occurrence;
  }

  DateTime _resolveHijriEvent(
    IslamicEvent event,
    DateTime from,
    int adjustmentDays,
  ) {
    final currentHijri = hijriDateFor(from, adjustmentDays: adjustmentDays);
    var occurrence = _hijriOccurrence(
      year: currentHijri.year,
      month: event.hijriMonth!,
      day: event.hijriDay!,
      adjustmentDays: adjustmentDays,
    );
    if (occurrence.isBefore(from) && event.repeatsYearly) {
      occurrence = _hijriOccurrence(
        year: currentHijri.year + 1,
        month: event.hijriMonth!,
        day: event.hijriDay!,
        adjustmentDays: adjustmentDays,
      );
    }
    return occurrence;
  }

  DateTime _hijriOccurrence({
    required int year,
    required int month,
    required int day,
    required int adjustmentDays,
  }) {
    final calendar = HijriCalendar();
    final validDay = day.clamp(1, calendar.getDaysInMonth(year, month));
    final calculatedDate = calendar.hijriToGregorian(year, month, validDay);
    return DateTime(
      calculatedDate.year,
      calculatedDate.month,
      calculatedDate.day - adjustmentDays,
    );
  }

  DateTime _dateInYear(int year, int month, int day) {
    final lastDay = DateTime(year, month + 1, 0).day;
    return DateTime(year, month, day.clamp(1, lastDay));
  }

  DateTime _utcDate(DateTime date) =>
      DateTime.utc(date.year, date.month, date.day);

  void _validateAdjustment(int adjustmentDays) {
    if (adjustmentDays < -1 || adjustmentDays > 1) {
      throw ArgumentError.value(
        adjustmentDays,
        'adjustmentDays',
        'Must be -1, 0, or 1.',
      );
    }
  }
}
