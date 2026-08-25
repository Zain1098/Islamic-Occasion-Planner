import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../shared/models/app_settings.dart';
import '../../shared/models/budget_item.dart';
import '../../shared/models/islamic_event.dart';
import '../../shared/models/reminder_preference.dart';
import '../../shared/models/saving_entry.dart';
import '../storage/hive_app_storage.dart';

class BackupService {
  BackupService(this._storage);

  static const schemaVersion = 1;
  final HiveAppStorage _storage;

  Future<void> exportAndShare() async {
    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final file = File('${directory.path}/noor-backup-$timestamp.json');
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(_export()),
    );
    await SharePlus.instance.share(
      ShareParams(
        text: 'Noor Islamic Occasion Planner backup',
        files: [XFile(file.path)],
      ),
    );
  }

  Future<bool> importFromPicker() async {
    final pickedFile = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: const ['json'],
    );
    final path = pickedFile?.path;
    if (path == null) {
      return false;
    }
    await importJson(await File(path).readAsString());
    return true;
  }

  Future<void> importJson(String source) async {
    final decoded = jsonDecode(source);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('This is not a Noor backup file.');
    }
    if (decoded['schemaVersion'] != schemaVersion) {
      throw const FormatException('This backup version is not supported.');
    }
    final events = _maps(decoded['events'], 'events');
    final budgetItems = _maps(decoded['budgetItems'], 'budgetItems');
    final savingEntries = _maps(decoded['savingEntries'], 'savingEntries');
    final reminders = _maps(
      decoded['reminderPreferences'],
      'reminderPreferences',
    );
    final settings = decoded['settings'];
    if (settings is! Map<String, dynamic>) {
      throw const FormatException('Backup settings are invalid.');
    }

    // Validate every record before any current local data is changed.
    final parsedEvents = events.map(IslamicEvent.fromMap).toList();
    final parsedBudgets = budgetItems.map(BudgetItem.fromMap).toList();
    final parsedSavings = savingEntries.map(SavingEntry.fromMap).toList();
    final parsedReminders = reminders.map(ReminderPreference.fromMap).toList();
    final parsedSettings = AppSettings.fromMap(settings);
    final eventIds = parsedEvents.map((item) => item.id).toSet();
    if (parsedBudgets.any((item) => !eventIds.contains(item.eventId)) ||
        parsedSavings.any((item) => !eventIds.contains(item.eventId)) ||
        parsedReminders.any((item) => !eventIds.contains(item.eventId))) {
      throw const FormatException(
        'Backup contains data for an occasion that is missing.',
      );
    }

    await _storage.replaceAll(
      events: {
        for (final item in parsedEvents) item.id: jsonEncode(item.toMap()),
      },
      budgetItems: {
        for (final item in parsedBudgets) item.id: jsonEncode(item.toMap()),
      },
      savingEntries: {
        for (final item in parsedSavings) item.id: jsonEncode(item.toMap()),
      },
      reminderPreferences: {
        for (final item in parsedReminders)
          item.eventId: jsonEncode(item.toMap()),
      },
      settings: {'app_settings': jsonEncode(parsedSettings.toMap())},
    );
  }

  Map<String, Object?> _export() => {
    'schemaVersion': schemaVersion,
    'exportedAt': DateTime.now().toIso8601String(),
    'settings':
        _singleMap(_storage.settings.get('app_settings')) ??
        const AppSettings().toMap(),
    'events': _allMaps(_storage.events.values),
    'budgetItems': _allMaps(_storage.budgetItems.values),
    'savingEntries': _allMaps(_storage.savingEntries.values),
    'reminderPreferences': _allMaps(_storage.reminderPreferences.values),
  };
}

List<Map<String, dynamic>> _allMaps(Iterable<String> values) =>
    values.map(_decodeMap).toList(growable: false);

Map<String, dynamic>? _singleMap(String? value) =>
    value == null ? null : _decodeMap(value);

Map<String, dynamic> _decodeMap(String value) {
  final decoded = jsonDecode(value);
  if (decoded is! Map<String, dynamic>) {
    throw const FormatException('Invalid data.');
  }
  return decoded;
}

List<Map<String, dynamic>> _maps(Object? value, String name) {
  if (value is! List) throw FormatException('Backup $name are invalid.');
  return value
      .map((item) {
        if (item is! Map<String, dynamic>) {
          throw FormatException('A $name item is invalid.');
        }
        return item;
      })
      .toList(growable: false);
}
