import 'package:flutter_test/flutter_test.dart';
import 'package:islamic_occasion_planner/core/services/savings_service.dart';

void main() {
  test('calculates remaining progress and rounded saving targets', () {
    const plan = SavingsPlan(
      targetAmount: 10000,
      savedAmount: 2500,
      daysRemaining: 15,
    );

    expect(plan.remainingAmount, 7500);
    expect(plan.progress, 0.25);
    expect(plan.perDay, 500);
    expect(plan.perWeek, 3500);
    expect(plan.perMonth, 15000);
  });

  test('never requests additional saving for complete or overdue plans', () {
    const complete = SavingsPlan(
      targetAmount: 1000,
      savedAmount: 1000,
      daysRemaining: 3,
    );
    const overdue = SavingsPlan(
      targetAmount: 1000,
      savedAmount: 200,
      daysRemaining: -1,
    );

    expect(complete.perDay, 0);
    expect(overdue.perDay, 0);
    expect(overdue.isOverdue, isTrue);
  });
}
