import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:ummaly/config/config.dart';

/// Service for creating/deleting/getting product flags.
class ProductFlagService {
  final String baseUrl;
  final FirebaseAuth _auth;

  ProductFlagService({
    String? baseUrl,
    FirebaseAuth? auth,
  })  : baseUrl = baseUrl ?? Config.apiBaseUrl,
        _auth = auth ?? FirebaseAuth.instance;

  Future<String> _idToken() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('Not authenticated');
    }
    // In some firebase_auth versions this returns Future<String?>.
    final token = await user.getIdToken();
    if (token == null || token.isEmpty) {
      throw StateError('Failed to obtain ID token');
    }
    return token;
  }

  Map<String, String> _headers(String token) => {
    'Authorization': 'Bearer $token',
    'Content-Type': 'application/json',
  };

  Future<Map<String, dynamic>> createFlagByBarcode({
    required String barcode,
    required String reason,
  }) async {
    final token = await _idToken();
    final uri = Uri.parse('$baseUrl/api/barcodes/$barcode/flags');
    final res = await http.post(
      uri,
      headers: _headers(token),
      body: jsonEncode({'reason': reason}),
    );
    if (res.statusCode == 201) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    throw StateError('Failed to flag: ${res.statusCode} ${res.body}');
  }

  Future<Map<String, dynamic>> createFlagByProductId({
    required int productId,
    required String reason,
  }) async {
    final token = await _idToken();
    final uri = Uri.parse('$baseUrl/api/products/$productId/flags');
    final res = await http.post(
      uri,
      headers: _headers(token),
      body: jsonEncode({'reason': reason}),
    );
    if (res.statusCode == 201) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    throw StateError('Failed to flag: ${res.statusCode} ${res.body}');
  }

  Future<Map<String, dynamic>?> getMyFlag({required int productId}) async {
    final token = await _idToken();
    final uri = Uri.parse('$baseUrl/api/products/$productId/flags/me');
    final res = await http.get(uri, headers: _headers(token));
    if (res.statusCode == 200) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    throw StateError('Failed to fetch my flag: ${res.statusCode} ${res.body}');
  }

  Future<void> deleteMyFlag({required int productId}) async {
    final token = await _idToken();
    final uri = Uri.parse('$baseUrl/api/products/$productId/flags/me');
    final res = await http.delete(uri, headers: _headers(token));
    if (res.statusCode == 200 || res.statusCode == 404) return;
    throw StateError('Failed to delete flag: ${res.statusCode} ${res.body}');
  }

  Future<Map<String, dynamic>> getSummary({required int productId}) async {
    final uri = Uri.parse('$baseUrl/api/products/$productId/flags/summary');
    final res = await http.get(uri);
    if (res.statusCode == 200) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    throw StateError('Failed to fetch summary: ${res.statusCode} ${res.body}');
  }
}
