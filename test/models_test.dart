import 'package:flutter_test/flutter_test.dart';
import 'package:islamic_occasion_planner/features/events/data/hive_event_repository.dart';
import 'package:islamic_occasion_planner/shared/models/app_settings.dart';
import 'package:islamic_occasion_planner/shared/models/islamic_event.dart';
import 'package:islamic_occasion_planner/shared/models/reminder_preference.dart';
import 'package:islamic_occasion_planner/shared/models/saving_entry.dart';

void main() {
  test('Islamic event serializes without losing a manual override', () {
    final event = IslamicEvent(
      id: 'eid',
      title: 'Eid al-Fitr',
      dateType: EventDateType.hijri,
      hijriMonth: 10,
      hijriDay: 1,
      manuallyOverriddenDate: DateTime(2027, 3, 10),
      repeatsYearly: true,
      enabled: true,
      createdAt: DateTime(2026, 8, 18),
      updatedAt: DateTime(2026, 8, 18),
    );

    final restored = IslamicEvent.fromMap(event.toMap());

    expect(restored.manuallyOverriddenDate, DateTime(2027, 3, 10));
    expect(restored.dateType, EventDateType.hijri);
  });

  test('default occasions are recurring Hijri events', () {
    final events = defaultIslamicOccasions(DateTime(2026, 8, 18));

    expect(events, hasLength(5));
    expect(
      events.every((event) => event.dateType == EventDateType.hijri),
      isTrue,
    );
    expect(events.every((event) => event.repeatsYearly), isTrue);
    expect(isDefaultIslamicOccasion(events.first), isTrue);
  });

  test('settings and saving entries serialize their enum values', () {
    final settings = AppSettings.fromMap(
      const AppSettings(themeMode: AppThemePreference.dark).toMap(),
    );
    final entry = SavingEntry.fromMap(
      SavingEntry(
        id: 'saving-1',
        eventId: 'eid',
        amount: 500,
        entryType: SavingEntryType.add,
        createdAt: DateTime(2026, 8, 18),
      ).toMap(),
    );

    expect(settings.themeMode, AppThemePreference.dark);
    expect(entry.entryType, SavingEntryType.add);
    expect(entry.amount, 500);
  });

  test('reminder preferences preserve all chosen offsets', () {
    final preference = ReminderPreference.fromMap(
      const ReminderPreference(
        eventId: 'eid',
        offsetsInDays: [30, 7, 1, 0],
        enabled: true,
      ).toMap(),
    );

    expect(preference.offsetsInDays, [30, 7, 1, 0]);
    expect(preference.enabled, isTrue);
  });
}
