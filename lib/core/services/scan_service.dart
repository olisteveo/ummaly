import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../config/config.dart';
import '../models/product.dart';
import 'ocr_service.dart';

class ScanService {
  // Singleton
  static final ScanService _instance = ScanService._internal();
  factory ScanService({http.Client? client, OcrService? ocr}) {
    if (client != null) _instance._client = client;
    if (ocr != null) _instance._ocr = ocr;
    return _instance;
  }
  ScanService._internal();

  http.Client _client = http.Client();
  OcrService _ocr = OcrService();

  // Backend reachability with TTL
  DateTime? _lastBackendCheck;
  bool _backendOk = false;
  static const _backendCheckTtl = Duration(seconds: 60);

  // Product cache with TTL
  final Map<String, _CachedProduct> _cache = {};
  static const _cacheTtl = Duration(minutes: 5);

  // Scan lock to prevent concurrent scans
  bool _isScanning = false;

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

  String _ocrUrlFromScan() {
    final scanUri = _normalizeUrl(AppConfig.scanEndpoint, fallbackPath: '/api/scan');
    return scanUri.replace(path: scanUri.path.replaceFirst('/api/scan', '/api/scan/ocr-text')).toString();
  }

  Future<bool> _ensureBackendReachable() async {
    // Re-check if TTL expired or never checked
    if (_lastBackendCheck != null &&
        DateTime.now().difference(_lastBackendCheck!) < _backendCheckTtl &&
        _backendOk) {
      return true;
    }

    final statusUrl = _statusUrlFromScan();
    try {
      final res = await _client
          .get(Uri.parse(statusUrl), headers: {'X-Ummaly-Client': 'mobile'})
          .timeout(const Duration(seconds: 2));
      _backendOk = res.statusCode == 200;
    } catch (e) {
      _backendOk = false;
      if (kDebugMode) debugPrint('[ScanService] Backend check error: $e');
    }
    _lastBackendCheck = DateTime.now();
    if (kDebugMode) debugPrint('[ScanService] Backend ${_backendOk ? "OK" : "UNREACHABLE"}');
    return _backendOk;
  }

  Future<Map<String, dynamic>> _scanCall({
    required String barcode,
    String? firebaseUid,
    String? location,
  }) async {
    final uri = _normalizeUrl(AppConfig.scanEndpoint, fallbackPath: '/api/scan');
    final payload = {
      'barcode': barcode,
      if (firebaseUid != null) 'firebase_uid': firebaseUid,
      if (location != null) 'location': location,
    };

    final response = await _client
        .post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'X-Ummaly-Client': 'mobile',
      },
      body: jsonEncode(payload),
    )
        .timeout(const Duration(seconds: 12));

    final Map<String, dynamic> data = jsonDecode(response.body.isEmpty ? '{}' : response.body);
    if (response.statusCode >= 400) {
      throw ScanException(
        data['error']?.toString() ?? 'Scan failed (${response.statusCode})',
        statusCode: response.statusCode,
      );
    }
    return data;
  }

  /// Submit OCR text and receive full product analysis (no second call needed).
  Future<Map<String, dynamic>> _submitOcrText({
    required String barcode,
    required String text,
    String? firebaseUid,
    String? location,
  }) async {
    final uri = Uri.parse(_ocrUrlFromScan());
    final payload = {
      'barcode': barcode,
      'text': text,
      if (firebaseUid != null) 'firebase_uid': firebaseUid,
      if (location != null) 'location': location,
    };
    final r = await _client
        .post(
      uri,
      headers: {'Content-Type': 'application/json', 'X-Ummaly-Client': 'mobile'},
      body: jsonEncode(payload),
    )
        .timeout(const Duration(seconds: 12));
    final data = jsonDecode(r.body.isEmpty ? '{}' : r.body) as Map<String, dynamic>;
    if (r.statusCode >= 400) {
      throw ScanException(
        data['error']?.toString() ?? 'OCR submit failed (${r.statusCode})',
        statusCode: r.statusCode,
      );
    }
    return data;
  }

  /// Main scan entry point with phase callbacks for UI feedback.
  Future<Product?> scanProduct(
      String barcode, {
        String? firebaseUid,
        String? location,
        void Function(String title, {String? subtitle, int? step, int? total})? onPhase,
      }) async {
    // Check cache (with TTL)
    final cached = _cache[barcode];
    if (cached != null && !cached.isExpired) {
      if (kDebugMode) debugPrint('[ScanService] Cache hit for [$barcode]');
      return cached.product;
    }

    // Prevent concurrent scans
    if (_isScanning) {
      if (kDebugMode) debugPrint('[ScanService] Scan already in progress, ignoring');
      return null;
    }
    _isScanning = true;

    try {
      final reachable = await _ensureBackendReachable();
      if (!reachable) {
        throw ScanException('Cannot reach Ummaly servers. Check your connection.');
      }

      onPhase?.call('Fetching product data…', step: 1, total: 4);

      if (kDebugMode) debugPrint('[ScanService] Scanning [$barcode]');

      // 1) First attempt (OFF path on backend)
      Map<String, dynamic> data = await _scanCall(
        barcode: barcode,
        firebaseUid: firebaseUid,
        location: location,
      );

      // 2) OCR fallback if backend needs photo
      if (data['status'] == 'needs_photo') {
        onPhase?.call(
          'Reading label…',
          subtitle: 'Point camera at the ingredients panel',
          step: 2,
          total: 4,
        );

        if (kDebugMode) debugPrint('[ScanService] Backend requested OCR');
        final text = await _ocr.captureAndRecognize();
        if (text == null || text.trim().length < 5) {
          if (kDebugMode) debugPrint('[ScanService] OCR cancelled or empty');
          return null;
        }

        onPhase?.call('Analyzing ingredients…', step: 3, total: 4);

        // OCR endpoint now runs halal analysis and returns full product
        data = await _submitOcrText(
          barcode: barcode,
          text: text.trim(),
          firebaseUid: firebaseUid,
          location: location,
        );
      } else {
        onPhase?.call('Analyzing ingredients…', step: 3, total: 4);
      }

      if (data.containsKey('product') && data['product'] != null) {
        final productData = Map<String, dynamic>.from(data['product']);

        if (kDebugMode) debugPrint('[ScanService] Product: ${productData['name']}');
        final product = Product.fromJson(productData);

        _cache[barcode] = _CachedProduct(product);
        return product;
      } else {
        if (kDebugMode) debugPrint('[ScanService] No product in response');
        return null;
      }
    } finally {
      _isScanning = false;
    }
  }

  void clearCache() {
    _cache.clear();
    if (kDebugMode) debugPrint('[ScanService] Cache cleared');
  }

  /// Force re-check backend on next scan
  void resetBackendCheck() {
    _lastBackendCheck = null;
    _backendOk = false;
  }
}

/// Cache entry with TTL
class _CachedProduct {
  final Product product;
  final DateTime cachedAt;

  _CachedProduct(this.product) : cachedAt = DateTime.now();

  bool get isExpired =>
      DateTime.now().difference(cachedAt) > ScanService._cacheTtl;
}

/// Typed exception for scan errors
class ScanException implements Exception {
  final String message;
  final int? statusCode;

  ScanException(this.message, {this.statusCode});

  @override
  String toString() => message;
}
