import '../../../core/services/date_service.dart';
import '../../../shared/models/islamic_event.dart';

class CalendarDay {
  const CalendarDay({
    required this.date,
    required this.hijriDate,
    required this.events,
  });

  final DateTime date;
  final HijriDate hijriDate;
  final List<IslamicEvent> events;
}

class CalendarData {
  const CalendarData({required this.month, required this.days});

  final DateTime month;
  final List<CalendarDay> days;
}

class CalendarCalculator {
  CalendarCalculator(this._dateService);

  final DateService _dateService;

  CalendarData build({
    required DateTime month,
    required List<IslamicEvent> events,
    required int hijriAdjustmentDays,
  }) {
    final normalizedMonth = DateTime(month.year, month.month);
    final dayCount = DateTime(
      normalizedMonth.year,
      normalizedMonth.month + 1,
      0,
    ).day;
    final days = List.generate(dayCount, (index) {
      final date = DateTime(
        normalizedMonth.year,
        normalizedMonth.month,
        index + 1,
      );
      return CalendarDay(
        date: date,
        hijriDate: _dateService.hijriDateFor(
          date,
          adjustmentDays: hijriAdjustmentDays,
        ),
        events: List.unmodifiable(
          events.where(
            (event) =>
                event.enabled && _matches(event, date, hijriAdjustmentDays),
          ),
        ),
      );
    });
    return CalendarData(month: normalizedMonth, days: List.unmodifiable(days));
  }

  bool _matches(IslamicEvent event, DateTime date, int hijriAdjustmentDays) {
    final override = event.manuallyOverriddenDate;
    if (override != null) return _sameDate(override, date);
    if (event.dateType == EventDateType.gregorian) {
      final eventDate = event.gregorianDate!;
      return event.repeatsYearly
          ? eventDate.month == date.month && eventDate.day == date.day
          : _sameDate(eventDate, date);
    }
    final hijri = _dateService.hijriDateFor(
      date,
      adjustmentDays: hijriAdjustmentDays,
    );
    return hijri.month == event.hijriMonth && hijri.day == event.hijriDay;
  }

  bool _sameDate(DateTime first, DateTime second) =>
      first.year == second.year &&
      first.month == second.month &&
      first.day == second.day;
}
