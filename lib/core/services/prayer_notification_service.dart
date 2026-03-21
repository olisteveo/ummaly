import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ummaly/core/services/prayer_time_service.dart';

/// Manages prayer notification preferences and scheduling.
///
/// Persists user settings (enabled, minutes-before, per-prayer toggles) via
/// SharedPreferences. On mobile, integrates with flutter_local_notifications
/// (added separately). On web, uses the browser Notification API.
///
/// Usage:
///   await PrayerNotificationService.instance.load();
///   await PrayerNotificationService.instance.setEnabled(true);
///   PrayerNotificationService.instance.scheduleNotifications();
class PrayerNotificationService extends ChangeNotifier {
  static final PrayerNotificationService _instance =
      PrayerNotificationService._();
  static PrayerNotificationService get instance => _instance;
  PrayerNotificationService._();

  // ── Prefs keys ──
  static const _keyEnabled = 'prayer_notif_enabled';
  static const _keyMinutesBefore = 'prayer_notif_minutes_before';
  static const _keyPrayerPrefix = 'prayer_notif_prayer_';

  // ── State ──
  bool _enabled = false;
  bool get enabled => _enabled;

  int _minutesBefore = 10;
  int get minutesBefore => _minutesBefore;

  /// The 5 daily prayers (Sunrise excluded — it's not a fard prayer).
  final List<String> prayerNames = const [
    'Fajr',
    'Dhuhr',
    'Asr',
    'Maghrib',
    'Isha',
  ];

  /// Per-prayer enabled state. Defaults to all enabled.
  final Map<String, bool> _prayerToggles = {};

  bool _loaded = false;
  Timer? _schedulerTimer;

  // ── Load / Save ──

