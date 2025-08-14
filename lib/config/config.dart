import 'dart:io';

/// Central app networking configuration.
/// Chooses an API base URL in this order:
/// 1) --dart-define=API_BASE=... (with or without scheme)
/// 2) _ngrokUrl if set
/// 3) Local network fallback (Android emulator uses 10.0.2.2)
class AppConfig {
  static const bool useUsbDebugging = false; // set true if using `adb reverse tcp:5000 tcp:5000`
  static const String _adbReverseIp = "10.0.2.2"; // Android emulator loopback to host
  static const String _wifiIp = "192.168.0.3";    // your local machine IP on Wi-Fi/LAN

  // Can be just the host; _ensureScheme() will add https:// automatically.
  static const String _ngrokUrl = "https://3155139239a4.ngrok-free.app";

  // flutter run --dart-define=API_BASE=https://my-api.example.com
  static const String _apiBaseOverride =
  String.fromEnvironment('API_BASE', defaultValue: "");

  static bool _hasScheme(String v) =>
      v.startsWith('http://') || v.startsWith('https://');

  static String _ensureScheme(String v) => _hasScheme(v) ? v : 'https://$v';

  static String _stripTrailingSlash(String v) =>
      v.endsWith('/') ? v.substring(0, v.length - 1) : v;

  /// Always returns a URL with scheme and no trailing slash.
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
        ? (useUsbDebugging
        ? "http://$_adbReverseIp:5000"
        : "http://$_wifiIp:5000")
        : "http://$_wifiIp:5000";
    return _stripTrailingSlash(local);
  }

  // Backwards/alternative name some files may use.
  static String get apiBaseUrl => baseUrl;

  // Core endpoints
  static String get scanEndpoint        => "$baseUrl/api/scan";
  static String get authEndpoint        => "$baseUrl/api/auth";
  static String get pingEndpoint        => "$baseUrl/api/ping";
  static String get scanHistoryEndpoint => "$baseUrl/api/scan-history";

  // Product flagging endpoints (strings)
  static String productFlagsByProduct(int productId) =>
      "$baseUrl/api/products/$productId/flags";
  static String productFlagsMe(int productId) =>
      "$baseUrl/api/products/$productId/flags/me";
  static String productFlagsSummary(int productId) =>
      "$baseUrl/api/products/$productId/flags/summary";
  static String productFlagsByBarcode(String barcode) =>
      "$baseUrl/api/barcodes/$barcode/flags";

  // Product flagging endpoints (Uri helpers) – convenient for http package.
  static Uri productFlagsByProductUri(int productId) =>
      Uri.parse(productFlagsByProduct(productId));
  static Uri productFlagsMeUri(int productId) =>
      Uri.parse(productFlagsMe(productId));
  static Uri productFlagsSummaryUri(int productId) =>
      Uri.parse(productFlagsSummary(productId));
  static Uri productFlagsByBarcodeUri(String barcode) =>
      Uri.parse(productFlagsByBarcode(barcode));
}

/// Lightweight alias for legacy/import convenience.
/// Some files import `Config.*`; keep in sync with AppConfig.
class Config {
  static String get baseUrl             => AppConfig.baseUrl;
  static String get apiBaseUrl          => AppConfig.apiBaseUrl;
  static String get scanHistoryEndpoint => AppConfig.scanHistoryEndpoint;

  // Expose flag endpoints here too (handy for services/widgets using Config)
  static String productFlagsByProduct(int productId) =>
      AppConfig.productFlagsByProduct(productId);
  static String productFlagsMe(int productId) =>
      AppConfig.productFlagsMe(productId);
  static String productFlagsSummary(int productId) =>
      AppConfig.productFlagsSummary(productId);
  static String productFlagsByBarcode(String barcode) =>
      AppConfig.productFlagsByBarcode(barcode);

  static Uri productFlagsByProductUri(int productId) =>
      AppConfig.productFlagsByProductUri(productId);
  static Uri productFlagsMeUri(int productId) =>
      AppConfig.productFlagsMeUri(productId);
  static Uri productFlagsSummaryUri(int productId) =>
      AppConfig.productFlagsSummaryUri(productId);
  static Uri productFlagsByBarcodeUri(String barcode) =>
      AppConfig.productFlagsByBarcodeUri(barcode);
}
