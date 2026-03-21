import 'package:ummaly/core/services/notification/notifier_factory.dart'
    if (dart.library.js_interop) 'package:ummaly/core/services/notification/notifier_factory_web.dart'
    if (dart.library.io) 'package:ummaly/core/services/notification/notifier_factory_mobile.dart';

/// Platform-agnostic notification dispatcher.
///
/// Delegates to [MobileNotifier] on iOS/Android and [WebNotifier] on web.
/// Uses Dart conditional imports to avoid compiling platform-specific code
/// on the wrong target (e.g. flutter_local_notifications on web).
///
/// All notification logic goes through this single entry point, keeping
/// the rest of the app platform-unaware.
///
/// Usage:
///   await NotificationDispatcher.instance.init();
///   await NotificationDispatcher.instance.requestPermission();
///   await NotificationDispatcher.instance.showNow(...);
///   await NotificationDispatcher.instance.schedule(...);
class NotificationDispatcher {
  static final NotificationDispatcher _instance = NotificationDispatcher._();
  static NotificationDispatcher get instance => _instance;
  NotificationDispatcher._();

  late final Notifier _notifier;
  bool _initialised = false;

  /// Initialise the platform-specific notification backend.
  /// Safe to call multiple times — only runs once.
  Future<void> init() async {
    if (_initialised) return;

    _notifier = createNotifier();
    await _notifier.init();
    _initialised = true;
  }

  /// Request notification permission from the OS / browser.
  /// Returns true if permission was granted.
  Future<bool> requestPermission() async {
    _ensureInit();
    return _notifier.requestPermission();
  }

  /// Show a notification immediately.
  Future<void> showNow({
    required int id,
    required String title,
    required String body,
  }) async {
    _ensureInit();
    await _notifier.showNow(id: id, title: title, body: body);
  }

  /// Schedule a notification for a future time.
  /// On web this is a no-op — the periodic timer in
  /// [PrayerNotificationService] handles web delivery.
  Future<void> schedule({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    _ensureInit();
    await _notifier.schedule(
      id: id,
      title: title,
      body: body,
      scheduledTime: scheduledTime,
    );
  }

  /// Cancel all pending/scheduled notifications.
  Future<void> cancelAll() async {
    _ensureInit();
    await _notifier.cancelAll();
  }

  void _ensureInit() {
    assert(_initialised, 'NotificationDispatcher.init() must be called first');
  }
}

/// Interface for platform-specific notification implementations.
///
/// Implemented by [MobileNotifier] and [WebNotifier].
abstract class Notifier {
  /// Initialise the notification backend.
  Future<void> init();

  /// Request notification permission. Returns true if granted.
  Future<bool> requestPermission();

  /// Show a notification immediately.
  Future<void> showNow({
    required int id,
    required String title,
    required String body,
  });

  /// Schedule a notification for a future time.
  Future<void> schedule({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
  });

  /// Cancel all pending/scheduled notifications.
  Future<void> cancelAll();
}