  /// Load preferences from disk. Call once at startup or when settings screen opens.
  Future<void> load() async {
    if (_loaded) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      _enabled = prefs.getBool(_keyEnabled) ?? false;
      _minutesBefore = prefs.getInt(_keyMinutesBefore) ?? 10;

      for (final name in prayerNames) {
        _prayerToggles[name] =
            prefs.getBool('$_keyPrayerPrefix${name.toLowerCase()}') ?? true;
      }
      _loaded = true;

      if (_enabled) {
        _startScheduler();
      }
    } catch (e) {
      debugPrint('[PrayerNotificationService] load error: $e');
    }
  }

  /// Enable or disable prayer notifications globally.
  Future<void> setEnabled(bool value) async {
    _enabled = value;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyEnabled, value);

    if (value) {
      _startScheduler();
    } else {
      _stopScheduler();
      _cancelAllNotifications();
    }
  }

  /// Set how many minutes before each prayer to send the notification.
  Future<void> setMinutesBefore(int minutes) async {
    _minutesBefore = minutes;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyMinutesBefore, minutes);

    if (_enabled) {
      scheduleNotifications();
    }
  }

  /// Check if a specific prayer is enabled for notifications.
  bool isPrayerEnabled(String name) => _prayerToggles[name] ?? true;

  /// Toggle a specific prayer's notification on/off.
  Future<void> setPrayerEnabled(String name, bool value) async {
    _prayerToggles[name] = value;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_keyPrayerPrefix${name.toLowerCase()}', value);

    if (_enabled) {
      scheduleNotifications();
    }
  }

  // ── Scheduling ──

  /// Start a periodic timer that checks and reschedules notifications.
  /// Runs every minute to handle day transitions and prayer time updates.
  void _startScheduler() {
    _stopScheduler();
    scheduleNotifications(); // schedule immediately
    _schedulerTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => _checkAndNotify(),
    );
  }

  void _stopScheduler() {
    _schedulerTimer?.cancel();
    _schedulerTimer = null;
  }

  /// Schedule notifications for today's remaining prayers.
  void scheduleNotifications() {
    if (!_enabled) return;

    final prayerService = PrayerTimeService.instance;
    if (prayerService.times.isEmpty) return;

    // Cancel existing notifications before rescheduling
    _cancelAllNotifications();

    final now = DateTime.now();

    for (final prayer in prayerService.times) {
      // Skip Sunrise — not a fard prayer
      if (prayer.name == 'Sunrise') continue;

      // Skip if this prayer is disabled
      if (!isPrayerEnabled(prayer.name)) continue;

      // Parse prayer time
      final parts = prayer.time.split(':');
      if (parts.length < 2) continue;
      final hour = int.tryParse(parts[0]) ?? 0;
      final minute =
          int.tryParse(parts[1].replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

      final prayerTime = DateTime(now.year, now.month, now.day, hour, minute);
      final notifyTime =
          prayerTime.subtract(Duration(minutes: _minutesBefore));

      // Only schedule if the notification time is still in the future
      if (notifyTime.isAfter(now)) {
        _scheduleSingleNotification(prayer.name, prayer.arabic, notifyTime);
      }
    }
  }

  /// Check if it's time to show a notification right now.
  void _checkAndNotify() {
    if (!_enabled) return;

    final prayerService = PrayerTimeService.instance;
    if (prayerService.times.isEmpty) return;

    final now = DateTime.now();

    for (final prayer in prayerService.times) {
      if (prayer.name == 'Sunrise') continue;
      if (!isPrayerEnabled(prayer.name)) continue;

      final parts = prayer.time.split(':');
      if (parts.length < 2) continue;
      final hour = int.tryParse(parts[0]) ?? 0;
      final minute =
          int.tryParse(parts[1].replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

      final prayerTime = DateTime(now.year, now.month, now.day, hour, minute);
      final notifyTime =
          prayerTime.subtract(Duration(minutes: _minutesBefore));

      // Check if we're within the notification minute window
      final diff = now.difference(notifyTime).inSeconds;
      if (diff >= 0 && diff < 60) {
        _showImmediateNotification(prayer.name, prayer.arabic, _minutesBefore);
      }
    }
  }

  // ── Platform-specific notification methods ──
  // These are stubs that will be wired to actual notification APIs.

  void _scheduleSingleNotification(
      String prayerName, String arabic, DateTime when) {
    // TODO: On mobile — use flutter_local_notifications to schedule
    // a local notification at [when].
    //
    // On web — the _checkAndNotify timer handles this since web doesn't
    // support scheduling future notifications.
    debugPrint(
        '[PrayerNotif] Scheduled: $prayerName ($arabic) at $when');
  }

  void _showImmediateNotification(
      String prayerName, String arabic, int minutesBefore) {
    if (kIsWeb) {
      _showWebNotification(prayerName, arabic, minutesBefore);
    } else {
      _showMobileNotification(prayerName, arabic, minutesBefore);
    }
  }

  void _showWebNotification(
      String prayerName, String arabic, int minutesBefore) {
    // Web Notification API is called via JS interop.
    // For now, log it. Full implementation requires dart:js_interop.
    debugPrint(
        '[PrayerNotif] WEB: $prayerName in $minutesBefore minutes');
    // TODO: Implement using dart:js_interop:
    // js.context.callMethod('Notification', [
    //   'Ummaly — $prayerName Prayer',
    //   js.JsObject.jsify({
    //     'body': '$arabic — $prayerName is in $minutesBefore minutes',
    //     'icon': '/icons/Icon-192.png',
    //   }),
    // ]);
  }

  void _showMobileNotification(
      String prayerName, String arabic, int minutesBefore) {
    // TODO: Implement using flutter_local_notifications:
    // final plugin = FlutterLocalNotificationsPlugin();
    // plugin.show(
    //   prayerName.hashCode,
    //   'Ummaly — $prayerName Prayer',
    //   '$arabic — $prayerName is in $minutesBefore minutes',
    //   notificationDetails,
    // );
    debugPrint(
        '[PrayerNotif] MOBILE: $prayerName in $minutesBefore minutes');
  }

  void _cancelAllNotifications() {
    // TODO: On mobile — call FlutterLocalNotificationsPlugin().cancelAll()
    debugPrint('[PrayerNotif] Cancelled all notifications');
  }

  @override
  void dispose() {
    _stopScheduler();
    super.dispose();
  }
}
