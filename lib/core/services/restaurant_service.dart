import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:ummaly/config/config.dart';
import 'package:ummaly/core/models/restaurant.dart'; // ✅ canonical import

class RestaurantSearchResponse {
  final List<Restaurant> items;
  final int count;
  final List<String> providersUsed;

  RestaurantSearchResponse({
    required this.items,
    required this.count,
    required this.providersUsed,
  });
}

class RestaurantService {
  const RestaurantService();

  Future<RestaurantSearchResponse> search({
    required String query,
    String? near,
    double? lat,
    double? lng,
    int radiusMeters = 3000,
    int page = 1,
    int pageSize = 20,
    bool? halalOnly, // optional – if null, server default applies
    String? sort,
  }) async {
    final uri = AppConfig.restaurantsSearchUri(
      query: query,
      near: near,
      lat: lat,
      lng: lng,
      radiusMeters: radiusMeters,
      page: page,
      pageSize: pageSize,
      halalOnly: halalOnly,
      sort: sort,
    );

    final res = await http.get(
      uri,
      headers: const {'Accept': 'application/json'},
    );

    if (res.statusCode != 200) {
      throw Exception('Restaurant search failed (${res.statusCode})');
    }

    final body = json.decode(res.body) as Map<String, dynamic>;

    final items = ((body['items'] as List?) ?? [])
        .map((e) => Restaurant.fromJson(e as Map<String, dynamic>))
        .toList();

    final count = (body['count'] is num)
        ? (body['count'] as num).toInt()
        : items.length;

    final providersUsed = (body['providersUsed'] as List?)
        ?.map((e) => e.toString())
        .toList() ??
        const [];

    return RestaurantSearchResponse(
      items: items,
      count: count,
      providersUsed: providersUsed,
    );
  }

  /// Optional helper if you want to post proposals from a service instead of a screen.
  Future<void> submitHalalProposal({
    required String provider, // 'google'
    required String externalId, // google place_id
    String? evidenceText,
    List<String>? evidenceUrls,
    String intent = 'CERTIFY', // 'CERTIFY' | 'DISPUTE'
    String? authToken,
  }) async {
    final rs = Uri.parse(AppConfig.restaurantsSearchEndpoint);
    final uri = Uri(
      scheme: rs.scheme,
      host: rs.host,
      port: rs.hasPort ? rs.port : null,
      path: '/api/halal/proposals',
    );

    final body = <String, dynamic>{
      'provider': provider,
      'externalId': externalId,
      if (evidenceText != null) 'evidenceText': evidenceText,
      if (evidenceUrls != null) 'evidenceUrls': evidenceUrls,
      'intent': intent,
    };

    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (authToken != null) 'Authorization': 'Bearer $authToken',
    };

    final res = await http.post(uri, headers: headers, body: jsonEncode(body));
    if (res.statusCode >= 400) {
      throw Exception('Proposal failed: ${res.statusCode} ${res.body}');
    }
  }
}
