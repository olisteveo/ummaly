import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = "http://10.0.2.2:5000"; // Android emulator

  static Future<Map<String, dynamic>?> scanBarcode(String barcode) async {
    final url = Uri.parse('$baseUrl/scan');

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
