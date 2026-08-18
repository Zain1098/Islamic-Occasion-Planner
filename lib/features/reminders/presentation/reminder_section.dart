import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/repository_providers.dart';
import '../../../core/services/reminder_coordinator.dart';
import '../../../shared/models/islamic_event.dart';
import '../../../shared/models/reminder_preference.dart';

final reminderPreferenceProvider =
    FutureProvider.family<ReminderPreference?, String>(
      (ref, eventId) =>
          ref.watch(reminderPreferenceRepositoryProvider).getForEvent(eventId),
    );

class ReminderSection extends ConsumerWidget {
  const ReminderSection({super.key, required this.event});

  final IslamicEvent event;

  @override
  Widget build(BuildContext context, WidgetRef ref) => ref
      .watch(reminderPreferenceProvider(event.id))
      .when(
        loading: () => const Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (error, stackTrace) => TextButton(
          onPressed: () => ref.invalidate(reminderPreferenceProvider(event.id)),
          child: const Text('Could not load reminders. Try again'),
        ),
        data: (preference) {
          final enabled = preference?.enabled ?? false;
          final selected = preference?.offsetsInDays.toSet() ?? {7, 1, 0};
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Occasion reminders'),
                    subtitle: const Text(
                      'A gentle planning reminder at 9:00 AM.',
                    ),
                    value: enabled,
                    onChanged: (value) => _save(context, ref, value, selected),
                  ),
                  if (enabled) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Remind me',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: reminderOffsets
                          .map(
                            (offset) => FilterChip(
                              label: Text(
                                offset == 0
                                    ? 'On the day'
                                    : '$offset days before',
                              ),
                              selected: selected.contains(offset),
                              onSelected: (value) {
                                final next = {...selected};
                                if (value) {
                                  next.add(offset);
                                } else if (next.length > 1) {
                                  next.remove(offset);
                                }
                                _save(context, ref, true, next);
                              },
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      );

  Future<void> _save(
    BuildContext context,
    WidgetRef ref,
    bool enabled,
    Set<int> offsets,
  ) async {
    if (enabled) {
      final granted = await ref
          .read(notificationServiceProvider)
          .requestPermission();
      if (!granted) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Allow notifications in Android settings to receive reminders.',
              ),
            ),
          );
        }
        return;
      }
      final settings = await ref.read(settingsRepositoryProvider).get();
      if (!settings.notificationsEnabled) {
        await ref
            .read(settingsRepositoryProvider)
            .save(settings.copyWith(notificationsEnabled: true));
      }
    }
    await ref
        .read(reminderPreferenceRepositoryProvider)
        .save(
          ReminderPreference(
            eventId: event.id,
            enabled: enabled,
            offsetsInDays: offsets.toList()..sort(),
          ),
        );
    await ref.read(reminderCoordinatorProvider).rescheduleEvent(event);
    ref.invalidate(reminderPreferenceProvider(event.id));
  }
}
