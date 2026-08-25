import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';

import '../core/providers/repository_providers.dart';
import '../core/services/notification_service.dart';
import '../features/dashboard/presentation/dashboard_screen.dart';
import '../features/calendar/presentation/calendar_screen.dart';
import '../features/events/presentation/events_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../shared/models/app_settings.dart';
import 'theme/app_theme.dart';

class IslamicOccasionPlannerApp extends ConsumerWidget {
  const IslamicOccasionPlannerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);
    return MaterialApp(
      title: 'Islamic Occasion Planner',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: settings.value == null
          ? ThemeMode.system
          : _themeModeFor(settings.value!.themeMode),
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
  StreamSubscription<Uri?>? _widgetClickSubscription;

  @override
  void initState() {
    super.initState();
    _notifications = ref.read(notificationServiceProvider);
    _notificationListener = () {
      if (_notifications.tappedEventId.value != null && mounted) {
        _handleNotificationTap();
      }
    };
    _notifications.tappedEventId.addListener(_notificationListener);
    _widgetClickSubscription = HomeWidget.widgetClicked.listen((_) {
      if (mounted) _selectDestination(2);
    });
    WidgetsBinding.instance.addPostFrameCallback(
      (_) async {
        try {
          final coordinator = ref.read(reminderCoordinatorProvider);
          unawaited(coordinator.rescheduleAll());
        } catch (_) {}
        await _handleNotificationTap();
        if (await HomeWidget.initiallyLaunchedFromHomeWidget() != null &&
            mounted) {
          _selectDestination(2);
        }
      },
    );
  }

  Future<void> _handleNotificationTap() async {
    try {
      final eventId = _notifications.tappedEventId.value;
      if (eventId == null || !mounted) return;
      _notifications.tappedEventId.value = null;
      _selectDestination(2);
      final event = await ref.read(eventRepositoryProvider).getById(eventId);
      if (event != null && mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => EventDetailScreen(event: event),
          ),
        );
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _notifications.tappedEventId.removeListener(_notificationListener);
    _widgetClickSubscription?.cancel();
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
    return Scaffold(
      body: SafeArea(
        child: switch (_selectedIndex) {
          0 => DashboardScreen(onViewPlans: () => _selectDestination(2)),
          1 => const CalendarScreen(),
          2 => const EventsScreen(),
          _ => const SettingsScreen(),
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

ThemeMode _themeModeFor(AppThemePreference preference) => switch (preference) {
  AppThemePreference.system => ThemeMode.system,
  AppThemePreference.light => ThemeMode.light,
  AppThemePreference.dark => ThemeMode.dark,
};

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
