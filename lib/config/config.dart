import 'dart:io';

class AppConfig {
  static const bool useUsbDebugging = false;
  static const String _adbReverseIp = "10.0.2.2";
  static const String _wifiIp = "192.168.0.3";

  // Can be just the host; we’ll add https:// automatically.
  static const String _ngrokUrl = "https://908f84068097.ngrok-free.app";

  // flutter run --dart-define=API_BASE=...
  static const String _apiBaseOverride =
  String.fromEnvironment('API_BASE', defaultValue: "");

  static bool _hasScheme(String v) =>
      v.startsWith('http://') || v.startsWith('https://');

  static String _ensureScheme(String v) =>
      _hasScheme(v) ? v : 'https://$v';

  static String _stripTrailingSlash(String v) =>
      v.endsWith('/') ? v.substring(0, v.length - 1) : v;

  // Always returns a URL with scheme and no trailing slash
  static String get baseUrl {
    if (_apiBaseOverride.isNotEmpty) {
      final withScheme = _ensureScheme(_apiBaseOverride.trim());
      return _stripTrailingSlash(withScheme);
    }
    if (_ngrokUrl.isNotEmpty) {
      final withScheme = _ensureScheme(_ngrokUrl.trim());
      return _stripTrailingSlash(withScheme);
    }
    final local = Platform.isAndroid
        ? (useUsbDebugging ? "http://$_adbReverseIp:5000" : "http://$_wifiIp:5000")
        : "http://$_wifiIp:5000";
    return _stripTrailingSlash(local);
  }

  static String get scanEndpoint        => "$baseUrl/api/scan";
  static String get authEndpoint        => "$baseUrl/api/auth";
  static String get pingEndpoint        => "$baseUrl/api/ping";
  static String get scanHistoryEndpoint => "$baseUrl/api/scan-history";
}
