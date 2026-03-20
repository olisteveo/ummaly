import 'package:shared_preferences/shared_preferences.dart';

/// Manages guest mode state and scan limits.
/// Free users get 5 scans, then must subscribe (£3/month).
class GuestService {
  static const int maxFreeScans = 5;
  static const String _scanCountKey = 'guest_scan_count';

  static Future<int> getScanCount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_scanCountKey) ?? 0;
  }

  static Future<int> incrementScanCount() async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getInt(_scanCountKey) ?? 0;
    final next = current + 1;
    await prefs.setInt(_scanCountKey, next);
    return next;
  }

  static Future<bool> canScan() async {
    final count = await getScanCount();
    return count < maxFreeScans;
  }

  static int remainingScans(int currentCount) {
    return (maxFreeScans - currentCount).clamp(0, maxFreeScans);
  }
}
