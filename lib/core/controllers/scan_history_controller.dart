import 'package:get/get.dart';
import 'package:dio/dio.dart';
import '../../config/config.dart';

class ScanHistoryController extends GetxController {
  final Dio _dio = Dio();
  final history = <Map<String, dynamic>>[].obs;
  final isLoading = false.obs;
  final page = 1.obs;
  final hasMore = true.obs;

  /// Index of the currently expanded item (for dropdown control)
  final expandedIndex = RxnInt();

  Future<void> fetchHistory(String firebaseUid, {bool loadMore = false}) async {
    if (isLoading.value || (!hasMore.value && loadMore)) return;

    isLoading.value = true;
    try {
      print("📥 [ScanHistoryController] Fetching scan history for UID: $firebaseUid, page ${page.value}");

      final response = await _dio.get(
        '${AppConfig.scanHistoryEndpoint}/$firebaseUid',
        queryParameters: {
          'page': page.value,
          'limit': 20,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data is Map<String, dynamic> && response.data.containsKey('history')
            ? response.data['history'] as List
            : response.data as List;

        if (loadMore) {
          history.addAll(data.cast<Map<String, dynamic>>());
        } else {
          history.assignAll(data.cast<Map<String, dynamic>>());
        }

        if (data.length < 20) {
          hasMore.value = false;
        } else {
          page.value++;
        }

        print("✅ [ScanHistoryController] Loaded ${data.length} scans (total: ${history.length})");
      } else {
        print("❌ [ScanHistoryController] Server responded with ${response.statusCode}");
      }
    } catch (e) {
      print('❌ Error fetching history: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void toggleExpanded(int index) {
    if (expandedIndex.value == index) {
      expandedIndex.value = null;
    } else {
      expandedIndex.value = index;
    }
  }

  /// Deletes a scan history item from the backend (Neon)
  Future<void> deleteHistoryItem(Map<String, dynamic> item, String firebaseUid) async {
    try {
      final String? barcode = item['product']?['barcode'];

      if (barcode == null || barcode.isEmpty) {
        print('⚠️ Missing barcode for scan history item, cannot delete.');
        return;
      }

      print('🗑️ Deleting scan history item from backend: $barcode for UID: $firebaseUid');

      final response = await _dio.delete(
        '${AppConfig.scanHistoryEndpoint}/$firebaseUid/$barcode',
      );

      if (response.statusCode == 200) {
        print('✅ Successfully deleted scan history item: $barcode');
      } else {
        print('❌ Failed to delete scan history item. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error deleting scan history item: $e');
    }
  }
}
