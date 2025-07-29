import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../../config/config.dart'; // ✅ fixed path
import '../models/product.dart';

class ScanService {
  static Timer? _debounce;

  Future<Product?> scanProduct(String barcode) async {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    final completer = Completer<Product?>();

    _debounce = Timer(const Duration(milliseconds: 500), () async {
      try {
        print("📤 [ScanService] Sending barcode $barcode to backend (${AppConfig.scanEndpoint})...");

        final response = await http.post(
          Uri.parse(AppConfig.scanEndpoint),
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
