import 'dart:convert';
import 'dart:io';

import '../../features/settings/data/settings_repository.dart';
import '../config/app_config.dart';
import '../providers/planner_data_refresh.dart';
import 'date_service.dart';
import 'official_hijri_month.dart';

typedef OfficialHijriRequest =
    Future<String> Function(Uri, Map<String, String>);

class HijriSyncResult {
  const HijriSyncResult({
    required this.success,
    required this.message,
    this.adjustmentDays,
    this.officialMonth,
  });

  final bool success;
  final String message;
  final int? adjustmentDays;
  final OfficialHijriMonth? officialMonth;
}

/// Uses only published, confirmed Pakistan committee records. Calculated or
/// network data is deliberately never treated as official confirmation.
class HijriSyncService {
  HijriSyncService({
    required SettingsRepository settingsRepository,
    required DateService dateService,
    OfficialHijriRequest? request,
  }) : _settingsRepository = settingsRepository,
       _dateService = dateService,
       _request = request ?? _get;

  final SettingsRepository _settingsRepository;
  final DateService _dateService;
  final OfficialHijriRequest _request;

  Future<HijriSyncResult> syncHijriDate({
    bool force = false,
    dynamic ref,
  }) async {
    final settings = await _settingsRepository.get();
    if (!force && !settings.autoSyncHijri) {
      return const HijriSyncResult(
        success: false,
        message: 'Official Hijri auto-sync is disabled in settings.',
      );
    }
    if (!AppConfig.hasOfficialHijriConfiguration) {
      return const HijriSyncResult(
        success: false,
        message:
            'Official Hijri source is not configured. Using calculated date.',
      );
    }
    final today = _dateService.today();
    final todayIso = _isoDate(today);
    if (!force && settings.lastHijriSyncIso == todayIso) {
      return HijriSyncResult(
        success: true,
        message: 'Official Hijri date already synced today.',
        adjustmentDays: settings.hijriAdjustmentDays,
      );
    }
    try {
      final record = await _fetchLatestConfirmedMonth(today);
      if (record == null) {
        return const HijriSyncResult(
          success: false,
          message:
              'No confirmed Ruet-e-Hilal Committee record is published yet. Using calculated date.',
        );
      }
      final day = today.difference(record.startsOn).inDays + 1;
      // A Hijri lunar month is never longer than 30 days. Do not interpret a
      // Hijri year/month as Gregorian values when validating this record.
      if (day < 1 || day > 30) {
        return const HijriSyncResult(
          success: false,
          message:
              'Latest official Hijri record does not cover today. Using calculated date.',
        );
      }
      final adjustment = _matchingAdjustment(
        today: today,
        year: record.year,
        month: record.month,
        day: day,
      );
      if (adjustment == null) {
        return HijriSyncResult(
          success: false,
          message:
              'Official date differs by more than one day. Keeping calculated date for safety.',
          officialMonth: record,
        );
      }
      await _settingsRepository.save(
        settings.copyWith(
          hijriAdjustmentDays: adjustment,
          lastHijriSyncIso: todayIso,
        ),
      );
      if (ref != null) refreshPlannerData(ref);
      return HijriSyncResult(
        success: true,
        message:
            'Synced with ${record.authorityName} (${_adjustmentLabel(adjustment)}).',
        adjustmentDays: adjustment,
        officialMonth: record,
      );
    } on SocketException {
      return const HijriSyncResult(
        success: false,
        message: 'Network unavailable. Using calculated date.',
      );
    } on HttpException {
      return const HijriSyncResult(
        success: false,
        message:
            'Official Hijri source could not be reached. Using calculated date.',
      );
    } on FormatException {
      return const HijriSyncResult(
        success: false,
        message: 'Official Hijri record is invalid. Using calculated date.',
      );
    } catch (_) {
      return const HijriSyncResult(
        success: false,
        message: 'Official Hijri sync failed. Using calculated date.',
      );
    }
  }

  Future<OfficialHijriMonth?> _fetchLatestConfirmedMonth(DateTime today) async {
    final uri =
        Uri.parse(
          '${AppConfig.supabaseUrl}/rest/v1/official_hijri_months',
        ).replace(
          queryParameters: {
            'select':
                'hijri_year,hijri_month,starts_on,authority_name,source_url,announced_at',
            'country_code': 'eq.PK',
            'status': 'eq.confirmed',
            'starts_on': 'lte.${_isoDate(today)}',
            'order': 'starts_on.desc',
            'limit': '1',
          },
        );
    final body = await _request(uri, {
      'apikey': AppConfig.supabasePublishableKey,
      'Authorization': 'Bearer ${AppConfig.supabasePublishableKey}',
      'Accept': 'application/json',
    });
    final rows = jsonDecode(body) as List<dynamic>;
    return rows.isEmpty
        ? null
        : OfficialHijriMonth.fromMap(rows.first as Map<String, dynamic>);
  }

  int? _matchingAdjustment({
    required DateTime today,
    required int year,
    required int month,
    required int day,
  }) {
    for (final adjustment in const [-1, 0, 1]) {
      final candidate = _dateService.hijriDateFor(
        today,
        adjustmentDays: adjustment,
      );
      if (candidate.year == year &&
          candidate.month == month &&
          candidate.day == day)
        return adjustment;
    }
    return null;
  }

  static String _isoDate(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  static String _adjustmentLabel(int adjustment) => adjustment == 0
      ? 'no adjustment'
      : '${adjustment > 0 ? '+' : ''}$adjustment day';

  static Future<String> _get(Uri uri, Map<String, String> headers) async {
    final client = HttpClient();
    try {
      final request = await client
          .getUrl(uri)
          .timeout(const Duration(seconds: 8));
      headers.forEach(request.headers.set);
      final response = await request.close().timeout(
        const Duration(seconds: 8),
      );
      final body = await response.transform(utf8.decoder).join();
      if (response.statusCode != HttpStatus.ok)
        throw HttpException(
          'Official Hijri request returned ${response.statusCode}.',
        );
      return body;
    } finally {
      client.close(force: true);
    }
  }
}
