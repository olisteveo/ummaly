class HalalMatch {
  final String name;
  final String status;
  final String notes;

  HalalMatch({
    required this.name,
    required this.status,
    required this.notes,
  });

  factory HalalMatch.fromJson(Map<String, dynamic> json) {
    return HalalMatch(
      name: json['name'] ?? '',
      status: json['status'] ?? '',
      notes: json['notes'] ?? '',
    );
  }
}

class Product {
  final String barcode;
  final String name;
  final String? brand;
  final String? ingredients;
  final String? imageUrl;
  final String halalStatus;
  final List<HalalMatch> halalMatches;

  Product({
    required this.barcode,
    required this.name,
    this.brand,
    this.ingredients,
    this.imageUrl,
    required this.halalStatus,
    required this.halalMatches,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      barcode: json['barcode'] ?? '',
      name: json['name'] ?? '',
      brand: json['brand'],
      ingredients: json['ingredients'],
      imageUrl: json['image_url'],
      halalStatus: json['halal_status'] ?? 'unknown',
      halalMatches: (json['halal_matches'] as List<dynamic>? ?? [])
          .map((match) => HalalMatch.fromJson(match))
          .toList(),
    );
  }
}
