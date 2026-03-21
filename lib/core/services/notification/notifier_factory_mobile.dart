import 'package:ummaly/core/services/notification/notification_dispatcher.dart';
import 'package:ummaly/core/services/notification/mobile_notifier.dart';

/// Mobile factory — returns [MobileNotifier] for iOS/Android.
Notifier createNotifier() => MobileNotifier();
