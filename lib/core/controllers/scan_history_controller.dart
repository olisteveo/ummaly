import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../config/config.dart';

/// Scan history controller using ChangeNotifier (consistent with rest of app).
class ScanHistoryController extends ChangeNotifier {
  final Dio _dio = Dio();

  final List<Map<String, dynamic>> history = [];
  bool isLoading = false;
  int _page = 1;
  bool hasMore = true;
  int? expandedIndex;

  static const int _limit = 20;

  /// Get Firebase auth token for secure API calls
  Future<String?> _getAuthToken() async {
    return FirebaseAuth.instance.currentUser?.getIdToken();
  }

  /// Build auth + client headers
  Future<Options> _authHeaders() async {
    final token = await _getAuthToken();
    return Options(headers: {
      'X-Ummaly-Client': 'mobile',
      if (token != null) 'Authorization': 'Bearer $token',
    });
  }

  /// Fetch scan history using secure /me endpoint (UID from auth token)
  Future<void> fetchHistory(String firebaseUid, {bool loadMore = false}) async {
    if (isLoading || (!hasMore && loadMore)) return;

    if (!loadMore) {
      _page = 1;
      hasMore = true;
    }

    isLoading = true;
    notifyListeners();

    try {
      final url = '${AppConfig.scanHistoryEndpoint}/me';
      if (kDebugMode) debugPrint('[ScanHistory] GET $url?page=$_page&limit=$_limit');

      final response = await _dio.get(
        url,
        queryParameters: {'page': _page, 'limit': _limit},
        options: await _authHeaders(),
      );

      if (response.statusCode == 200) {
        List data;
        final body = response.data;

        if (body is Map<String, dynamic>) {
          if (body['items'] is List)        data = body['items'] as List;
          else if (body['history'] is List) data = body['history'] as List;
          else if (body['data'] is List)    data = body['data'] as List;
          else                              data = const [];
        } else if (body is List) {
          data = body;
        } else {
          data = const [];
        }

        if (loadMore) {
          history.addAll(data.cast<Map<String, dynamic>>());
        } else {
          history
            ..clear()
            ..addAll(data.cast<Map<String, dynamic>>());
        }

        if (data.length < _limit) {
          hasMore = false;
        } else {
          _page++;
        }
      } else {
        if (kDebugMode) debugPrint('[ScanHistory] Server responded with ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[ScanHistory] Error fetching: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshHistory(String firebaseUid) async {
    _page = 1;
    hasMore = true;
    await fetchHistory(firebaseUid, loadMore: false);
  }

  void toggleExpanded(int index) {
    expandedIndex = (expandedIndex == index) ? null : index;
    notifyListeners();
  }

  /// Delete a single scan history item by barcode
  Future<void> deleteHistoryItem(Map<String, dynamic> item, String firebaseUid) async {
    try {
      final String? barcode = item['product']?['barcode'] ?? item['barcode'];
      if (barcode == null || barcode.isEmpty) {
        if (kDebugMode) debugPrint('[ScanHistory] Missing barcode, cannot delete');
        return;
      }

      final url = '${AppConfig.scanHistoryEndpoint}/me/$barcode';
      if (kDebugMode) debugPrint('[ScanHistory] DELETE $url');

      final response = await _dio.delete(
        url,
        options: await _authHeaders(),
      );

      if (response.statusCode == 200) {
        final idx = history.indexWhere(
              (h) => (h['product']?['barcode'] ?? h['barcode']) == barcode,
        );
        if (idx >= 0) {
          history.removeAt(idx);
          notifyListeners();
        }
        if (kDebugMode) debugPrint('[ScanHistory] Deleted barcode: $barcode');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[ScanHistory] Error deleting item: $e');
    }
  }

  /// Delete all scan history
  Future<int?> deleteAllHistory(String firebaseUid) async {
    try {
      final url = '${AppConfig.scanHistoryEndpoint}/me';
      if (kDebugMode) debugPrint('[ScanHistory] DELETE $url (all)');

      final response = await _dio.delete(
        url,
        options: await _authHeaders(),
      );

      if (response.statusCode == 200) {
        final body = response.data;
        final deletedCount = (body is Map<String, dynamic>)
            ? body['deletedCount'] as int?
            : null;

        history.clear();
        hasMore = false;
        _page = 1;
        expandedIndex = null;
        notifyListeners();

        return deletedCount ?? 0;
      } else {
        if (kDebugMode) debugPrint('[ScanHistory] Failed to delete all: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[ScanHistory] Error deleting all: $e');
      return null;
    }
  }
}
