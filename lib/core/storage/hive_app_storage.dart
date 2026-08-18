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
}
