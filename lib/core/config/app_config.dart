class AppConfig {
  const AppConfig._();

  /// These are public client values, safe to ship with the Android app.
  /// A service-role or secret key must never be placed here.
  static const supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://ubexvdioqjztbqvzptgj.supabase.co',
  );
  static const supabasePublishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
    defaultValue: 'sb_publishable_eYXzfeZ0XlJZhZtYUb3glw_NVPQcRt_',
  );

  static bool get hasOfficialHijriConfiguration {
    final uri = Uri.tryParse(supabaseUrl);
    return uri != null &&
        uri.hasScheme &&
        uri.host.endsWith('.supabase.co') &&
        supabasePublishableKey.isNotEmpty;
  }
}
