import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/repository_providers.dart';
import '../../../core/utils/identifier_generator.dart';
import '../../budget/presentation/event_finance_section.dart';
import '../../reminders/presentation/reminder_section.dart';
import '../../../shared/models/islamic_event.dart';
import '../../../shared/widgets/app_state_view.dart';
import '../data/hive_event_repository.dart';
import 'events_provider.dart';

enum _PlanFilter { all, ramadanEid, custom, disabled }

class EventsScreen extends ConsumerStatefulWidget {
  const EventsScreen({super.key});

  @override
  ConsumerState<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends ConsumerState<EventsScreen> {
  final _searchController = TextEditingController();
  _PlanFilter _filter = _PlanFilter.all;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final events = ref.watch(eventsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Occasion plans')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Add occasion'),
      ),
      body: events.when(
        loading: () => const AppLoadingView(label: 'Loading occasion plans'),
        error: (error, stackTrace) => AppErrorView(
          message: 'Occasion plans could not be loaded.',
          onRetry: () => ref.invalidate(eventsProvider),
        ),
        data: (items) {
          final filtered = _filtered(items);
          return items.isEmpty
              ? const Center(
                  child: Text('Add an occasion you want to prepare for.'),
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                  children: [
                    TextField(
                      controller: _searchController,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.search),
                        hintText: 'Search occasion plans',
                        suffixIcon: _searchController.text.isEmpty
                            ? null
                            : IconButton(
                                tooltip: 'Clear search',
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {});
                                },
                              ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          for (final filter in _PlanFilter.values) ...[
                            ChoiceChip(
                              label: Text(_filterLabel(filter)),
                              selected: _filter == filter,
                              onSelected: (_) =>
                                  setState(() => _filter = filter),
                            ),
                            const SizedBox(width: 8),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    if (filtered.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(
                          child: Text('No plans match this filter.'),
                        ),
                      )
                    else
                      ...filtered.map(
                        (event) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _EventTile(event: event),
                        ),
                      ),
                  ],
                );
        },
      ),
    );
  }

  Future<void> _openEditor(BuildContext context, WidgetRef ref) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (context) => const EventEditorScreen()),
    );
    if (saved == true) ref.invalidate(eventsProvider);
  }

  List<IslamicEvent> _filtered(List<IslamicEvent> events) {
    final query = _searchController.text.trim().toLowerCase();
    return events
        .where((event) {
          final title = event.title.toLowerCase();
          final isRamadanEid =
              title.contains('ramadan') || title.contains('eid');
          final matchesFilter = switch (_filter) {
            _PlanFilter.all => true,
            _PlanFilter.ramadanEid => isRamadanEid,
            _PlanFilter.custom => !isDefaultIslamicOccasion(event),
            _PlanFilter.disabled => !event.enabled,
          };
          return matchesFilter &&
              (query.isEmpty ||
                  title.contains(query) ||
                  (event.notes?.toLowerCase().contains(query) ?? false));
        })
        .toList(growable: false);
  }
}

String _filterLabel(_PlanFilter filter) => switch (filter) {
  _PlanFilter.all => 'Upcoming',
  _PlanFilter.ramadanEid => 'Ramadan & Eid',
  _PlanFilter.custom => 'Custom',
  _PlanFilter.disabled => 'Disabled',
};

class _EventTile extends ConsumerWidget {
  const _EventTile({required this.event});

  final IslamicEvent event;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: ListTile(
        enabled: event.enabled,
        leading: CircleAvatar(
          child: Icon(event.enabled ? Icons.event : Icons.event_busy_outlined),
        ),
        title: Text(event.title),
        subtitle: Text(
          '${_eventDateLabel(event)}${event.repeatsYearly ? ' · Yearly' : ''}',
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () async {
          final changed = await Navigator.of(context).push<bool>(
            MaterialPageRoute(
              builder: (context) => EventDetailScreen(event: event),
            ),
          );
          if (changed == true) ref.invalidate(eventsProvider);
        },
      ),
    );
  }
}

class EventDetailScreen extends ConsumerWidget {
  const EventDetailScreen({super.key, required this.event});

