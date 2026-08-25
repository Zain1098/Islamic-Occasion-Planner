import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/repository_providers.dart';
import '../../../core/services/date_service.dart';
import '../../../shared/widgets/app_state_view.dart';
import '../domain/dashboard_data.dart';
import 'dashboard_provider.dart';

import '../../../core/utils/currency_formatter.dart';
import '../../savings/presentation/add_saving_dialog.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key, required this.onViewPlans});

  final VoidCallback onViewPlans;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboard = ref.watch(dashboardProvider);
    final settings = ref.watch(appSettingsProvider).value;
    final currencyCode = settings?.currencyCode ?? 'PKR';

    return dashboard.when(
      loading: () => const AppLoadingView(label: 'Loading dashboard'),
      error: (error, stackTrace) => AppErrorView(
        message: 'Your dashboard could not be loaded.',
        onRetry: () => ref.invalidate(dashboardProvider),
      ),
      data: (data) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          unawaited(ref.read(homeWidgetServiceProvider).update(data));
        });
        return _DashboardContent(
          data: data,
          onViewPlans: onViewPlans,
          currencyCode: currencyCode,
        );
      },
    );
  }
}

class _DashboardContent extends ConsumerWidget {
  const _DashboardContent({
    required this.data,
    required this.onViewPlans,
    required this.currencyCode,
  });

  final DashboardData data;
  final VoidCallback onViewPlans;
  final String currencyCode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
          sliver: SliverList.list(
            children: [
              Text('Assalamu Alaikum', style: theme.textTheme.headlineMedium),
              const SizedBox(height: 6),
              Text(
                _formatGregorianDate(data.today),
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: 2),
              Text(
                _formatHijriDate(data.hijriToday),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              if (data.nextEvent case final nextEvent?) ...[
                _NextEventCard(
                  summary: nextEvent,
                  onViewPlans: onViewPlans,
                  currencyCode: currencyCode,
                ),
                const SizedBox(height: 28),
                _SectionHeader(
                  title: 'Upcoming occasions',
                  action: 'View plans',
                  onAction: onViewPlans,
                ),
                const SizedBox(height: 12),
                ...data.upcomingEvents
                    .take(4)
                    .map(
                      (summary) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _UpcomingEventCard(
                          summary: summary,
                          currencyCode: currencyCode,
                        ),
                      ),
                    ),
                const SizedBox(height: 12),
                _YearlySummary(
                  totalPlannedAmount: data.totalPlannedAmount,
                  monthlyAmountNeeded: data.monthlyAmountNeeded,
                  currencyCode: currencyCode,
                ),
              ] else
                _NoUpcomingEvents(onViewPlans: onViewPlans),
            ],
          ),
        ),
      ],
    );
  }
}

class _NextEventCard extends ConsumerWidget {
  const _NextEventCard({
    required this.summary,
    required this.onViewPlans,
    required this.currencyCode,
  });

  final DashboardEventSummary summary;
  final VoidCallback onViewPlans;
  final String currencyCode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const foreground = Color(0xFFFFF9F0);
    final isBudgeted = summary.targetAmount > 0;
    final savedText = formatCurrency(summary.savedAmount, currencyCode);
    final targetText = formatCurrency(summary.targetAmount, currencyCode);
    final remainingText = formatCurrency(summary.remainingAmount, currencyCode);
    final dailyRateText = formatCurrency(summary.dailySavingRequired, currencyCode);

    final statusText = isBudgeted
        ? '$savedText saved of $targetText ($remainingText left)'
        : 'Set a budget to start planning.';

