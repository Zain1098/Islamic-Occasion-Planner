import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../events/presentation/events_screen.dart';
import '../domain/calendar_data.dart';
import 'calendar_provider.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  late DateTime _month;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month);
    _selectedDate = DateTime(now.year, now.month, now.day);
  }

  void _changeMonth(int offset) {
    setState(() {
      _month = DateTime(_month.year, _month.month + offset);
      _selectedDate = DateTime(_month.year, _month.month, 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final calendar = ref.watch(calendarProvider(_month));
    return Scaffold(
      appBar: AppBar(title: const Text('Calendar')),
      body: calendar.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: TextButton(
            onPressed: () => ref.invalidate(calendarProvider(_month)),
            child: const Text('Try again'),
          ),
        ),
        data: (data) => _CalendarContent(
          data: data,
          selectedDate: _selectedDate,
          onPrevious: () => _changeMonth(-1),
          onNext: () => _changeMonth(1),
          onSelect: (date) => setState(() => _selectedDate = date),
        ),
      ),
    );
  }
}

class _CalendarContent extends StatelessWidget {
  const _CalendarContent({
    required this.data,
    required this.selectedDate,
    required this.onPrevious,
    required this.onNext,
    required this.onSelect,
  });

  final CalendarData data;
  final DateTime selectedDate;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final ValueChanged<DateTime> onSelect;

  @override
  Widget build(BuildContext context) {
    final selectedDay = data.days
        .where((day) => _sameDate(day.date, selectedDate))
        .firstOrNull;
    final leadingBlankDays = data.month.weekday % 7;
    final cells = <Widget>[
      for (var index = 0; index < leadingBlankDays; index++) const SizedBox(),
      ...data.days.map(
        (day) => _CalendarCell(
          day: day,
          selected: _sameDate(day.date, selectedDate),
          today: _sameDate(day.date, DateTime.now()),
          onTap: () => onSelect(day.date),
        ),
      ),
    ];
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        Row(
          children: [
            IconButton(
              onPressed: onPrevious,
              icon: const Icon(Icons.chevron_left),
            ),
            Expanded(
              child: Text(
                _monthLabel(data.month),
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            IconButton(
              onPressed: onNext,
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const _WeekdayHeader(),
        const SizedBox(height: 8),
        GridView.count(
          crossAxisCount: 7,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 0.72,
          children: cells,
        ),
        const SizedBox(height: 24),
        Text(
          selectedDay == null
              ? 'Select a date'
              : _selectedDateLabel(selectedDay),
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        if (selectedDay == null || selectedDay.events.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('No occasions on this date.'),
            ),
          )
        else
          ...selectedDay.events.map(
            (event) => Card(
              child: ListTile(
                title: Text(event.title),
                subtitle: const Text('Tap to view plan'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => EventDetailScreen(event: event),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _WeekdayHeader extends StatelessWidget {
  const _WeekdayHeader();
  @override
  Widget build(BuildContext context) => Row(
    children: [
      for (final label in ['S', 'M', 'T', 'W', 'T', 'F', 'S'])
        Expanded(child: Center(child: Text(label))),
    ],
  );
}

class _CalendarCell extends StatelessWidget {
  const _CalendarCell({
    required this.day,
    required this.selected,
    required this.today,
    required this.onTap,
  });

  final CalendarDay day;
  final bool selected;
  final bool today;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hasEvents = day.events.isNotEmpty;
    final background = selected
        ? scheme.primary
        : today
        ? scheme.primaryContainer
        : Colors.transparent;
    final foreground = selected ? scheme.onPrimary : scheme.onSurface;
    return Semantics(
      button: true,
      label:
          '${day.date.day}, Hijri ${day.hijriDate.day}, ${hasEvents ? '${day.events.length} occasion plans' : 'no occasions'}',
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.all(2),
          padding: const EdgeInsets.only(top: 6),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(12),
            border: today && !selected
                ? Border.all(color: scheme.primary)
                : null,
          ),
          child: Column(
            children: [
              Text(
                '${day.date.day}',
                style: TextStyle(
                  color: foreground,
                  fontWeight: hasEvents || today
                      ? FontWeight.w700
                      : FontWeight.w400,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${day.hijriDate.day}',
                style: TextStyle(
                  color: selected
                      ? scheme.onPrimary.withValues(alpha: 0.8)
                      : scheme.onSurfaceVariant,
                  fontSize: 11,
                ),
              ),
              const Spacer(),
              if (hasEvents)
                Container(
                  width: 6,
                  height: 6,
                  margin: const EdgeInsets.only(bottom: 6),
                  decoration: BoxDecoration(
                    color: selected ? scheme.onPrimary : scheme.secondary,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

String _monthLabel(DateTime month) {
  const names = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  return '${names[month.month - 1]} ${month.year}';
}

String _selectedDateLabel(CalendarDay day) =>
    '${day.date.day}/${day.date.month}/${day.date.year} · ${day.hijriDate.day}/${day.hijriDate.month}/${day.hijriDate.year} AH';

bool _sameDate(DateTime first, DateTime second) =>
    first.year == second.year &&
    first.month == second.month &&
    first.day == second.day;