  final IslamicEvent event;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDefault = isDefaultIslamicOccasion(event);
    return Scaffold(
      appBar: AppBar(
        title: Text(event.title),
        actions: [
          IconButton(
            tooltip: event.enabled ? 'Disable occasion' : 'Enable occasion',
            onPressed: () => _toggleEnabled(context, ref),
            icon: Icon(
              event.enabled
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
            ),
          ),
          if (!isDefault)
            IconButton(
              tooltip: 'Delete occasion',
              onPressed: () => _delete(context, ref),
              icon: const Icon(Icons.delete_outline),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            _eventDateLabel(event),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(event.repeatsYearly ? 'Repeats yearly' : 'One-time occasion'),
          if (event.manuallyOverriddenDate != null) ...[
            const SizedBox(height: 8),
            Text(
              'Manual date: ${event.manuallyOverriddenDate!.day}/${event.manuallyOverriddenDate!.month}/${event.manuallyOverriddenDate!.year}',
            ),
          ],
          if (event.notes case final notes?) ...[
            const SizedBox(height: 24),
            Text('Notes', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(notes),
          ],
          const SizedBox(height: 28),
          EventFinanceSection(eventId: event.id),
          const SizedBox(height: 24),
          ReminderSection(event: event),
          const SizedBox(height: 32),
          FilledButton.icon(
            onPressed: () => _edit(context, ref),
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Edit occasion'),
          ),
        ],
      ),
    );
  }

  Future<void> _edit(BuildContext context, WidgetRef ref) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (context) => EventEditorScreen(event: event)),
    );
    if (saved == true && context.mounted) Navigator.of(context).pop(true);
  }

  Future<void> _toggleEnabled(BuildContext context, WidgetRef ref) async {
    final now = DateTime.now();
    await ref
        .read(eventRepositoryProvider)
        .save(_copyEvent(event, enabled: !event.enabled, updatedAt: now));
    await ref.read(reminderCoordinatorProvider).rescheduleByEventId(event.id);
    if (context.mounted) Navigator.of(context).pop(true);
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this occasion?'),
        content: const Text(
          'Its budget items and saving history will also be removed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(reminderCoordinatorProvider).cancelEvent(event.id);
    await ref.read(budgetRepositoryProvider).deleteForEvent(event.id);
    await ref.read(savingRepositoryProvider).deleteForEvent(event.id);
    await ref.read(reminderPreferenceRepositoryProvider).delete(event.id);
    await ref.read(eventRepositoryProvider).delete(event.id);
    if (context.mounted) Navigator.of(context).pop(true);
  }
}

class EventEditorScreen extends ConsumerStatefulWidget {
  const EventEditorScreen({super.key, this.event});

  final IslamicEvent? event;

  @override
  ConsumerState<EventEditorScreen> createState() => _EventEditorScreenState();
}

