import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:ummaly/config/config.dart';
import 'package:ummaly/core/models/scan_entry.dart';

/// Fetches paginated scan history.
/// Uses Config.scanHistoryEndpoint, e.g. `${baseUrl}/api/scan-history`.
class ScanHistoryService {
  final String baseUrl;
  ScanHistoryService({String? baseUrl}) : baseUrl = baseUrl ?? Config.apiBaseUrl;

  /// Fetch a page of scan history.
  /// - [skip]: number of records to skip (offset)
  /// - [take]: page size (server usually caps to 50)
  /// - [includeProduct]: hints backend to include product summary in each item
  Future<ScanHistoryPage> fetch({
    int skip = 0,
    int take = 20,
    bool includeProduct = true,
  }) async {
    final qp = <String>[
      'skip=$skip',
      'take=$take',
      if (includeProduct) 'includeProduct=1',
    ].join('&');

    final uri = Uri.parse('${Config.scanHistoryEndpoint}?$qp');
    final res = await http.get(uri);

    if (res.statusCode != 200) {
      throw StateError('Failed to fetch scan history: ${res.statusCode} ${res.body}');
    }

    final map = jsonDecode(res.body) as Map<String, dynamic>;
    return ScanHistoryPage.fromJson(map);
  }
}
