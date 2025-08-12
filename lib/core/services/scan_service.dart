import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;

import '../../config/config.dart';
import '../models/product.dart';

class ScanService {
  static Timer? _debounce;
  final Map<String, Product> _cache = {};

  static bool _backendChecked = false;
  static bool _backendOk = false;

  // --------- sanitizer ----------
  List<String> _sanitizeIngredientsDynamic(dynamic raw) {
    if (raw == null) return const [];
    List<String> list;
    if (raw is String) {
      // split on ; or newline or commas not inside [...]
      list = raw.split(RegExp(r'[;\n]+|,(?![^\[]*\])')).map((e) => e.trim()).toList();
    } else if (raw is List) {
      list = raw.map((e) => e?.toString() ?? '').toList();
    } else {
      list = [raw.toString()];
    }

    final phoneOrContact = RegExp(r'\b(tel|telephone|phone|freephone|fax|email|mail|contact)\b', caseSensitive: false);
    final urlLike         = RegExp(r'https?://|www\.', caseSensitive: false);
    final atSymbol        = RegExp(r'@');
    final poOrFreepost    = RegExp(r'\bpo\.?\s*box\b|\bfreepost\b', caseSensitive: false);
    final ukPostcode      = RegExp(r'\b([A-Z]{1,2}\d[A-Z\d]?\s?\d[A-Z]{2})\b', caseSensitive: false);
    final longDigits      = RegExp(r'(?:\d[\s\-]?){7,}');
    final addressWords    = RegExp(
      r'\b(street|st\.|road|rd\.|avenue|ave\.|lane|ln\.|drive|dr\.|city|town|county|postcode|zip|eircode|'
      r'leicestershire|ashby(?:-|\s)de(?:-|\s)la(?:-|\s)zouch|united kingdom|uk|republic of ireland|roi)\b',
      caseSensitive: false,
    );
    final regTm           = RegExp(r'registered|trade\s*mark|™|®', caseSensitive: false);
    final onlyPunct       = RegExp(r'^[\s,.;:()\-–—]*$');

    final cleaned = <String>[];
    for (final rawItem in list) {
      final s = rawItem.trim();
      if (s.isEmpty) continue;
      if (onlyPunct.hasMatch(s)) continue;
      if (ukPostcode.hasMatch(s)) continue;
      if (longDigits.hasMatch(s)) continue;
      if (phoneOrContact.hasMatch(s)) continue;
      if (urlLike.hasMatch(s)) continue;
      if (atSymbol.hasMatch(s)) continue;
      if (poOrFreepost.hasMatch(s)) continue;

      final commaCount = ','.allMatches(s).length;
      final words = s.split(RegExp(r'\s+')).length;

      if (addressWords.hasMatch(s)) {
        // treat likely addressy lines as non-ingredients
        if (commaCount >= 1 || words <= 5 || regTm.hasMatch(s)) continue;
      }
      if (regTm.hasMatch(s)) continue;
      if (s.toLowerCase() == 'uk' || s.toLowerCase() == 'roi') continue;

      cleaned.add(s);
    }
    // de-dupe (case insensitive)
    final seen = <String>{};
    return cleaned.where((e) => seen.add(e.toLowerCase())).toList();
  }

  void _applySanitizedFields(Map<String, dynamic> productData, List<String> cleanList) {
    final cleanText = cleanList.join(', ');

    // write to BOTH snake_case and camelCase so any widget/model sees the same thing
    productData['ingredients_list_sanitized'] = cleanList;
    productData['ingredientsListSanitized']   = cleanList;

    productData['ingredients_list'] = cleanList;
    productData['ingredientsList']  = cleanList;

    productData['ingredients_text'] = cleanText;
    productData['ingredientsText']  = cleanText;

    // keep ingredients as String for backward compat
    productData['ingredients']      = cleanText;
  }
  // --------------------------------

  Uri _normalizeUrl(String raw, {String fallbackPath = '/api/status'}) {
    String s = raw.trim();
    final u = Uri.tryParse(s);
    if (u != null && (u.hasScheme && u.host.isNotEmpty)) return u;
    if (s.startsWith('//')) s = 'https:$s';
    if (!s.startsWith('http://') && !s.startsWith('https://')) {
      final parts = s.split('/');
      final host = parts.first;
      final path = parts.length > 1 ? '/${parts.sublist(1).join('/')}' : '';
      return Uri.https(host, path.isEmpty ? fallbackPath : path);
    }
    return Uri.parse(s);
  }

  String _statusUrlFromScan() {
    final scanUri = _normalizeUrl(AppConfig.scanEndpoint, fallbackPath: '/api/scan');
    return scanUri.replace(path: scanUri.path.replaceFirst('/api/scan', '/api/status')).toString();
  }

  Future<bool> _ensureBackendReachable() async {
    if (_backendChecked) return _backendOk;
    _backendChecked = true;

    final statusUrl = _statusUrlFromScan();
    try {
      final res = await http
          .get(Uri.parse(statusUrl), headers: {'X-Ummaly-Client': 'mobile'})
          .timeout(const Duration(seconds: 2));
      _backendOk = res.statusCode == 200;
      print('[ScanService] Backend check ${_backendOk ? "OK" : "FAILED"} at $statusUrl');
    } catch (e) {
      _backendOk = false;
      print('[ScanService] Backend check error for $statusUrl: $e');
      print('[ScanService] TIP: Use a full URL like https://<ngrok>.ngrok-free.app');
    }
    return _backendOk;
  }

  Future<Product?> scanProduct(
      String barcode, {
        String? firebaseUid,
        String? location,
      }) async {
    if (_cache.containsKey(barcode)) {
      print("[ScanService] Returning cached product for [$barcode]");
      return _cache[barcode];
    }

    if (_debounce?.isActive ?? false) _debounce!.cancel();
    final completer = Completer<Product?>();

    _debounce = Timer(const Duration(milliseconds: 500), () async {
      try {
        await _ensureBackendReachable();

        final uri = _normalizeUrl(AppConfig.scanEndpoint, fallbackPath: '/api/scan');
        print("[ScanService] Sending barcode [$barcode] to backend: $uri");

        final payload = {
          'barcode': barcode,
          if (firebaseUid != null) 'firebase_uid': firebaseUid,
          if (location != null) 'location': location,
        };

        final response = await http
            .post(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'X-Ummaly-Client': 'mobile',
          },
          body: jsonEncode(payload),
        )
            .timeout(const Duration(seconds: 8));

        if (response.statusCode == 200) {
          final Map<String, dynamic> data = jsonDecode(response.body);
          if (data.containsKey('product') && data['product'] != null) {
            final productData = Map<String, dynamic>.from(data['product']);

            final rawList = productData['ingredients_list'] ??
                productData['ingredientsList'] ??
                productData['ingredients'] ??
                productData['ingredientsText'];

            final cleanList = _sanitizeIngredientsDynamic(rawList);
            _applySanitizedFields(productData, cleanList);

            print("[ScanService] Product found: ${productData['name']}");
            final product = Product.fromJson(productData);

            _cache[barcode] = product;
            completer.complete(product);
          } else {
            print("[ScanService] No product key in response");
            completer.complete(null);
          }
        } else {
          print("[ScanService] Backend error: ${response.statusCode} - ${response.body}");
          completer.complete(null);
        }
      } catch (e) {
        print("[ScanService] Exception during scan: $e");
        completer.complete(null);
      }
    });

    return completer.future;
  }

  void clearCache() {
    _cache.clear();
    print("[ScanService] Cache cleared");
  }
}
