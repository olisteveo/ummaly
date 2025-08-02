import 'package:get/get.dart';
import 'package:dio/dio.dart';
import '../../config/config.dart';  // ✅ NEW import for AppConfig

class ScanHistoryController extends GetxController {
  final Dio _dio = Dio();
  final history = <Map<String, dynamic>>[].obs;
  final isLoading = false.obs;
  final page = 1.obs;
  final hasMore = true.obs;

  Future<void> fetchHistory(String firebaseUid, {bool loadMore = false}) async {
    if (isLoading.value || (!hasMore.value && loadMore)) return;

    isLoading.value = true;
    try {
      print("📥 [ScanHistoryController] Fetching scan history for UID: $firebaseUid, page ${page.value}");

      // ✅ Use AppConfig instead of hardcoded URL
      final response = await _dio.get(
        '${AppConfig.scanHistoryEndpoint}/$firebaseUid',
        queryParameters: {
          'page': page.value,
          'limit': 20,
        },
      );

      if (response.statusCode == 200) {
        // ✅ Adjust this based on backend response structure
        final data = response.data is Map<String, dynamic> && response.data.containsKey('history')
            ? response.data['history'] as List
            : response.data as List;

        if (loadMore) {
          history.addAll(data.cast<Map<String, dynamic>>());
        } else {
          history.assignAll(data.cast<Map<String, dynamic>>());
        }

        // ✅ Pagination check — if fewer than 20, no more pages
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
}
