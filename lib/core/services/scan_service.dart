import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;

import '../../config/config.dart';
import '../models/product.dart';

/// ✅ Handles communication with the backend for barcode scans.
/// Features:
/// - Debounces requests (prevents spamming backend if user waves scanner)
/// - Sends Firebase UID (if logged in) and optional location data
/// - Returns a `Product` model or null on failure
class ScanService {
  static Timer? _debounce;

  /// ✅ Send a scanned barcode to the backend
  /// [barcode] – The scanned code
  /// [firebaseUid] – Optional Firebase UID for user tracking
  /// [location] – Optional location string
  Future<Product?> scanProduct(
      String barcode, {
        String? firebaseUid,
        String? location,
      }) async {
    // ✅ Cancel any ongoing debounce timer to avoid duplicate requests
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    final completer = Completer<Product?>();

    _debounce = Timer(const Duration(milliseconds: 500), () async {
      try {
        print(
            "📤 [ScanService] Sending barcode [$barcode] to backend: ${AppConfig.scanEndpoint}");

        // ✅ Build request payload dynamically
        final Map<String, dynamic> requestBody = {
          'barcode': barcode,
          if (firebaseUid != null) 'firebase_uid': firebaseUid,
          if (location != null) 'location': location,
        };

        // ✅ Make HTTP POST request
        final response = await http.post(
          Uri.parse(AppConfig.scanEndpoint),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(requestBody),
        );

        // ✅ Handle backend response
        if (response.statusCode == 200) {
          final Map<String, dynamic> data = jsonDecode(response.body);

          if (data.containsKey('product') && data['product'] != null) {
            final productData = data['product'];
            print("✅ [ScanService] Product found: ${productData['name']}");
            completer.complete(Product.fromJson(productData));
          } else {
            print("⚠️ [ScanService] No product key in response");
            completer.complete(null);
          }
        } else {
          print(
              "❌ [ScanService] Backend error: ${response.statusCode} - ${response.body}");
          completer.complete(null);
        }
      } catch (e) {
        print("🚨 [ScanService] Exception during scan: $e");
        completer.complete(null);
      }
    });

    return completer.future;
  }
}
