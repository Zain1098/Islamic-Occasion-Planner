import 'dart:convert';

import '../../../core/storage/hive_app_storage.dart';
import '../../../shared/models/islamic_event.dart';
import 'event_repository.dart';

class HiveEventRepository implements EventRepository {
  HiveEventRepository(this._storage);

  final HiveAppStorage _storage;

  @override
  Future<List<IslamicEvent>> getAll() async => _storage.events.values
      .map(
        (value) =>
            IslamicEvent.fromMap(jsonDecode(value) as Map<String, dynamic>),
      )
      .toList(growable: false);

  @override
  Future<IslamicEvent?> getById(String eventId) async {
    final value = _storage.events.get(eventId);
    return value == null
        ? null
        : IslamicEvent.fromMap(jsonDecode(value) as Map<String, dynamic>);
  }

  @override
  Future<void> save(IslamicEvent event) =>
      _storage.events.put(event.id, jsonEncode(event.toMap()));

  @override
  Future<void> delete(String eventId) => _storage.events.delete(eventId);

  @override
  Future<void> seedDefaults() async {
    if (_storage.events.isNotEmpty) return;
    final now = DateTime.now();
    await Future.wait(defaultIslamicOccasions(now).map(save));
  }
}

List<IslamicEvent> defaultIslamicOccasions(DateTime createdAt) => [
  _hijriEvent('ramadan', 'Ramadan begins', 9, 1, createdAt),
  _hijriEvent('eid-al-fitr', 'Eid al-Fitr', 10, 1, createdAt),
  _hijriEvent('ashura', 'Ashura', 1, 10, createdAt),
  _hijriEvent('eid-al-adha', 'Eid al-Adha', 12, 10, createdAt),
  _hijriEvent('mawlid', 'Mawlid al-Nabi', 3, 12, createdAt),
];

const defaultIslamicOccasionIds = {
  'ramadan',
  'eid-al-fitr',
  'ashura',
  'eid-al-adha',
  'mawlid',
};

bool isDefaultIslamicOccasion(IslamicEvent event) =>
    defaultIslamicOccasionIds.contains(event.id);

IslamicEvent _hijriEvent(
  String id,
  String title,
  int month,
  int day,
  DateTime now,
) => IslamicEvent(
  id: id,
  title: title,
  dateType: EventDateType.hijri,
  hijriMonth: month,
  hijriDay: day,
  repeatsYearly: true,
  enabled: true,
  createdAt: now,
  updatedAt: now,
);
