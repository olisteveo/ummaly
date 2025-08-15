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
    final uri = Config.restaurantsSearchUri(
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
}
