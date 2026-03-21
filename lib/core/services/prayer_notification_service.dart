import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ummaly/core/services/prayer_time_service.dart';
import 'package:ummaly/core/services/notification/notification_dispatcher.dart';

/// Manages prayer notification preferences and scheduling.
///
/// Persists user settings (enabled, minutes-before, per-prayer toggles) via
/// SharedPreferences. Delegates actual notification delivery to
/// [NotificationDispatcher] which handles platform differences.
///
/// Usage:
///   await PrayerNotificationService.instance.init();
///   await PrayerNotificationService.instance.setEnabled(true);
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

  /// The 5 daily fard prayers (Sunrise excluded).
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

  /// Tracks which notifications we've already shown this minute
  /// to prevent duplicates from the periodic timer.
  final Set<String> _shownThisMinute = {};

  // ── Initialisation ──

  /// Load preferences and initialise the notification dispatcher.
  /// Call once at app startup (safe to call multiple times).
  Future<void> load() async {
    if (_loaded) return;
    try {
      await NotificationDispatcher.instance.init();

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

  // ── Public API ──

  /// Enable or disable prayer notifications globally.
  ///
  /// Requests notification permission from the OS when enabling.
  /// The preference is saved regardless of permission outcome — on web
  /// the browser may block permission (especially in incognito), but the
  /// scheduler still runs so notifications fire once permission is granted.
  /// The [WebNotifier.showNow] and [MobileNotifier.showNow] already guard
  /// against missing permission at delivery time.
  Future<void> setEnabled(bool value) async {
    if (value) {
      // Request permission — non-blocking: we save the preference either way
      final granted = await NotificationDispatcher.instance.requestPermission();
      if (!granted) {
        debugPrint('[PrayerNotif] Permission not yet granted — '
            'saving preference, will deliver when allowed');
      }
    }

    _enabled = value;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyEnabled, value);

    if (value) {
      _startScheduler();
    } else {
      _stopScheduler();
      await NotificationDispatcher.instance.cancelAll();
    }
  }

  /// Set how many minutes before each prayer to send the notification.
  Future<void> setMinutesBefore(int minutes) async {
    _minutesBefore = minutes;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyMinutesBefore, minutes);

    if (_enabled) {
      await _rescheduleAll();
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
      await _rescheduleAll();
    }
  }

  // ── Scheduling ──

  void _startScheduler() {
    _stopScheduler();
    _rescheduleAll();
    // Check every 30 seconds for web (which can't schedule future notifications)
    // and as a safety net for mobile.
    _schedulerTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _checkAndNotify(),
    );
  }

  void _stopScheduler() {
    _schedulerTimer?.cancel();
    _schedulerTimer = null;
  }

  /// Cancel all existing notifications and reschedule for remaining prayers.
  Future<void> _rescheduleAll() async {
    if (!_enabled) return;

    await NotificationDispatcher.instance.cancelAll();

    final prayerService = PrayerTimeService.instance;
    if (prayerService.times.isEmpty) return;

    final now = DateTime.now();

    for (final prayer in prayerService.times) {
      if (prayer.name == 'Sunrise') continue;
      if (!isPrayerEnabled(prayer.name)) continue;

      final prayerTime = _parsePrayerTime(prayer.time, now);
      if (prayerTime == null) continue;

      final notifyTime =
          prayerTime.subtract(Duration(minutes: _minutesBefore));

      if (notifyTime.isAfter(now)) {
        await NotificationDispatcher.instance.schedule(
          id: prayer.name.hashCode,
          title: '${prayer.arabic}  ${prayer.name} Prayer',
          body: '${prayer.name} is in $_minutesBefore minutes — time to prepare',
          scheduledTime: notifyTime,
        );
      }
    }
  }

  /// Periodic check — primarily for web where scheduled notifications
  /// aren't supported. Also acts as a safety net on mobile.
  void _checkAndNotify() {
    if (!_enabled) return;

    final prayerService = PrayerTimeService.instance;
    if (prayerService.times.isEmpty) return;

    final now = DateTime.now();
    // Reset shown set each new minute
    final minuteKey = '${now.hour}:${now.minute}';
    if (_shownThisMinute.isNotEmpty &&
        !_shownThisMinute.any((k) => k.startsWith(minuteKey))) {
      _shownThisMinute.clear();
    }

    for (final prayer in prayerService.times) {
      if (prayer.name == 'Sunrise') continue;
      if (!isPrayerEnabled(prayer.name)) continue;

      final prayerTime = _parsePrayerTime(prayer.time, now);
      if (prayerTime == null) continue;

      final notifyTime =
          prayerTime.subtract(Duration(minutes: _minutesBefore));

      final diff = now.difference(notifyTime).inSeconds;
      final dedupKey = '$minuteKey:${prayer.name}';

      // Fire if we're within the 60-second window and haven't shown yet
      if (diff >= 0 && diff < 60 && !_shownThisMinute.contains(dedupKey)) {
        _shownThisMinute.add(dedupKey);
        NotificationDispatcher.instance.showNow(
          id: prayer.name.hashCode,
          title: '${prayer.arabic}  ${prayer.name} Prayer',
          body: '${prayer.name} is in $_minutesBefore minutes — time to prepare',
        );
      }
    }
  }

  // ── Helpers ──

  /// Parse "HH:mm" string into a DateTime for today.
  DateTime? _parsePrayerTime(String timeStr, DateTime today) {
    final parts = timeStr.split(':');
    if (parts.length < 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute =
        int.tryParse(parts[1].replaceAll(RegExp(r'[^0-9]'), ''));
    if (hour == null || minute == null) return null;
    return DateTime(today.year, today.month, today.day, hour, minute);
  }

  @override
  void dispose() {
    _stopScheduler();
    super.dispose();
  }
}
