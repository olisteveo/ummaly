import 'dart:io';

class AppConfig {
  // 🔀 Toggle this ON (true) when testing via USB with adb reverse
  // 🔀 Leave it OFF (false) when testing over Wi‑Fi
  static const bool useUsbDebugging = false;

  // ✅ Ngrok URL (always accessible from any Wi-Fi or mobile data)
  static const String _ngrokUrl = "https://51e93d6d394f.ngrok-free.app";

  // ✅ IPs for local testing (optional fallback if Ngrok is off)
  static const String _adbReverseIp = "10.0.2.2"; // Android emulator/USB via adb reverse
  static const String _wifiIp = "192.168.0.3";    // Your laptop’s Wi‑Fi IP

  // ✅ Base URL logic – defaults to Ngrok unless you explicitly want local
  static String get baseUrl {
    // ✅ Always use Ngrok by default for global access
    return _ngrokUrl;

    // 👉 If you ever want to switch back to local for debugging, comment the above line
    // and uncomment below:
    /*
    if (Platform.isAndroid) {
      return useUsbDebugging
          ? "http://$_adbReverseIp:5000"
          : "http://$_wifiIp:5000";
    } else {
      return "http://$_wifiIp:5000";
    }
    */
  }

  // Centralised API endpoints (✅ updated to include /api prefix)
  static String get scanEndpoint => "$baseUrl/api/scan";
  static String get authEndpoint => "$baseUrl/api/auth";
  static String get pingEndpoint => "$baseUrl/api/ping";
}
