import 'package:get/get.dart';
import 'package:dio/dio.dart';
import '../../config/config.dart';

class ScanHistoryController extends GetxController {
  final Dio _dio = Dio();

  final history = <Map<String, dynamic>>[].obs;
  final isLoading = false.obs;
  final page = 1.obs;
  final hasMore = true.obs;

  final expandedIndex = RxnInt();
  static const int _limit = 20;

  // ---------- sanitizer ----------
  List<String> _sanitizeIngredientsDynamic(dynamic raw) {
    if (raw == null) return const [];
    List<String> list;
    if (raw is String) {
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
        if (commaCount >= 1 || words <= 5 || regTm.hasMatch(s)) continue;
      }
      if (regTm.hasMatch(s)) continue;
      if (s.toLowerCase() == 'uk' || s.toLowerCase() == 'roi') continue;

      cleaned.add(s);
    }
    final seen = <String>{};
    return cleaned.where((e) => seen.add(e.toLowerCase())).toList();
  }

  void _applySanitizedFields(Map<String, dynamic> prod, List<String> cleanList) {
    final cleanText = cleanList.join(', ');

    prod['ingredients_list_sanitized'] = cleanList;
    prod['ingredientsListSanitized']   = cleanList;

    prod['ingredients_list'] = cleanList;
    prod['ingredientsList']  = cleanList;

    prod['ingredients_text'] = cleanText;
    prod['ingredientsText']  = cleanText;

    prod['ingredients']      = cleanText; // keep String for existing widgets
  }
  // --------------------------------

  void _applySanitizerToHistoryList(List items) {
    for (final it in items) {
      if (it is! Map<String, dynamic>) continue;
      final prod = (it['product'] is Map<String, dynamic>)
          ? it['product'] as Map<String, dynamic>
          : it;

      final rawList = prod['ingredients_list'] ??
          prod['ingredientsList'] ??
          prod['ingredients'] ??
          prod['ingredientsText'];

      final cleanList = _sanitizeIngredientsDynamic(rawList);
      _applySanitizedFields(prod, cleanList);
    }
  }

  Future<void> fetchHistory(String firebaseUid, {bool loadMore = false}) async {
    if (isLoading.value || (!hasMore.value && loadMore)) return;

    if (!loadMore) {
      page.value = 1;
      hasMore.value = true;
    }

    isLoading.value = true;
    try {
      final url = '${AppConfig.scanHistoryEndpoint}/$firebaseUid';
      print('[ScanHistory] GET $url?page=${page.value}&limit=$_limit');

      final response = await _dio.get(
        url,
        queryParameters: {'page': page.value, 'limit': _limit},
        options: Options(headers: {'X-Ummaly-Client': 'mobile'}),
      );

      if (response.statusCode == 200) {
        List data;
        final body = response.data;

        if (body is Map<String, dynamic>) {
          if (body['items'] is List)      data = body['items'] as List;
          else if (body['history'] is List) data = body['history'] as List;
          else if (body['data'] is List)    data = body['data'] as List;
          else                               data = const [];
        } else if (body is List) {
          data = body;
        } else {
          data = const [];
        }

        _applySanitizerToHistoryList(data);

        if (loadMore) {
          history.addAll(data.cast<Map<String, dynamic>>());
        } else {
          history.assignAll(data.cast<Map<String, dynamic>>());
        }

        if (data.length < _limit) {
          hasMore.value = false;
        } else {
          page.value++;
        }
      } else {
        print('❌ [ScanHistoryController] Server responded with ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error fetching history: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refreshHistory(String firebaseUid) async {
    page.value = 1;
    hasMore.value = true;
    await fetchHistory(firebaseUid, loadMore: false);
  }

  void toggleExpanded(int index) {
    expandedIndex.value = (expandedIndex.value == index) ? null : index;
  }

  Future<void> deleteHistoryItem(Map<String, dynamic> item, String firebaseUid) async {
    try {
      final String? barcode = item['product']?['barcode'] ?? item['barcode'];
      if (barcode == null || barcode.isEmpty) {
        print('⚠️ Missing barcode for scan history item, cannot delete.');
        return;
      }

      final url = '${AppConfig.scanHistoryEndpoint}/$firebaseUid/$barcode';
      print('[ScanHistory] DELETE $url');

      final response = await _dio.delete(
        url,
        options: Options(headers: {'X-Ummaly-Client': 'mobile'}),
      );

      if (response.statusCode == 200) {
        final idx = history.indexWhere(
              (h) => (h['product']?['barcode'] ?? h['barcode']) == barcode,
        );
        if (idx >= 0) history.removeAt(idx);
        print('✅ Deleted scan history for barcode: $barcode');
      } else {
        print('❌ Failed to delete scan history item. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error deleting scan history item: $e');
    }
  }

  Future<int?> deleteAllHistory(String firebaseUid) async {
    try {
      final url = '${AppConfig.scanHistoryEndpoint}/$firebaseUid';
      print('[ScanHistory] DELETE $url');

      final response = await _dio.delete(
        url,
        options: Options(headers: {'X-Ummaly-Client': 'mobile'}),
      );

      if (response.statusCode == 200) {
        final body = response.data;
        final deletedCount = (body is Map<String, dynamic>)
            ? body['deletedCount'] as int?
            : null;

        history.clear();
        hasMore.value = false;
        page.value = 1;
        expandedIndex.value = null;

        return deletedCount ?? 0;
      } else {
        print('❌ Failed to delete all history. Status code: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('❌ Error deleting all history: $e');
      return null;
    }
  }
}
