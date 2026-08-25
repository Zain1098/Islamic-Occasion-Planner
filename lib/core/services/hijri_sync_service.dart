import 'dart:convert';
import 'dart:io';

import '../../features/settings/data/settings_repository.dart';
import '../services/date_service.dart';
import '../providers/planner_data_refresh.dart';

class HijriSyncResult {
  const HijriSyncResult({
    required this.success,
    required this.message,
    this.adjustmentDays,
    this.onlineHijriDay,
    this.onlineHijriMonth,
  });

  final bool success;
  final String message;
  final int? adjustmentDays;
  final int? onlineHijriDay;
  final int? onlineHijriMonth;
}

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
    final todayIso =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    if (!force && settings.lastHijriSyncIso == todayIso) {
      return HijriSyncResult(
        success: true,
        message: 'Already synced today.',
        adjustmentDays: settings.hijriAdjustmentDays,
      );
    }

    try {
      final formattedDate =
          '${today.day.toString().padLeft(2, '0')}-${today.month.toString().padLeft(2, '0')}-${today.year}';
      
      // Try Pakistan location-based endpoint first, then gToH endpoint
      var url = Uri.parse(
          'https://api.aladhan.com/v1/timingsByCity/$formattedDate?city=Karachi&country=Pakistan');

      var request =
          await _client.getUrl(url).timeout(const Duration(seconds: 8));
      var response =
          await request.close().timeout(const Duration(seconds: 8));

      if (response.statusCode != 200) {
        // Fallback to standard gToH endpoint
        url = Uri.parse('https://api.aladhan.com/v1/gToH/$formattedDate');
        request =
            await _client.getUrl(url).timeout(const Duration(seconds: 8));
        response =
            await request.close().timeout(const Duration(seconds: 8));
      }

      if (response.statusCode != 200) {
        return HijriSyncResult(
          success: false,
          message: 'API returned status ${response.statusCode}',
        );
      }

      final responseBody = await response.transform(utf8.decoder).join();
      final json = jsonDecode(responseBody) as Map<String, dynamic>;

      if (json['code'] != 200 || json['data'] == null) {
        return const HijriSyncResult(
          success: false,
          message: 'Invalid response from online calendar server.',
        );
      }

      Map<String, dynamic> hijriData;
      if (json['data'] is Map &&
          json['data']['date'] != null &&
          json['data']['date']['hijri'] != null) {
        hijriData = json['data']['date']['hijri'] as Map<String, dynamic>;
      } else if (json['data'] is Map && json['data']['hijri'] != null) {
        hijriData = json['data']['hijri'] as Map<String, dynamic>;
      } else {
        return const HijriSyncResult(
          success: false,
          message: 'Hijri date structure missing in response.',
        );
      }

      final onlineDay = int.parse(hijriData['day'].toString());
      final onlineMonth =
          int.parse((hijriData['month'] as Map<String, dynamic>)['number'].toString());

      final localZeroAdjHijri =
          _dateService.hijriDateFor(today, adjustmentDays: 0);

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

      return HijriSyncResult(
        success: true,
        message:
            'Synced successfully for Pakistan (Adjustment: ${adjustment >= 0 ? '+$adjustment' : adjustment} day)',
        adjustmentDays: adjustment,
        onlineHijriDay: onlineDay,
        onlineHijriMonth: onlineMonth,
      );
    } catch (e) {
      return HijriSyncResult(
        success: false,
        message: 'Network offline. Using local calculation.',
      );
    }
  }
}
