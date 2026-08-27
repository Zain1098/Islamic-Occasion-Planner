import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/planner_data_refresh.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../core/services/backup_service.dart';
import '../../../shared/models/app_settings.dart';
import '../../../shared/widgets/app_state_view.dart';
import '../../dashboard/presentation/dashboard_provider.dart';
import 'encrypted_backup_pin_dialog.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);
    return settings.when(
      loading: () => const AppLoadingView(label: 'Loading settings'),
      error: (error, stackTrace) => AppErrorView(
        message: 'Settings could not be loaded.',
        onRetry: () => ref.invalidate(appSettingsProvider),
      ),
      data: (value) => _SettingsContent(settings: value),
    );
  }
}

class _SettingsContent extends ConsumerStatefulWidget {
  const _SettingsContent({required this.settings});

  final AppSettings settings;

  @override
  ConsumerState<_SettingsContent> createState() => _SettingsContentState();
}

class _SettingsContentState extends ConsumerState<_SettingsContent> {
  late AppSettings _settings;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _settings = widget.settings;
  }

  Future<void> _save(AppSettings updated, {bool reschedule = false}) async {
    setState(() => _busy = true);
    try {
      await ref.read(settingsRepositoryProvider).save(updated);
      if (reschedule)
        await ref.read(reminderCoordinatorProvider).rescheduleAll();
      if (mounted) {
        setState(() => _settings = updated);
        ref.invalidate(appSettingsProvider);
        ref.invalidate(dashboardProvider);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _setNotifications(bool enabled) async {
    if (enabled) {
      final granted = await ref
          .read(notificationServiceProvider)
          .requestPermission();
      if (!granted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Notification permission was not granted.'),
            ),
          );
        }
        return;
      }
    }
    await _save(
      _settings.copyWith(notificationsEnabled: enabled),
      reschedule: true,
    );
  }

  Future<void> _importBackup() async {
    setState(() => _busy = true);
    try {
      final backup = ref.read(backupServiceProvider);
      var source = await backup.pickBackupSource();
      if (source == null || !mounted) return;
      String? safetyBackupPin;
      if (backup.isEncryptedBackup(source)) {
        final pin = await showEncryptedBackupUnlockDialog(context);
        if (pin == null || !mounted) return;
        source = await backup.decryptBackup(source, pin);
        safetyBackupPin = pin;
      }
      final preview = backup.previewJson(source);
      if (!mounted) return;
      final confirmed = await _confirmRestore(preview);
      if (confirmed != true) return;
      safetyBackupPin ??= await showEncryptedBackupPinDialog(
        context,
        title: 'Protect safety backup',
        description:
            'Choose a PIN for the encrypted copy of your current planner data. You will need it if you ever restore this safety backup.',
        actionLabel: 'Continue import',
      );
      if (safetyBackupPin == null || !mounted) return;
      await backup.importJson(source, safetyBackupPin: safetyBackupPin);
      await ref.read(reminderCoordinatorProvider).rescheduleAll();
      if (mounted) {
        final restoredSettings = await ref
            .read(settingsRepositoryProvider)
            .get();
        if (!mounted) return;
        setState(() => _settings = restoredSettings);
        refreshPlannerData(ref);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Backup imported. An encrypted safety backup was saved first.'),
          ),
        );
      }
    } on FormatException catch (error) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<bool?> _confirmRestore(BackupPreview preview) => showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Replace current planner data?'),
      content: Text(
        'This backup contains ${preview.events} occasions, ${preview.budgetItems} budget items, ${preview.savingEntries} savings entries, and ${preview.reminders} reminder plans.\n\nImporting replaces current local data. Noor will first create a safety backup.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Import'),
        ),
      ],
    ),
  );

  Future<void> _exportEncryptedBackup() async {
    final pin = await showEncryptedBackupPinDialog(context);
    if (pin == null || !mounted) return;
    setState(() => _busy = true);
    try {
      await ref.read(backupServiceProvider).exportEncryptedAndShare(pin);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _scheduleTestReminder() async {
    final granted = await ref
        .read(notificationServiceProvider)
        .requestPermission();
    if (!granted) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Allow notifications in Android settings first.'),
          ),
        );
      return;
    }
    await ref.read(notificationServiceProvider).scheduleTestReminder();
    if (mounted)
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Test reminder scheduled for about one minute from now.',
          ),
        ),
      );
  }

  Future<void> _syncHijriNow() async {
    setState(() => _busy = true);
    try {
      final result = await ref
          .read(hijriSyncServiceProvider)
          .syncHijriDate(force: true, ref: ref);
      if (result.success) {
        await ref.read(reminderCoordinatorProvider).rescheduleAll();
      }
      if (mounted) {
        final restoredSettings = await ref
            .read(settingsRepositoryProvider)
            .get();
        setState(() => _settings = restoredSettings);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(result.message)));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pickReminderTime() async {
    final current = _settings.reminderTimeMinutes;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: current ~/ 60, minute: current % 60),
      helpText: 'Choose reminder time',
    );
    if (picked == null || !mounted) return;
    final minutes = picked.hour * 60 + picked.minute;
    await _save(
      _settings.copyWith(reminderTimeMinutes: minutes),
      reschedule: true,
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Settings')),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      children: [
        Text('Calendar', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Card(
          child: Column(
            children: [
              ListTile(
                title: const Text('Hijri date adjustment'),
                subtitle: const Text('Dates may vary by local moon sighting.'),
                trailing: DropdownButton<int>(
                  value: _settings.hijriAdjustmentDays,
                  underline: const SizedBox.shrink(),
                  onChanged: _busy
                      ? null
                      : (value) {
                          if (value != null) {
                            _save(
                              _settings.copyWith(hijriAdjustmentDays: value),
                              reschedule: true,
                            );
                          }
                        },
                  items: const [
                    DropdownMenuItem(value: -1, child: Text('-1 day')),
                    DropdownMenuItem(value: 0, child: Text('0 days')),
                    DropdownMenuItem(value: 1, child: Text('+1 day')),
                  ],
                ),
              ),
              const Divider(height: 1),
              SwitchListTile(
                value: _settings.autoSyncHijri,
                onChanged: _busy
                    ? null
                    : (enabled) =>
                          _save(_settings.copyWith(autoSyncHijri: enabled)),
                title: const Text('Auto-sync Hijri date (Online)'),
                subtitle: const Text(
                  'Auto-detect Pakistan moon sighting date when connected.',
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.sync_outlined),
                title: const Text('Sync date now'),
                subtitle: Text(_syncStatusText(_settings)),
                onTap: _busy ? null : _syncHijriNow,
              ),
              const Divider(height: 1),
              ListTile(
                title: const Text('Currency'),
                subtitle: const Text('Pakistani rupee'),
                trailing: Text(
                  _settings.currencyCode,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text('Reminders', style: Theme.of(context).textTheme.titleLarge),
        Card(
          child: Column(
            children: [
              SwitchListTile(
                value: _settings.notificationsEnabled,
                onChanged: _busy ? null : _setNotifications,
                title: const Text('Occasion reminders'),
                subtitle: const Text(
                  'Receive your selected advance reminders.',
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.notifications_active_outlined),
                title: const Text('Send test reminder'),
                subtitle: const Text(
                  'Schedules a test notification in about one minute.',
                ),
                onTap: _busy ? null : _scheduleTestReminder,
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.access_time_outlined),
                title: const Text('Reminder time'),
                subtitle: Text(_formatTime(_settings.reminderTimeMinutes)),
                onTap: _busy ? null : _pickReminderTime,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text('Appearance', style: Theme.of(context).textTheme.titleLarge),
        Card(
          child: ListTile(
            title: const Text('Theme'),
            trailing: DropdownButton<AppThemePreference>(
              value: _settings.themeMode,
              underline: const SizedBox.shrink(),
              onChanged: _busy
                  ? null
                  : (value) {
                      if (value == null) return;
                      _save(_settings.copyWith(themeMode: value));
                    },
              items: const [
                DropdownMenuItem(
                  value: AppThemePreference.system,
                  child: Text('System'),
                ),
                DropdownMenuItem(
                  value: AppThemePreference.light,
                  child: Text('Light'),
                ),
                DropdownMenuItem(
                  value: AppThemePreference.dark,
                  child: Text('Dark'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text('Backup', style: Theme.of(context).textTheme.titleLarge),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.ios_share_outlined),
                title: const Text('Export backup'),
                subtitle: const Text('Save all local planner data as JSON.'),
                onTap: _busy
                    ? null
                    : () async {
                        setState(() => _busy = true);
                        try {
                          await ref
                              .read(backupServiceProvider)
                              .exportAndShare();
                        } finally {
                          if (mounted) setState(() => _busy = false);
                        }
                      },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.lock_outline),
                title: const Text('Export encrypted backup'),
                subtitle: const Text('Protect your planner data with a PIN.'),
                onTap: _busy ? null : _exportEncryptedBackup,
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.file_open_outlined),
                title: const Text('Import backup'),
                subtitle: const Text(
                  'Restore a previously exported JSON file.',
                ),
                onTap: _busy ? null : _importBackup,
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

String _syncStatusText(AppSettings settings) {
  if (settings.lastHijriSyncIso == null) {
    return 'Not synced yet';
  }
  final adj = settings.hijriAdjustmentDays;
  final adjStr = adj == 0 ? '0 days' : (adj > 0 ? '+$adj day' : '$adj day');
  return 'Last synced: ${settings.lastHijriSyncIso} · Auto-adjusted ($adjStr)';
}

String _formatTime(int totalMinutes) {
  final hour = totalMinutes ~/ 60;
  final minute = totalMinutes % 60;
  final period = hour < 12 ? 'AM' : 'PM';
  final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
  final displayMin = minute.toString().padLeft(2, '0');
  return '$displayHour:$displayMin $period';
}