    return Semantics(
      label:
          'Next occasion: ${summary.event.title}, ${summary.daysRemaining} days remaining',
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF285745),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: Color(0xFFB68A3A),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.auto_awesome_outlined,
                    color: Color(0xFF29251F),
                  ),
                ),
                const Spacer(),
                Text(
                  '${summary.daysRemaining} days left',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: foreground,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              'Next occasion',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: foreground.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              summary.event.title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: foreground,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatShortDate(summary.date),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: foreground.withValues(alpha: 0.82),
              ),
            ),
            const SizedBox(height: 20),
            LinearProgressIndicator(
              value: summary.progress,
              minHeight: 8,
              borderRadius: BorderRadius.circular(12),
              backgroundColor: foreground.withValues(alpha: 0.2),
              color: const Color(0xFFE7C878),
            ),
            const SizedBox(height: 10),
            Text(
              statusText,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: foreground),
            ),
            if (isBudgeted && summary.dailySavingRequired > 0) ...[
              const SizedBox(height: 4),
              Text(
                '$dailyRateText / day required',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: const Color(0xFFE7C878),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: () => showAddSavingDialog(
                    context: context,
                    ref: ref,
                    eventId: summary.event.id,
                    currencyCode: currencyCode,
                    currentSaved: summary.savedAmount,
                  ),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add saving'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFB68A3A),
                    foregroundColor: const Color(0xFF29251F),
                  ),
                ),
                TextButton.icon(
                  onPressed: onViewPlans,
                  icon: const Icon(Icons.arrow_forward),
                  iconAlignment: IconAlignment.end,
                  label: const Text('View plan'),
                  style: TextButton.styleFrom(foregroundColor: foreground),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _UpcomingEventCard extends StatelessWidget {
  const _UpcomingEventCard({
    required this.summary,
    required this.currencyCode,
  });

  final DashboardEventSummary summary;
  final String currencyCode;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.event_outlined,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    summary.event.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${_formatShortDate(summary.date)} · ${summary.daysRemaining} days left',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              summary.targetAmount == 0
                  ? 'No budget'
                  : formatCurrency(summary.targetAmount, currencyCode),
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _YearlySummary extends StatelessWidget {
  const _YearlySummary({
    required this.totalPlannedAmount,
    required this.monthlyAmountNeeded,
    required this.currencyCode,
  });

  final int totalPlannedAmount;
  final int monthlyAmountNeeded;
  final String currencyCode;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: theme.colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Yearly planning',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Planned across upcoming occasions',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Text(
              formatCurrency(totalPlannedAmount, currencyCode),
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            if (monthlyAmountNeeded > 0) ...[
              const SizedBox(height: 6),
              Text(
                '~${formatCurrency(monthlyAmountNeeded, currencyCode)} / month needed',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSecondaryContainer.withValues(alpha: 0.85),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _NoUpcomingEvents extends StatelessWidget {
  const _NoUpcomingEvents({required this.onViewPlans});

  final VoidCallback onViewPlans;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Icon(Icons.event_available_outlined, size: 40),
          const SizedBox(height: 12),
          Text(
            'No upcoming plans',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 6),
          const Text(
            'Add an occasion you want to prepare for.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          TextButton(onPressed: onViewPlans, child: const Text('View plans')),
        ],
      ),
    ),
  );
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.action,
    required this.onAction,
  });

  final String title;
  final String action;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      TextButton(onPressed: onAction, child: Text(action)),
    ],
  );
}

String _formatAmount(int amount) => amount.toString().replaceAllMapped(
  RegExp(r'(?<=\d)(?=(\d{3})+(?!\d))'),
  (match) => ',',
);

String _formatGregorianDate(DateTime date) {
  const weekdays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];
  const months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  return '${weekdays[date.weekday - 1]}, ${date.day} ${months[date.month - 1]}';
}

String _formatHijriDate(HijriDate date) {
  const months = [
    'Muharram',
    'Safar',
    'Rabi al-Awwal',
    'Rabi al-Thani',
    'Jumada al-Awwal',
    'Jumada al-Thani',
    'Rajab',
    'Shaban',
    'Ramadan',
    'Shawwal',
    'Dhu al-Qadah',
    'Dhu al-Hijjah',
  ];
  return '${date.day} ${months[date.month - 1]} ${date.year} AH';
}

String _formatShortDate(DateTime date) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${date.day} ${months[date.month - 1]} ${date.year}';
}
