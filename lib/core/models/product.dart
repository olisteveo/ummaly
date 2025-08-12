class HalalMatch {
  /// We support both backend shapes: {term,status,notes?} and {name,status,notes?}
  final String term;   // canonical
  final String status; // "haram" | "conditional" | "halal"
  final String? notes;

  HalalMatch({
    required this.term,
    required this.status,
    this.notes,
  });

  factory HalalMatch.fromJson(Map<String, dynamic> json) {
    return HalalMatch(
      term: (json['term'] ?? json['name'] ?? '').toString(),
      status: (json['status'] ?? 'conditional').toString(),
      notes: json['notes']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'term': term,
      'status': status,
      if (notes != null) 'notes': notes,
    };
  }
}

class AnalysisStep {
  final String id;
  final String label;
  final String status; // "done" | "error" | "skipped"
  final String? detail;

  AnalysisStep({
    required this.id,
    required this.label,
    required this.status,
    this.detail,
  });

  factory AnalysisStep.fromJson(Map<String, dynamic> json) {
    return AnalysisStep(
      id: json['id']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      status: json['status']?.toString() ?? 'done',
      detail: json['detail'] == null ? null : json['detail'].toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'label': label,
    'status': status,
    if (detail != null) 'detail': detail,
  };
}

class Product {
  final String barcode;
  final String name;
  final String? brand;
  final String? ingredients;
  final String? imageUrl;
  final String halalStatus;

  final List<HalalMatch> halalMatches;

  /// Extra metadata from backend (optional)
  final double? confidence; // 0..1
  final String? notes;
  final List<AnalysisStep> analysisSteps;

  Product({
    required this.barcode,
    required this.name,
    this.brand,
    this.ingredients,
    this.imageUrl,
    required this.halalStatus,
    required this.halalMatches,
    this.confidence,
    this.notes,
    required this.analysisSteps,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    final List<dynamic> matchesRaw = (json['halal_matches'] as List?) ?? const [];
    final List<dynamic> stepsRaw = (json['analysis_steps'] as List?) ?? const [];

    return Product(
      barcode: json['barcode']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      brand: json['brand']?.toString(),
      ingredients: json['ingredients']?.toString(),
      imageUrl: json['image_url']?.toString(),
      halalStatus: (json['halal_status']?.toString() ?? 'UNKNOWN').toUpperCase(),
      halalMatches: matchesRaw
          .map((e) => HalalMatch.fromJson((e as Map).cast<String, dynamic>()))
          .toList(),
      confidence: json['confidence'] == null ? null : (json['confidence'] as num).toDouble(),
      notes: json['notes']?.toString(),
      analysisSteps: stepsRaw
          .map((e) => AnalysisStep.fromJson((e as Map).cast<String, dynamic>()))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'barcode': barcode,
      'name': name,
      'brand': brand,
      'ingredients': ingredients,
      'image_url': imageUrl,
      'halal_status': halalStatus,
      'halal_matches': halalMatches.map((m) => m.toJson()).toList(),
      if (confidence != null) 'confidence': confidence,
      if (notes != null) 'notes': notes,
      'analysis_steps': analysisSteps.map((s) => s.toJson()).toList(),
    };
  }
}
