import 'dart:convert';
import 'dart:io';

import '../../features/settings/data/settings_repository.dart';
import '../providers/planner_data_refresh.dart';
import 'date_service.dart';

class HijriSyncResult {
  const HijriSyncResult({
    required this.success,
    required this.message,
    this.adjustmentDays,
  });
  final bool success;
  final String message;
  final int? adjustmentDays;
}

/// Fetches the real-time Pakistan Hijri date from Aladhan API using the
/// Karachi calculation method (University of Islamic Sciences, Karachi —
/// method 1), then auto-sets hijriAdjustmentDays so the app matches the
/// Ruet-e-Hilal / Pakistan moon-sighting date every day.
///
/// Endpoint chain (tried in order until one succeeds):
///   1. timingsByCity – Karachi, Pakistan, method=1
///   2. gToH          – standard Aladhan Gregorian→Hijri
class HijriSyncService {
  HijriSyncService({
    required SettingsRepository settingsRepository,
    required DateService dateService,
    HttpClient? httpClient,
  })  : _settingsRepository = settingsRepository,
        _dateService = dateService,
        _client = httpClient ?? HttpClient();

  final SettingsRepository _settingsRepository;
  final DateService _dateService;
  final HttpClient _client;

  Future<HijriSyncResult> syncHijriDate({
    bool force = false,
    dynamic ref,
  }) async {
    final settings = await _settingsRepository.get();
    if (!force && !settings.autoSyncHijri) {
      return const HijriSyncResult(
        success: false,
        message: 'Auto-sync is disabled in settings.',
      );
    }

    final today = _dateService.today();
    final todayIso = _isoDate(today);

    if (!force && settings.lastHijriSyncIso == todayIso) {
      return HijriSyncResult(
        success: true,
        message: 'Already synced today.',
        adjustmentDays: settings.hijriAdjustmentDays,
      );
    }

    // DD-MM-YYYY format required by Aladhan API
    final ddmmyyyy =
        '${today.day.toString().padLeft(2, '0')}-${today.month.toString().padLeft(2, '0')}-${today.year}';

    final endpoints = [
      // Method 1 = University of Islamic Sciences, Karachi
      // — closest to official Pakistan Ruet-e-Hilal Committee dates
      Uri.parse(
          'https://api.aladhan.com/v1/timingsByCity/$ddmmyyyy?city=Karachi&country=Pakistan&method=1'),
      // Fallback: plain Gregorian→Hijri conversion
      Uri.parse('https://api.aladhan.com/v1/gToH/$ddmmyyyy'),
    ];

    Map<String, dynamic>? hijriData;
    String usedSource = 'Unknown';

    for (final url in endpoints) {
      try {
        final req = await _client.getUrl(url).timeout(const Duration(seconds: 8));
        final res = await req.close().timeout(const Duration(seconds: 8));
        if (res.statusCode == 200) {
          final body = await res.transform(utf8.decoder).join();
          final json = jsonDecode(body) as Map<String, dynamic>;
          if (json['code'] == 200 && json['data'] != null) {
            final data = json['data'] as Map<String, dynamic>;
            // timingsByCity wraps hijri inside data.date.hijri
            if (data['date'] is Map &&
                (data['date'] as Map)['hijri'] != null) {
              hijriData =
                  (data['date'] as Map<String, dynamic>)['hijri'] as Map<String, dynamic>;
              usedSource = 'Karachi (method 1)';
              break;
            }
            // gToH puts hijri directly in data.hijri
            if (data['hijri'] != null) {
              hijriData = data['hijri'] as Map<String, dynamic>;
              usedSource = 'Aladhan gToH';
              break;
            }
          }
        }
      } on SocketException {
        // try next endpoint
      } on TimeoutException {
        // try next endpoint
      } catch (_) {
        // try next endpoint
      }
    }

    if (hijriData == null) {
      return HijriSyncResult(
        success: false,
        message: 'Network offline – keeping last saved adjustment.',
        adjustmentDays: settings.hijriAdjustmentDays,
      );
    }

    final onlineDay = int.parse(hijriData['day'].toString().trim());
    final onlineMonth = int.parse(
        (hijriData['month'] as Map<String, dynamic>)['number'].toString());

    // Try -1, 0, +1 to find which adjustment makes local == online
    int? adjustment;
    for (final adj in const [-1, 0, 1]) {
      final candidate = _dateService.hijriDateFor(today, adjustmentDays: adj);
      if (candidate.day == onlineDay && candidate.month == onlineMonth) {
        adjustment = adj;
        break;
      }
    }

    // If no exact match (can happen at month boundaries), clamp to nearest
    if (adjustment == null) {
      final zeroAdj = _dateService.hijriDateFor(today, adjustmentDays: 0);
      final diff = onlineDay - zeroAdj.day;
      adjustment = diff.clamp(-1, 1);
    }

    await _settingsRepository.save(
      settings.copyWith(
        hijriAdjustmentDays: adjustment,
        lastHijriSyncIso: todayIso,
      ),
    );

    if (ref != null) refreshPlannerData(ref);

    final adjLabel = adjustment == 0
        ? 'no change'
        : (adjustment > 0 ? '+$adjustment day' : '$adjustment day');
    return HijriSyncResult(
      success: true,
      message:
          'Synced via $usedSource · Pakistan date: $onlineDay/$onlineMonth AH ($adjLabel)',
      adjustmentDays: adjustment,
    );
  }

  static String _isoDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
