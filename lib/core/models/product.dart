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
  /// Optional DB id (if API includes it)
  final int? id;

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

  /// User flagging meta (optional)
  final int? flagsCount; // total flags on this product
  final bool? myFlagged; // whether the current user flagged it

  Product({
    this.id,
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
    this.flagsCount,
    this.myFlagged,
  });

  // Helpers to parse mixed shapes safely
  static int? _toInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    return int.tryParse(v.toString());
  }
  static double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }
  static bool? _toBool(dynamic v) {
    if (v == null) return null;
    if (v is bool) return v;
    final s = v.toString().toLowerCase();
    if (s == 'true') return true;
    if (s == 'false') return false;
    return null;
  }
  static String? _str(dynamic v) => v?.toString();

  factory Product.fromJson(Map<String, dynamic> json) {
    final List<dynamic> matchesRaw =
        (json['halal_matches'] as List?) ??
            (json['halalMatches'] as List?) ??
            const [];

    final List<dynamic> stepsRaw =
        (json['analysis_steps'] as List?) ??
            (json['analysisSteps'] as List?) ??
            const [];

    // Accept snake_case and camelCase for commonly used keys
    final imageUrl = _str(json['image_url'] ?? json['imageUrl']);
    final halalStatus =
    (json['halal_status'] ?? json['halalStatus'] ?? 'UNKNOWN')
        .toString()
        .toUpperCase();

    return Product(
      id: _toInt(json['id']),
      barcode: _str(json['barcode']) ?? '',
      name: _str(json['name']) ?? '',
      brand: _str(json['brand']),
      ingredients: _str(json['ingredients']),
      imageUrl: imageUrl,
      halalStatus: halalStatus,
      halalMatches: matchesRaw
          .whereType<Map>()
          .map((e) => HalalMatch.fromJson(e.cast<String, dynamic>()))
          .toList(),
      confidence: _toDouble(json['confidence']),
      notes: _str(json['notes']),
      analysisSteps: stepsRaw
          .whereType<Map>()
          .map((e) => AnalysisStep.fromJson(e.cast<String, dynamic>()))
          .toList(),
      flagsCount: _toInt(json['flagsCount'] ?? json['flags_count']),
      myFlagged: _toBool(json['myFlagged'] ?? json['my_flagged']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
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
      if (flagsCount != null) 'flagsCount': flagsCount,
      if (myFlagged != null) 'myFlagged': myFlagged,
    };
  }

  Product copyWith({
    int? id,
    String? barcode,
    String? name,
    String? brand,
    String? ingredients,
    String? imageUrl,
    String? halalStatus,
    List<HalalMatch>? halalMatches,
    double? confidence,
    String? notes,
    List<AnalysisStep>? analysisSteps,
    int? flagsCount,
    bool? myFlagged,
  }) {
    return Product(
      id: id ?? this.id,
      barcode: barcode ?? this.barcode,
      name: name ?? this.name,
      brand: brand ?? this.brand,
      ingredients: ingredients ?? this.ingredients,
      imageUrl: imageUrl ?? this.imageUrl,
      halalStatus: halalStatus ?? this.halalStatus,
      halalMatches: halalMatches ?? this.halalMatches,
      confidence: confidence ?? this.confidence,
      notes: notes ?? this.notes,
      analysisSteps: analysisSteps ?? this.analysisSteps,
      flagsCount: flagsCount ?? this.flagsCount,
      myFlagged: myFlagged ?? this.myFlagged,
    );
  }
}
