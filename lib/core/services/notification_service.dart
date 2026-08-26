import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  final ValueNotifier<String?> tappedEventId = ValueNotifier<String?>(null);
  bool _initialized = false;

  Future<void> initialize() async {
    tz.initializeTimeZones();
    try {
      final deviceZone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(deviceZone.identifier));
    } catch (_) {
      // UTC remains a safe fallback if a device cannot provide its IANA zone.
    }
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    );
    await _plugin.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: (response) {
        if (response.payload?.isNotEmpty ?? false) {
          tappedEventId.value = response.payload;
        }
      },
    );
    final launchDetails = await _plugin.getNotificationAppLaunchDetails();
    if (launchDetails?.didNotificationLaunchApp ?? false) {
      final payload = launchDetails?.notificationResponse?.payload;
      if (payload?.isNotEmpty ?? false) tappedEventId.value = payload;
    }
    _initialized = true;
  }

  Future<bool> requestPermission() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    return await android?.requestNotificationsPermission() ?? true;
  }

  Future<void> schedule({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledAt,
    required String eventId,
  }) async {
    if (!_initialized) return;
    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: tz.TZDateTime.from(scheduledAt, tz.local),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'occasion_reminders',
          'Occasion reminders',
          channelDescription: 'Planning reminders for upcoming occasions',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: eventId,
    );
  }

  /// Schedules a real inexact Android alarm so users can verify permission,
  /// channel delivery and launcher behavior without changing their plans.
  Future<void> scheduleTestReminder() async {
    const testId = 990001;
    await cancel(testId);
    await schedule(
      id: testId,
      title: 'Noor reminder test',
      body: 'Your Android reminder was scheduled successfully.',
      scheduledAt: DateTime.now().add(const Duration(minutes: 1)),
      eventId: '',
    );
  }

  Future<void> cancel(int id) async {
    if (_initialized) await _plugin.cancel(id: id);
  }
}
