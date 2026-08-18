enum EventDateType { hijri, gregorian }

class IslamicEvent {
  const IslamicEvent({
    required this.id,
    required this.title,
    required this.dateType,
    required this.repeatsYearly,
    required this.enabled,
    required this.createdAt,
    required this.updatedAt,
    this.notes,
    this.hijriMonth,
    this.hijriDay,
    this.gregorianDate,
    this.manuallyOverriddenDate,
  });

  final String id;
  final String title;
  final String? notes;
  final EventDateType dateType;
  final int? hijriMonth;
  final int? hijriDay;
  final DateTime? gregorianDate;
  final DateTime? manuallyOverriddenDate;
  final bool repeatsYearly;
  final bool enabled;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, Object?> toMap() => {
    'id': id,
    'title': title,
    'notes': notes,
    'dateType': dateType.name,
    'hijriMonth': hijriMonth,
    'hijriDay': hijriDay,
    'gregorianDate': gregorianDate?.toIso8601String(),
    'manuallyOverriddenDate': manuallyOverriddenDate?.toIso8601String(),
    'repeatsYearly': repeatsYearly,
    'enabled': enabled,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory IslamicEvent.fromMap(Map<String, dynamic> map) {
    final dateType = EventDateType.values.byName(map['dateType'] as String);
    final hijriMonth = map['hijriMonth'] as int?;
    final hijriDay = map['hijriDay'] as int?;
    final gregorianDate = _readDate(map['gregorianDate']);
    if (dateType == EventDateType.hijri &&
        (hijriMonth == null || hijriDay == null)) {
      throw const FormatException('A Hijri event requires a month and day.');
    }
    if (dateType == EventDateType.gregorian && gregorianDate == null) {
      throw const FormatException('A Gregorian event requires a date.');
    }
    return IslamicEvent(
      id: map['id'] as String,
      title: map['title'] as String,
      notes: map['notes'] as String?,
      dateType: dateType,
      hijriMonth: hijriMonth,
      hijriDay: hijriDay,
      gregorianDate: gregorianDate,
      manuallyOverriddenDate: _readDate(map['manuallyOverriddenDate']),
      repeatsYearly: map['repeatsYearly'] as bool,
      enabled: map['enabled'] as bool,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }
}

DateTime? _readDate(Object? value) =>
    value == null ? null : DateTime.parse(value as String);
