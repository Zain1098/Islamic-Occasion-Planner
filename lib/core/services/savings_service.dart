class SavingsPlan {
  const SavingsPlan({
    required this.targetAmount,
    required this.savedAmount,
    required this.daysRemaining,
  });

  final int targetAmount;
  final int savedAmount;
  final int daysRemaining;

  int get remainingAmount =>
      (targetAmount - savedAmount).isNegative ? 0 : targetAmount - savedAmount;
  bool get isOverdue => daysRemaining < 0;
  double get progress =>
      targetAmount == 0 ? 0 : (savedAmount / targetAmount).clamp(0, 1);
  int get perDay => _requiredFor(1);
  int get perWeek => _requiredFor(7);
  int get perMonth => _requiredFor(30);

  int _requiredFor(int periodDays) {
    if (remainingAmount == 0 || daysRemaining <= 0) return 0;
    return (remainingAmount * periodDays / daysRemaining).ceil();
  }
}
