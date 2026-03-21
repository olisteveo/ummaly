import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:ummaly/core/services/notification/notification_dispatcher.dart';

/// Mobile (iOS/Android) notification implementation using
/// [flutter_local_notifications] v21+.
///
/// Supports both immediate and scheduled notifications.
/// Handles platform-specific initialisation (Android channel, iOS permissions).
class MobileNotifier implements Notifier {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  /// Android notification details using the prayer channel.
  static const _androidDetails = AndroidNotificationDetails(
    'prayer_reminders',
    'Prayer Reminders',
    channelDescription: 'Notifications before prayer times',
    importance: Importance.high,
    priority: Priority.high,
    playSound: true,
    icon: '@mipmap/ic_launcher',
  );

  /// iOS/macOS notification details.
  static const _iosDetails = DarwinNotificationDetails(
    presentAlert: true,
    presentBadge: true,
    presentSound: true,
  );

  /// Combined platform details.
  static const _notificationDetails = NotificationDetails(
    android: _androidDetails,
    iOS: _iosDetails,
  );

  @override
  Future<void> init() async {
    // Initialise timezone data for scheduled notifications
    tz.initializeTimeZones();

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false, // We request manually
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    await _plugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // Create the Android notification channel
    final androidPlugin =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          'prayer_reminders',
          'Prayer Reminders',
          description: 'Notifications before prayer times',
          importance: Importance.high,
        ),
      );
    }

    debugPrint('[MobileNotifier] Initialised');
  }

  @override
  Future<bool> requestPermission() async {
    // Android 13+ requires explicit permission
    final androidPlugin =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      final granted = await androidPlugin.requestNotificationsPermission();
      return granted ?? false;
    }

    // iOS
    final iosPlugin =
        _plugin.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
    if (iosPlugin != null) {
      final granted = await iosPlugin.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }

    return true; // Assume granted on older Android
  }

  @override
  Future<void> showNow({
    required int id,
    required String title,
    required String body,
  }) async {
    try {
      await _plugin.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: _notificationDetails,
      );
    } catch (e) {
      debugPrint('[MobileNotifier] showNow error: $e');
    }
  }

  @override
  Future<void> schedule({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    try {
      final tzTime = tz.TZDateTime.from(scheduledTime, tz.local);

      await _plugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: tzTime,
        notificationDetails: _notificationDetails,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: null, // One-shot, not repeating
      );

      debugPrint('[MobileNotifier] Scheduled #$id at $tzTime');
    } catch (e) {
      debugPrint('[MobileNotifier] schedule error: $e');
    }
  }

  @override
  Future<void> cancelAll() async {
    await _plugin.cancelAll();
    debugPrint('[MobileNotifier] Cancelled all');
  }

  /// Handle notification tap — could navigate to prayer screen in future.
  static void _onNotificationTap(NotificationResponse response) {
    debugPrint(
        '[MobileNotifier] Tapped notification: ${response.payload}');
  }
}
