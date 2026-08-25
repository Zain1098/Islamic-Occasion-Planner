enum AppThemePreference { system, light, dark }

class AppSettings {
  const AppSettings({
    this.hijriAdjustmentDays = 0,
    this.currencyCode = 'PKR',
    this.notificationsEnabled = false,
    this.themeMode = AppThemePreference.system,
    this.autoSyncHijri = true,
    this.lastHijriSyncIso,
  }) : assert(hijriAdjustmentDays >= -1 && hijriAdjustmentDays <= 1);

  final int hijriAdjustmentDays;
  final String currencyCode;
  final bool notificationsEnabled;
  final AppThemePreference themeMode;
  final bool autoSyncHijri;
  final String? lastHijriSyncIso;

  AppSettings copyWith({
    int? hijriAdjustmentDays,
    String? currencyCode,
    bool? notificationsEnabled,
    AppThemePreference? themeMode,
    bool? autoSyncHijri,
    Object? lastHijriSyncIso = _sentinel,
  }) => AppSettings(
    hijriAdjustmentDays: hijriAdjustmentDays ?? this.hijriAdjustmentDays,
    currencyCode: currencyCode ?? this.currencyCode,
    notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
    themeMode: themeMode ?? this.themeMode,
    autoSyncHijri: autoSyncHijri ?? this.autoSyncHijri,
    lastHijriSyncIso: lastHijriSyncIso == _sentinel
        ? this.lastHijriSyncIso
        : lastHijriSyncIso as String?,
  );

  Map<String, Object?> toMap() => {
    'hijriAdjustmentDays': hijriAdjustmentDays,
    'currencyCode': currencyCode,
    'notificationsEnabled': notificationsEnabled,
    'themeMode': themeMode.name,
    'autoSyncHijri': autoSyncHijri,
    'lastHijriSyncIso': lastHijriSyncIso,
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
  );
}

const _sentinel = Object();
