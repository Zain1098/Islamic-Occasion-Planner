import 'package:home_widget/home_widget.dart';

import '../../features/dashboard/domain/dashboard_data.dart';

/// Keeps the Android home-screen widget in sync with the planner's next event.
class HomeWidgetService {
  static const _provider =
      'com.islamicoccasionplanner.app.OccasionPlannerWidgetProvider';

  Future<void> update(DashboardData data) async {
    final next = data.nextEvent;
    final title = next?.event.title ?? 'No upcoming occasion';
    final subtitle = next == null
        ? 'Open Noor to add your first plan'
        : '${next.daysRemaining} day${next.daysRemaining == 1 ? '' : 's'} left';
    final amount = next == null
        ? 'Plan ahead, stress less'
        : next.targetAmount == 0
        ? 'Set a budget in Noor'
        : 'Rs ${_formatAmount(next.remainingAmount)} remaining';

    await Future.wait([
      HomeWidget.saveWidgetData<String>('widget_title', title),
      HomeWidget.saveWidgetData<String>('widget_subtitle', subtitle),
      HomeWidget.saveWidgetData<String>('widget_amount', amount),
    ]);
    await HomeWidget.updateWidget(qualifiedAndroidName: _provider);
  }
}

String _formatAmount(int amount) => amount.toString().replaceAllMapped(
  RegExp(r'(?<=\d)(?=(\d{3})+(?!\d))'),
  (match) => ',',
);
