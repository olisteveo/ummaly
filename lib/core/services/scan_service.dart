import 'dart:convert';
import 'dart:io'; // ✅ For platform check
import 'dart:async'; // ✅ For debounce
import 'package:http/http.dart' as http;
import '../models/product.dart';

class ScanService {
  static String get baseUrl {
    if (Platform.isAndroid) {
      // ✅ Use localhost since adb reverse forwards device traffic to laptop’s localhost
      return "http://localhost:5000";
    } else {
      // ✅ Emulator still needs 10.0.2.2 to reach host machine
      return "http://10.0.2.2:5000";
    }
  }

  /// ✅ Debounce timer (to prevent multiple scans firing instantly)
  static Timer? _debounce;

  /// ✅ Debounced scanProduct function
  Future<Product?> scanProduct(String barcode) async {
    // Cancel any pending debounce timers if another scan is requested quickly
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    // Completer lets us return a Future after debounce
    final completer = Completer<Product?>();

    _debounce = Timer(const Duration(milliseconds: 500), () async {
      try {
        print("📤 [ScanService] Sending barcode $barcode to backend...");
        final response = await http.post(
          Uri.parse('$baseUrl/scan'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'barcode': barcode}),
        );

        if (response.statusCode == 200) {
          final Map<String, dynamic> data = jsonDecode(response.body);
          final productData = data['product'];
          print("✅ [ScanService] Product found: ${productData['name']}");
          completer.complete(Product.fromJson(productData));
        } else {
          print("❌ [ScanService] Failed: ${response.statusCode}");
          completer.complete(null);
        }
      } catch (e) {
        print("⚠️ [ScanService] Error: $e");
        completer.complete(null);
      }
    });

    return completer.future;
  }
}
