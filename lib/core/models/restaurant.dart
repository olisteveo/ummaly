// core/models/restaurant.dart
class Restaurant {
  final String provider;
  final String externalId;
  final String name;
  final String address;
  final double? latitude;
  final double? longitude;
  final double? rating;
  final int? ratingCount;
  final int? priceLevel;
  final List<String> categories;
  final String? phone;
  final String? website;
  final bool? openingNow;
  final List<String>? openingHours;

  /// backend halal signals
  /// - [halalVerified]: true only when an admin has approved the place.
  /// - [claimedHalal]: soft signal (e.g., Yelp "Halal" tag or stored claimed status).
  /// - [communityHalalCount]: number of pending user proposals.
  final bool halalVerified;
  final bool claimedHalal;
  final int communityHalalCount;

  Restaurant({
    required this.provider,
    required this.externalId,
    required this.name,
    required this.address,
    this.latitude,
    this.longitude,
    this.rating,
    this.ratingCount,
    this.priceLevel,
    required this.categories,
    this.phone,
    this.website,
    this.openingNow,
    this.openingHours,
    this.halalVerified = false,
    this.claimedHalal = false,
    this.communityHalalCount = 0,
  });

  factory Restaurant.fromJson(Map<String, dynamic> json) {
    return Restaurant(
      provider: json['provider'] ?? '',
      externalId: json['externalId'] ?? '',
      name: json['name'] ?? '',
      address: json['address'] ?? '',
      latitude:
      (json['latitude'] is num) ? (json['latitude'] as num).toDouble() : null,
      longitude:
      (json['longitude'] is num) ? (json['longitude'] as num).toDouble() : null,
      rating: (json['rating'] is num) ? (json['rating'] as num).toDouble() : null,
      ratingCount:
      (json['ratingCount'] is num) ? (json['ratingCount'] as num).toInt() : null,
      priceLevel:
      (json['priceLevel'] is num) ? (json['priceLevel'] as num).toInt() : null,
      categories:
      (json['categories'] as List?)?.map((e) => e.toString()).toList() ??
          const [],
      phone: json['phone'],
      website: json['website'],
      openingNow: json['openingNow'] is bool ? json['openingNow'] as bool : null,
      openingHours:
      (json['openingHours'] as List?)?.map((e) => e.toString()).toList(),

      // NEW halal fields with safe defaults
      halalVerified: json['halalVerified'] == true,
      claimedHalal: json['claimedHalal'] == true,
      communityHalalCount: (json['communityHalalCount'] is num)
          ? (json['communityHalalCount'] as num).toInt()
          : 0,
    );
  }
}
