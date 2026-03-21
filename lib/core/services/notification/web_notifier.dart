import 'dart:js_interop';

import 'package:flutter/foundation.dart';
import 'package:web/web.dart' as web;
import 'package:ummaly/core/services/notification/notification_dispatcher.dart';

/// Web notification implementation using the browser Notification API.
///
/// Uses [dart:js_interop] and [package:web] for type-safe JS interop.
/// Scheduling is not supported on web — the periodic timer in
/// [PrayerNotificationService] handles delivery timing instead.
class WebNotifier implements Notifier {
  @override
  Future<void> init() async {
    debugPrint('[WebNotifier] Initialised');
  }

  @override
  Future<bool> requestPermission() async {
    try {
      final permission = web.Notification.permission;

      if (permission == 'granted') return true;
      if (permission == 'denied') return false;

      // Request permission from the user
      final result = await web.Notification.requestPermission().toDart;
      return result.toDart == 'granted';
    } catch (e) {
      debugPrint('[WebNotifier] requestPermission error: $e');
      return false;
    }
  }

  @override
  Future<void> showNow({
    required int id,
    required String title,
    required String body,
  }) async {
    try {
      if (web.Notification.permission != 'granted') {
        debugPrint('[WebNotifier] Permission not granted, skipping');
        return;
      }

      final options = web.NotificationOptions(
        body: body,
        icon: '/icons/Icon-192.png',
        tag: 'prayer_$id', // Replaces existing with same tag
      );

      web.Notification(title, options);

      debugPrint('[WebNotifier] Shown: $title');
    } catch (e) {
      debugPrint('[WebNotifier] showNow error: $e');
    }
  }

  @override
  Future<void> schedule({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    // Web doesn't support scheduled notifications.
    // The periodic timer in PrayerNotificationService handles timing.
    debugPrint(
        '[WebNotifier] Schedule not supported on web — using timer fallback');
  }

  @override
  Future<void> cancelAll() async {
    // Web notifications auto-dismiss; nothing to cancel.
    debugPrint('[WebNotifier] cancelAll (no-op on web)');
  }
}
