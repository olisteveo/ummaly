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
  final String? googleMapsUrl;
  final bool? openingNow;
  final List<String>? openingHours;

  /// Halal metadata (from backend)
  ///
  /// - [halalStatusEffective] e.g. CERTIFIED | CLAIMED_HALAL | UNKNOWN | NOT_HALAL
  /// - [isVerifiedHalal] true iff admin verified (alias kept: [halalVerified])
  /// - [halalVerifiedAt] ISO timestamp when verified
  /// - [claimedHalal] soft signal (e.g., user/yelp claim)
  /// - [communityHalalCount] number of pending proposals
  final String halalStatusEffective;
  final bool isVerifiedHalal;
  final bool halalVerified; // legacy alias, mirrors isVerifiedHalal
  final DateTime? halalVerifiedAt;
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
    this.googleMapsUrl,
    this.openingNow,
    this.openingHours,
    // halal
    this.halalStatusEffective = 'UNKNOWN',
    this.isVerifiedHalal = false,
    bool? halalVerified, // if provided, overrides; else mirrors isVerifiedHalal
    this.halalVerifiedAt,
    this.claimedHalal = false,
    this.communityHalalCount = 0,
  }) : halalVerified = halalVerified ?? isVerifiedHalal;

  factory Restaurant.fromJson(Map<String, dynamic> json) {
    DateTime? _parseDt(dynamic v) {
      if (v == null) return null;
      try {
        if (v is String) return DateTime.parse(v);
      } catch (_) {}
      return null;
    }

    final String status =
        (json['halalStatusEffective'] as String?) ??
            ((json['claimedHalal'] == true) ? 'CLAIMED_HALAL' : 'UNKNOWN');

    final bool verified =
        (json['isVerifiedHalal'] ?? json['halalVerified']) == true;

    final bool claimed =
        (json['claimedHalal'] == true) || status == 'CLAIMED_HALAL';

    return Restaurant(
      provider: json['provider'] ?? '',
      externalId: json['externalId'] ?? '',
      name: json['name'] ?? '',
      address: json['address'] ?? '',
      latitude: (json['latitude'] is num)
          ? (json['latitude'] as num).toDouble()
          : null,
      longitude: (json['longitude'] is num)
          ? (json['longitude'] as num).toDouble()
          : null,
      rating: (json['rating'] is num) ? (json['rating'] as num).toDouble() : null,
      ratingCount: (json['ratingCount'] is num)
          ? (json['ratingCount'] as num).toInt()
          : null,
      priceLevel: (json['priceLevel'] is num)
          ? (json['priceLevel'] as num).toInt()
          : null,
      categories:
      (json['categories'] as List?)?.map((e) => e.toString()).toList() ??
          const [],
      phone: json['phone'],
      website: json['website'],
      googleMapsUrl: json['googleMapsUrl'],
      openingNow: json['openingNow'] is bool ? json['openingNow'] as bool : null,
      openingHours:
      (json['openingHours'] as List?)?.map((e) => e.toString()).toList(),

      // halal fields
      halalStatusEffective: status,
      isVerifiedHalal: verified,
      halalVerified: verified, // keep alias in sync
      halalVerifiedAt: _parseDt(json['halalVerifiedAt']),
      claimedHalal: claimed,
      communityHalalCount: (json['communityHalalCount'] is num)
          ? (json['communityHalalCount'] as num).toInt()
          : 0,
    );
  }
}
