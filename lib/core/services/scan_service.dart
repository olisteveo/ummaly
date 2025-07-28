import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/product.dart';

class ScanService {
  static const String baseUrl = 'http://YOUR_BACKEND_URL:PORT'; // 👈 update this

  Future<Product?> scanProduct(String barcode) async {
    final response = await http.post(
      Uri.parse('$baseUrl/scan'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'barcode': barcode}),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      final productData = data['product']; // ✅ backend sends product: {...}
      return Product.fromJson(productData);
    } else {
      print('❌ Failed to scan product: ${response.statusCode}');
      return null;
    }
  }
}
