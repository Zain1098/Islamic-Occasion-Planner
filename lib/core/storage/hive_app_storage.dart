import 'package:hive_ce_flutter/hive_flutter.dart';

class HiveAppStorage {
  HiveAppStorage._({
    required this.events,
    required this.budgetItems,
    required this.savingEntries,
    required this.reminderPreferences,
    required this.settings,
  });

  static const _storageName = 'islamic_occasion_planner';
  final Box<String> events;
  final Box<String> budgetItems;
  final Box<String> savingEntries;
  final Box<String> reminderPreferences;
  final Box<String> settings;

  static Future<HiveAppStorage> open() async {
    await Hive.initFlutter(_storageName);
    return HiveAppStorage._(
      events: await Hive.openBox<String>('events'),
      budgetItems: await Hive.openBox<String>('budget_items'),
      savingEntries: await Hive.openBox<String>('saving_entries'),
      reminderPreferences: await Hive.openBox<String>('reminder_preferences'),
      settings: await Hive.openBox<String>('settings'),
    );
  }

  /// Replaces data only after the caller has completely validated its backup.
  /// The previous maps are restored if one of the writes fails.
  Future<void> replaceAll({
    required Map<String, String> events,
    required Map<String, String> budgetItems,
    required Map<String, String> savingEntries,
    required Map<String, String> reminderPreferences,
    required Map<String, String> settings,
  }) async {
    final previous = <Box<String>, Map<dynamic, String>>{
      this.events: Map<dynamic, String>.from(this.events.toMap()),
      this.budgetItems: Map<dynamic, String>.from(this.budgetItems.toMap()),
      this.savingEntries: Map<dynamic, String>.from(this.savingEntries.toMap()),
      this.reminderPreferences: Map<dynamic, String>.from(
        this.reminderPreferences.toMap(),
      ),
      this.settings: Map<dynamic, String>.from(this.settings.toMap()),
    };
    try {
      await this.events.clear();
      await this.budgetItems.clear();
      await this.savingEntries.clear();
      await this.reminderPreferences.clear();
      await this.settings.clear();
      await this.events.putAll(events);
      await this.budgetItems.putAll(budgetItems);
      await this.savingEntries.putAll(savingEntries);
      await this.reminderPreferences.putAll(reminderPreferences);
      await this.settings.putAll(settings);
    } catch (_) {
      for (final entry in previous.entries) {
        await entry.key.clear();
        await entry.key.putAll(entry.value);
      }
      rethrow;
    }
  }
}
