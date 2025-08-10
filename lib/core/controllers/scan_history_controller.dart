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

  static const int _limit = 20;

  /// Fetch history; set [loadMore]=true for next page.
  Future<void> fetchHistory(String firebaseUid, {bool loadMore = false}) async {
    if (isLoading.value || (!hasMore.value && loadMore)) return;

    // Reset pagination when not loading more
    if (!loadMore) {
      page.value = 1;
      hasMore.value = true;
    }

    isLoading.value = true;
    try {
      final response = await _dio.get(
        '${AppConfig.scanHistoryEndpoint}/$firebaseUid',
        queryParameters: {'page': page.value, 'limit': _limit},
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

        // Pagination bookkeeping
        if (data.length < _limit) {
          hasMore.value = false;
        } else {
          page.value++;
        }
      } else {
        // server error
        // ignore: avoid_print
        print('❌ [ScanHistoryController] Server responded with ${response.statusCode}');
      }
    } catch (e) {
      // ignore: avoid_print
      print('❌ Error fetching history: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Convenience refresh: resets pagination and loads first page
  Future<void> refreshHistory(String firebaseUid) async {
    page.value = 1;
    hasMore.value = true;
    await fetchHistory(firebaseUid, loadMore: false);
  }

  void toggleExpanded(int index) {
    if (expandedIndex.value == index) {
      expandedIndex.value = null;
    } else {
      expandedIndex.value = index;
    }
  }

  /// Deletes all scans for a specific product (by barcode)
  Future<void> deleteHistoryItem(Map<String, dynamic> item, String firebaseUid) async {
    try {
      final String? barcode = item['product']?['barcode'];
      if (barcode == null || barcode.isEmpty) {
        // ignore: avoid_print
        print('⚠️ Missing barcode for scan history item, cannot delete.');
        return;
      }

      final response = await _dio.delete(
        '${AppConfig.scanHistoryEndpoint}/$firebaseUid/$barcode',
      );

      if (response.statusCode == 200) {
        // ignore: avoid_print
        print('✅ Deleted scan history for barcode: $barcode');
      } else {
        // ignore: avoid_print
        print('❌ Failed to delete scan history item. Status code: ${response.statusCode}');
      }
    } catch (e) {
      // ignore: avoid_print
      print('❌ Error deleting scan history item: $e');
    }
  }

  /// Bulk delete ALL history for the user (new backend endpoint)
  Future<int?> deleteAllHistory(String firebaseUid) async {
    try {
      final response = await _dio.delete(
        '${AppConfig.scanHistoryEndpoint}/$firebaseUid',
      );

      if (response.statusCode == 200) {
        final deletedCount = (response.data is Map<String, dynamic>)
            ? response.data['deletedCount'] as int?
            : null;

        history.clear();
        hasMore.value = false;
        page.value = 1;
        expandedIndex.value = null;

        return deletedCount ?? 0;
      } else {
        // ignore: avoid_print
        print('❌ Failed to delete all history. Status code: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      // ignore: avoid_print
      print('❌ Error deleting all history: $e');
      return null;
    }
  }
}
