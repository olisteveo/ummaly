import 'package:flutter/foundation.dart';

class ProductSummary {
  final int? id;
  final String name;
  final String? brand;
  final String? imageUrl;
  final String halalStatus; // HALAL | HARAM | UNKNOWN
  final double? confidence;
  final String? barcode;

  const ProductSummary({
    this.id,
    required this.name,
    this.brand,
    this.imageUrl,
    required this.halalStatus,
    this.confidence,
    this.barcode,
  });

  static double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }

  factory ProductSummary.fromJson(Map<String, dynamic> json) {
    return ProductSummary(
      id: json['id'] is int ? json['id'] as int : int.tryParse('${json['id']}'),
      name: (json['name'] ?? '').toString(),
      brand: json['brand']?.toString(),
      imageUrl: (json['image_url'] ?? json['imageUrl'])?.toString(),
      halalStatus: (json['halal_status'] ?? json['halalStatus'] ?? 'UNKNOWN')
          .toString()
          .toUpperCase(),
      confidence: _toDouble(json['confidence']),
      barcode: json['barcode']?.toString(),
    );
  }
}

class ScanEntry {
  final int id;
  final String barcode;
  final DateTime timestamp;
  final String? location;
  final ProductSummary? product;
  final int? flagsCount;
  final bool? myFlagged;

  ScanEntry({
    required this.id,
    required this.barcode,
    required this.timestamp,
    this.location,
    this.product,
    this.flagsCount,
    this.myFlagged,
  });

  factory ScanEntry.fromJson(Map<String, dynamic> json) {
    final tsRaw = json['scan_timestamp'] ?? json['timestamp'] ?? json['date'];
    DateTime ts;
    if (tsRaw is int) {
      ts = DateTime.fromMillisecondsSinceEpoch(tsRaw, isUtc: true).toLocal();
    } else {
      ts = DateTime.tryParse(tsRaw?.toString() ?? '')?.toLocal() ?? DateTime.now();
    }

    final prod = (json['product'] is Map)
        ? ProductSummary.fromJson((json['product'] as Map).cast<String, dynamic>())
        : null;

    return ScanEntry(
      id: json['id'] is int ? json['id'] as int : int.parse(json['id'].toString()),
      barcode: (json['barcode'] ?? prod?.barcode ?? '').toString(),
      timestamp: ts,
      location: json['location']?.toString(),
      product: prod,
      flagsCount: json['flagsCount'] is int
          ? json['flagsCount'] as int
          : int.tryParse('${json['flagsCount']}'),
      myFlagged: json['myFlagged'] is bool ? json['myFlagged'] as bool : null,
    );
  }
}

class ScanHistoryPage {
  final List<ScanEntry> items;
  final int total;
  final int skip;
  final int take;

  ScanHistoryPage({
    required this.items,
    required this.total,
    required this.skip,
    required this.take,
  });

  factory ScanHistoryPage.fromJson(Map<String, dynamic> json) {
    final list = (json['items'] as List? ?? const [])
        .whereType<Map>()
        .map((m) => ScanEntry.fromJson(m.cast<String, dynamic>()))
        .toList();
    return ScanHistoryPage(
      items: list,
      total: json['total'] is int ? json['total'] as int : int.tryParse('${json['total']}') ?? list.length,
      skip: json['skip'] is int ? json['skip'] as int : int.tryParse('${json['skip']}') ?? 0,
      take: json['take'] is int ? json['take'] as int : int.tryParse('${json['take']}') ?? list.length,
    );
  }
}
