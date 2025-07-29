import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../config/config.dart'; // ✅ Import AppConfig for dynamic baseUrl

class ApiService {
  /// Scans a barcode by sending it to the backend.
  /// Returns the product map if found, otherwise `null`.
  static Future<Map<String, dynamic>?> scanBarcode(String barcode) async {
    final url = Uri.parse(AppConfig.scanEndpoint); // ✅ Uses AppConfig

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"barcode": barcode}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['product'];
      } else {
        print('❌ API error: ${response.statusCode} ${response.body}');
        return null;
      }
    } catch (e) {
      print('❌ Exception calling backend: $e');
      return null;
    }
  }
}
