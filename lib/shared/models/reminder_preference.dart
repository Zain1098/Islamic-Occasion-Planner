class ReminderPreference {
  const ReminderPreference({
    required this.eventId,
    required this.offsetsInDays,
    required this.enabled,
  });

  final String eventId;
  final List<int> offsetsInDays;
  final bool enabled;

  Map<String, Object?> toMap() => {
    'eventId': eventId,
    'offsetsInDays': offsetsInDays,
    'enabled': enabled,
  };

  factory ReminderPreference.fromMap(Map<String, dynamic> map) =>
      ReminderPreference(
        eventId: map['eventId'] as String,
        offsetsInDays: (map['offsetsInDays'] as List<dynamic>).cast<int>(),
        enabled: map['enabled'] as bool,
      );
}
