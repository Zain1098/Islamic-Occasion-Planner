enum AppThemePreference { system, light, dark }

class AppSettings {
  const AppSettings({
    this.hijriAdjustmentDays = 0,
    this.currencyCode = 'PKR',
    this.notificationsEnabled = false,
    this.themeMode = AppThemePreference.system,
  }) : assert(hijriAdjustmentDays >= -1 && hijriAdjustmentDays <= 1);

  final int hijriAdjustmentDays;
  final String currencyCode;
  final bool notificationsEnabled;
  final AppThemePreference themeMode;

  Map<String, Object?> toMap() => {
    'hijriAdjustmentDays': hijriAdjustmentDays,
    'currencyCode': currencyCode,
    'notificationsEnabled': notificationsEnabled,
    'themeMode': themeMode.name,
  };

  factory AppSettings.fromMap(Map<String, dynamic> map) => AppSettings(
    hijriAdjustmentDays: map['hijriAdjustmentDays'] as int,
    currencyCode: map['currencyCode'] as String,
    notificationsEnabled: map['notificationsEnabled'] as bool,
    themeMode: AppThemePreference.values.byName(map['themeMode'] as String),
  );
}