class _EventEditorScreenState extends ConsumerState<EventEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _idGenerator = IdentifierGenerator();
  late final TextEditingController _titleController;
  late final TextEditingController _notesController;
  late EventDateType _dateType;
  late bool _repeatsYearly;
  late int _hijriMonth;
  late int _hijriDay;
  DateTime? _gregorianDate;
  DateTime? _manualDate;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final event = widget.event;
    _titleController = TextEditingController(text: event?.title ?? '');
    _notesController = TextEditingController(text: event?.notes ?? '');
    _dateType = event?.dateType ?? EventDateType.hijri;
    _repeatsYearly = event?.repeatsYearly ?? true;
    _hijriMonth = event?.hijriMonth ?? 9;
    _hijriDay = event?.hijriDay ?? 1;
    _gregorianDate = event?.gregorianDate;
    _manualDate = event?.manuallyOverriddenDate;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.event == null ? 'Add occasion' : 'Edit occasion'),
    ),
    body: Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TextFormField(
            controller: _titleController,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Occasion title'),
            validator: (value) =>
                value == null || value.trim().isEmpty ? 'Enter a title' : null,
          ),
          const SizedBox(height: 20),
          SegmentedButton<EventDateType>(
            segments: const [
              ButtonSegment(value: EventDateType.hijri, label: Text('Hijri')),
              ButtonSegment(
                value: EventDateType.gregorian,
                label: Text('Gregorian'),
              ),
            ],
            selected: {_dateType},
            onSelectionChanged: (value) =>
                setState(() => _dateType = value.first),
          ),
          const SizedBox(height: 20),
          if (_dateType == EventDateType.hijri) ...[
            DropdownButtonFormField<int>(
              initialValue: _hijriMonth,
              decoration: const InputDecoration(labelText: 'Hijri month'),
              items: List.generate(
                12,
                (index) => DropdownMenuItem(
                  value: index + 1,
                  child: Text(_hijriMonths[index]),
                ),
              ),
              onChanged: (value) => setState(() => _hijriMonth = value!),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              initialValue: _hijriDay,
              decoration: const InputDecoration(labelText: 'Hijri day'),
              items: List.generate(
                30,
                (index) => DropdownMenuItem(
                  value: index + 1,
                  child: Text('${index + 1}'),
                ),
              ),
              onChanged: (value) => setState(() => _hijriDay = value!),
            ),
          ] else
            _DateField(
              label: 'Gregorian date',
              date: _gregorianDate,
              onPick: (date) => setState(() => _gregorianDate = date),
            ),
          const SizedBox(height: 12),
          SwitchListTile(
            value: _repeatsYearly,
            onChanged: (value) => setState(() => _repeatsYearly = value),
            title: const Text('Repeat yearly'),
          ),
          const SizedBox(height: 12),
          _DateField(
            label: 'Manual date override (optional)',
            date: _manualDate,
            onPick: (date) => setState(() => _manualDate = date),
            onClear: _manualDate == null
                ? null
                : () => setState(() => _manualDate = null),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _notesController,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Notes (optional)',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 28),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: Text(_saving ? 'Saving…' : 'Save occasion'),
          ),
        ],
      ),
    ),
  );

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_dateType == EventDateType.gregorian && _gregorianDate == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Choose a Gregorian date.')));
      return;
    }
    setState(() => _saving = true);
    final now = DateTime.now();
    final existing = widget.event;
    final event = IslamicEvent(
      id: existing?.id ?? _idGenerator.next('event'),
      title: _titleController.text.trim(),
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      dateType: _dateType,
      hijriMonth: _dateType == EventDateType.hijri ? _hijriMonth : null,
      hijriDay: _dateType == EventDateType.hijri ? _hijriDay : null,
      gregorianDate: _dateType == EventDateType.gregorian
          ? _gregorianDate
          : null,
      manuallyOverriddenDate: _manualDate,
      repeatsYearly: _repeatsYearly,
      enabled: existing?.enabled ?? true,
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
    );
    await ref.read(eventRepositoryProvider).save(event);
    await ref.read(reminderCoordinatorProvider).rescheduleEvent(event);
    if (mounted) Navigator.of(context).pop(true);
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.date,
    required this.onPick,
    this.onClear,
  });

  final String label;
  final DateTime? date;
  final ValueChanged<DateTime> onPick;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    title: Text(label),
    subtitle: Text(
      date == null
          ? 'Not selected'
          : '${date!.day}/${date!.month}/${date!.year}',
    ),
    trailing: Wrap(
      spacing: 4,
      children: [
        if (onClear != null)
          IconButton(onPressed: onClear, icon: const Icon(Icons.clear)),
        IconButton(
          onPressed: () async {
            final result = await showDatePicker(
              context: context,
              initialDate: date ?? DateTime.now(),
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
            );
            if (result != null) onPick(result);
          },
          icon: const Icon(Icons.calendar_today_outlined),
        ),
      ],
    ),
  );
}

IslamicEvent _copyEvent(
  IslamicEvent event, {
  required bool enabled,
  required DateTime updatedAt,
}) => IslamicEvent(
  id: event.id,
  title: event.title,
  notes: event.notes,
  dateType: event.dateType,
  hijriMonth: event.hijriMonth,
  hijriDay: event.hijriDay,
  gregorianDate: event.gregorianDate,
  manuallyOverriddenDate: event.manuallyOverriddenDate,
  repeatsYearly: event.repeatsYearly,
  enabled: enabled,
  createdAt: event.createdAt,
  updatedAt: updatedAt,
);

String _eventDateLabel(IslamicEvent event) =>
    event.dateType == EventDateType.hijri
    ? '${event.hijriDay} ${_hijriMonths[event.hijriMonth! - 1]}'
    : '${event.gregorianDate!.day}/${event.gregorianDate!.month}/${event.gregorianDate!.year}';

const _hijriMonths = [
  'Muharram',
  'Safar',
  'Rabi al-Awwal',
  'Rabi al-Thani',
  'Jumada al-Awwal',
  'Jumada al-Thani',
  'Rajab',
  'Shaban',
  'Ramadan',
  'Shawwal',
  'Dhu al-Qadah',
  'Dhu al-Hijjah',
];
