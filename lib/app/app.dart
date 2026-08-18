import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/providers/repository_providers.dart';
import '../core/services/notification_service.dart';
import '../features/dashboard/presentation/dashboard_screen.dart';
import '../features/calendar/presentation/calendar_screen.dart';
import '../features/events/presentation/events_screen.dart';
import 'theme/app_theme.dart';

class IslamicOccasionPlannerApp extends ConsumerWidget {
  const IslamicOccasionPlannerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Islamic Occasion Planner',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      home: const AppShell(),
    );
  }
}

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  int _selectedIndex = 0;
  late final VoidCallback _notificationListener;
  late final NotificationService _notifications;

  @override
  void initState() {
    super.initState();
    _notifications = ref.read(notificationServiceProvider);
    _notificationListener = () {
      if (_notifications.tappedEventId.value != null && mounted) {
        _selectDestination(2);
      }
    };
    _notifications.tappedEventId.addListener(_notificationListener);
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _notificationListener(),
    );
  }

  @override
  void dispose() {
    _notifications.tappedEventId.removeListener(_notificationListener);
    super.dispose();
  }

  static const _destinations = <_Destination>[
    _Destination(
      label: 'Home',
      icon: Icons.home_outlined,
      selectedIcon: Icons.home,
    ),
    _Destination(
      label: 'Calendar',
      icon: Icons.calendar_month_outlined,
      selectedIcon: Icons.calendar_month,
    ),
    _Destination(
      label: 'Plans',
      icon: Icons.account_balance_wallet_outlined,
      selectedIcon: Icons.account_balance_wallet,
    ),
    _Destination(
      label: 'Settings',
      icon: Icons.tune_outlined,
      selectedIcon: Icons.tune,
    ),
  ];

  void _selectDestination(int index) => setState(() => _selectedIndex = index);

  @override
  Widget build(BuildContext context) {
    final destination = _destinations[_selectedIndex];
    return Scaffold(
      body: SafeArea(
        child: switch (_selectedIndex) {
          0 => DashboardScreen(onViewPlans: () => _selectDestination(2)),
          1 => const CalendarScreen(),
          2 => const EventsScreen(),
          _ => _ShellPage(title: destination.label),
        },
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _selectDestination,
        destinations: [
          for (final destination in _destinations)
            NavigationDestination(
              icon: Icon(destination.icon),
              selectedIcon: Icon(destination.selectedIcon),
              label: destination.label,
            ),
        ],
      ),
    );
  }
}

class _ShellPage extends StatelessWidget {
  const _ShellPage({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(
            '$title will be ready as the planner takes shape.',
            style: textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const Spacer(),
          Center(
            child: Icon(
              Icons.construction_outlined,
              size: 48,
              color: colorScheme.primary,
              semanticLabel: '$title in progress',
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              'This section is part of a later V1 phase.',
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium,
            ),
          ),
          const Spacer(flex: 2),
        ],
      ),
    );
  }
}

class _Destination {
  const _Destination({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}
