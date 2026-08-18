enum SavingEntryType { add, subtract }

class SavingEntry {
  const SavingEntry({
    required this.id,
    required this.eventId,
    required this.amount,
    required this.entryType,
    required this.createdAt,
    this.note,
  });

  final String id;
  final String eventId;
  final int amount;
  final SavingEntryType entryType;
  final DateTime createdAt;
  final String? note;

  Map<String, Object?> toMap() => {
    'id': id,
    'eventId': eventId,
    'amount': amount,
    'entryType': entryType.name,
    'createdAt': createdAt.toIso8601String(),
    'note': note,
  };

  factory SavingEntry.fromMap(Map<String, dynamic> map) => SavingEntry(
    id: map['id'] as String,
    eventId: map['eventId'] as String,
    amount: map['amount'] as int,
    entryType: SavingEntryType.values.byName(map['entryType'] as String),
    createdAt: DateTime.parse(map['createdAt'] as String),
    note: map['note'] as String?,
  );
}
