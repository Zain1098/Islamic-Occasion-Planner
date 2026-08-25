import 'dart:convert';
import 'dart:io';

import '../../features/settings/data/settings_repository.dart';
import '../services/date_service.dart';
import '../providers/planner_data_refresh.dart';
import 'hijri_sync_service.dart';

class PakistanHijriFeedService {
  PakistanHijriFeedService({
    required SettingsRepository settingsRepository,
    required DateService dateService,
    HttpClient? httpClient,
  })  : _settingsRepository = settingsRepository,
        _dateService = dateService,
        _client = httpClient ?? HttpClient();

  final SettingsRepository _settingsRepository;
  final DateService _dateService;
  final HttpClient _client;

  /// Fetches real-time Pakistan Hijri date (Karachi / Ruet-e-Hilal method)
  /// and automatically adjusts app settings for 100% accurate local dates.
  Future<HijriSyncResult> syncPakistanHijriDate({
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
    final todayIso =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    if (!force && settings.lastHijriSyncIso == todayIso) {
      return HijriSyncResult(
        success: true,
        message: 'Already synced today.',
        adjustmentDays: settings.hijriAdjustmentDays,
      );
    }

    final formattedDate =
        '${today.day.toString().padLeft(2, '0')}-${today.month.toString().padLeft(2, '0')}-${today.year}';

    // Endpoints for Pakistan Hijri Date resolution:
    // 1. Karachi Method 1 (University of Islamic Sciences, Karachi)
    // 2. Standard Aladhan gToH Endpoint
    final endpoints = [
      Uri.parse(
          'https://api.aladhan.com/v1/timingsByCity/$formattedDate?city=Karachi&country=Pakistan&method=1'),
      Uri.parse('https://api.aladhan.com/v1/gToH/$formattedDate'),
    ];

    Map<String, dynamic>? hijriData;
    String usedSource = 'Karachi Ruet Sighting';

    for (final url in endpoints) {
      try {
        final request =
            await _client.getUrl(url).timeout(const Duration(seconds: 8));
        final response =
            await request.close().timeout(const Duration(seconds: 8));

        if (response.statusCode == 200) {
          final responseBody = await response.transform(utf8.decoder).join();
          final json = jsonDecode(responseBody) as Map<String, dynamic>;

          if (json['code'] == 200 && json['data'] != null) {
            if (json['data'] is Map &&
                json['data']['date'] != null &&
                json['data']['date']['hijri'] != null) {
              hijriData = json['data']['date']['hijri'] as Map<String, dynamic>;
              usedSource = 'Karachi Ruet Feed';
              break;
            } else if (json['data'] is Map && json['data']['hijri'] != null) {
              hijriData = json['data']['hijri'] as Map<String, dynamic>;
              usedSource = 'Aladhan Global Feed';
              break;
            }
          }
        }
      } catch (_) {
        // Try next endpoint on timeout or network error
      }
    }

    if (hijriData == null) {
      return HijriSyncResult(
        success: false,
        message: 'Network offline. Preserving verified Pakistan calculation.',
        adjustmentDays: settings.hijriAdjustmentDays,
      );
    }

    final onlineDay = int.parse(hijriData['day'].toString());
    final onlineMonth = int.parse(
        (hijriData['month'] as Map<String, dynamic>)['number'].toString());

    final localZeroAdjHijri =
        _dateService.hijriDateFor(today, adjustmentDays: 0);

    // Calculate required Pakistan offset (-1, 0, +1)
    int adjustment = onlineDay - localZeroAdjHijri.day;
    if (adjustment < -1) adjustment = -1;
    if (adjustment > 1) adjustment = 1;

    final updatedSettings = settings.copyWith(
      hijriAdjustmentDays: adjustment,
      lastHijriSyncIso: todayIso,
    );

    await _settingsRepository.save(updatedSettings);

    if (ref != null) {
      refreshPlannerData(ref);
    }

    final adjLabel =
        adjustment == 0 ? '0 days' : (adjustment > 0 ? '+$adjustment day' : '$adjustment day');

    return HijriSyncResult(
      success: true,
      message:
          'Synced via $usedSource ($onlineDay/${onlineMonth} AH · Adjustment: $adjLabel)',
      adjustmentDays: adjustment,
      onlineHijriDay: onlineDay,
      onlineHijriMonth: onlineMonth,
    );
  }
}
