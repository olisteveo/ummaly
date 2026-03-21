import 'package:ummaly/core/services/notification/notification_dispatcher.dart';
import 'package:ummaly/core/services/notification/web_notifier.dart';

/// Web factory — returns [WebNotifier] for browser environments.
Notifier createNotifier() => WebNotifier();
