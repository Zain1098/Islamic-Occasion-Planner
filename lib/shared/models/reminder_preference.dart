class ReminderPreference {
  const ReminderPreference({
    required this.eventId,
    required this.offsetsInDays,
    this.reminderTimeMinutes = 540,
    required this.enabled,
  });

  final String eventId;
  final List<int> offsetsInDays;
  final int reminderTimeMinutes;
  final bool enabled;

  Map<String, Object?> toMap() => {
    'eventId': eventId,
    'reminderTimeMinutes': reminderTimeMinutes,
    'offsetsInDays': offsetsInDays,
    'enabled': enabled,
  };

  factory ReminderPreference.fromMap(Map<String, dynamic> map) =>
      ReminderPreference(
        eventId: map['eventId'] as String,
        offsetsInDays: (map['offsetsInDays'] as List<dynamic>).cast<int>(),
        reminderTimeMinutes: (map['reminderTimeMinutes'] as int?) ?? 540,
        enabled: map['enabled'] as bool,
      );
}
