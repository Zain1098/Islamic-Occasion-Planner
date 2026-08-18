class BudgetItem {
  const BudgetItem({
    required this.id,
    required this.eventId,
    required this.category,
    required this.plannedAmount,
    this.actualAmount,
  });

  final String id;
  final String eventId;
  final String category;
  final int plannedAmount;
  final int? actualAmount;

  Map<String, Object?> toMap() => {
    'id': id,
    'eventId': eventId,
    'category': category,
    'plannedAmount': plannedAmount,
    'actualAmount': actualAmount,
  };

  factory BudgetItem.fromMap(Map<String, dynamic> map) => BudgetItem(
    id: map['id'] as String,
    eventId: map['eventId'] as String,
    category: map['category'] as String,
    plannedAmount: map['plannedAmount'] as int,
    actualAmount: map['actualAmount'] as int?,
  );
}
