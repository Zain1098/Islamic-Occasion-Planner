enum AppThemePreference { system, light, dark }

class AppSettings {
  const AppSettings({
    this.hijriAdjustmentDays = 0,
    this.currencyCode = 'PKR',
    this.notificationsEnabled = false,
    this.themeMode = AppThemePreference.system,
    this.autoSyncHijri = true,
    this.lastHijriSyncIso,
    this.reminderTimeMinutes = 540, // 9:00 AM default
  }) : assert(hijriAdjustmentDays >= -1 && hijriAdjustmentDays <= 1);

  final int hijriAdjustmentDays;
  final String currencyCode;
  final bool notificationsEnabled;
  final AppThemePreference themeMode;
  final bool autoSyncHijri;
  final String? lastHijriSyncIso;

  /// Minutes from midnight for reminder notifications (e.g. 540 = 9:00 AM,
  /// 1080 = 6:00 PM). Stored & surfaced so the user can customise it.
  final int reminderTimeMinutes;

  /// True if the Hijri date was synced online today — used to show the
  /// "Official Pakistan confirmation" badge on the dashboard.
  bool hijriSyncedToday(DateTime today) {
    if (lastHijriSyncIso == null) return false;
    final iso =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    return lastHijriSyncIso == iso;
  }

  AppSettings copyWith({
    int? hijriAdjustmentDays,
    String? currencyCode,
    bool? notificationsEnabled,
    AppThemePreference? themeMode,
    bool? autoSyncHijri,
    Object? lastHijriSyncIso = _sentinel,
    int? reminderTimeMinutes,
  }) => AppSettings(
    hijriAdjustmentDays: hijriAdjustmentDays ?? this.hijriAdjustmentDays,
    currencyCode: currencyCode ?? this.currencyCode,
    notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
    themeMode: themeMode ?? this.themeMode,
    autoSyncHijri: autoSyncHijri ?? this.autoSyncHijri,
    lastHijriSyncIso: lastHijriSyncIso == _sentinel
        ? this.lastHijriSyncIso
        : lastHijriSyncIso as String?,
    reminderTimeMinutes: reminderTimeMinutes ?? this.reminderTimeMinutes,
  );

  Map<String, Object?> toMap() => {
    'hijriAdjustmentDays': hijriAdjustmentDays,
    'currencyCode': currencyCode,
    'notificationsEnabled': notificationsEnabled,
    'themeMode': themeMode.name,
    'autoSyncHijri': autoSyncHijri,
    'lastHijriSyncIso': lastHijriSyncIso,
    'reminderTimeMinutes': reminderTimeMinutes,
  };

  factory AppSettings.fromMap(Map<String, dynamic> map) => AppSettings(
    hijriAdjustmentDays: (map['hijriAdjustmentDays'] as int?) ?? 0,
    currencyCode: (map['currencyCode'] as String?) ?? 'PKR',
    notificationsEnabled: (map['notificationsEnabled'] as bool?) ?? false,
    themeMode: map['themeMode'] == null
        ? AppThemePreference.system
        : AppThemePreference.values.byName(map['themeMode'] as String),
    autoSyncHijri: (map['autoSyncHijri'] as bool?) ?? true,
    lastHijriSyncIso: map['lastHijriSyncIso'] as String?,
    reminderTimeMinutes: (map['reminderTimeMinutes'] as int?) ?? 540,
  );
}

const _sentinel = Object();
