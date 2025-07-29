import 'dart:io';

class AppConfig {
  // 🔀 Toggle this ON (true) when testing via USB with adb reverse
  // 🔀 Leave it OFF (false) when testing over Wi‑Fi
  static const bool useUsbDebugging = false;

  // ✅ IPs for different scenarios
  static const String _adbReverseIp = "10.0.2.2"; // Android emulator/USB via adb reverse
  static const String _wifiIp = "192.168.0.3";    // Your laptop’s Wi‑Fi IP

  // ✅ Base URL logic – handles USB & Wi-Fi seamlessly
  static String get baseUrl {
    if (Platform.isAndroid) {
      // 👇 If USB debugging toggle is ON, use adb reverse IP
      return useUsbDebugging
          ? "http://$_adbReverseIp:5000"
          : "http://$_wifiIp:5000";
    } else {
      // 🍏 iOS simulator or real device on Wi-Fi
      return "http://$_wifiIp:5000";
    }
  }

  // 👇 Centralised API endpoints
  static String get scanEndpoint => "$baseUrl/scan";
  static String get authEndpoint => "$baseUrl/auth";
  static String get pingEndpoint => "$baseUrl/ping";
}
