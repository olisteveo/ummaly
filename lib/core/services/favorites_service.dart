import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Lightweight local favorites store.
///
/// Persists a list of favorited products as JSON in SharedPreferences.
/// Each entry stores enough data to display a compact card without
/// needing a network call.
class FavoritesService extends ChangeNotifier {
  FavoritesService._();
  static final FavoritesService instance = FavoritesService._();

  static const _key = 'favorite_scans';
  static const int _maxFavorites = 50;

  List<FavoriteProduct> _favorites = [];
  bool _loaded = false;

  List<FavoriteProduct> get favorites => List.unmodifiable(_favorites);
  int get count => _favorites.length;

  /// Load from disk (call once at startup or lazily)
  Future<void> load() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    _favorites = raw
        .map((s) {
          try {
            return FavoriteProduct.fromJson(
                jsonDecode(s) as Map<String, dynamic>);
          } catch (_) {
            return null;
          }
        })
        .whereType<FavoriteProduct>()
        .toList();
    _loaded = true;
    notifyListeners();
  }

  /// Check if a barcode is favorited
  bool isFavorited(String barcode) {
    return _favorites.any((f) => f.barcode == barcode);
  }

  /// Toggle favorite. Returns new favorited state.
  Future<bool> toggle(FavoriteProduct product) async {
    final exists = _favorites.indexWhere((f) => f.barcode == product.barcode);
    if (exists >= 0) {
      _favorites.removeAt(exists);
    } else {
      // Add to front (most recent first), cap at max
      _favorites.insert(0, product.copyWith(favoritedAt: DateTime.now()));
      if (_favorites.length > _maxFavorites) {
        _favorites = _favorites.sublist(0, _maxFavorites);
      }
    }
    await _save();
    notifyListeners();
    return exists < 0; // true = now favorited
  }

  /// Remove a favorite by barcode
  Future<void> remove(String barcode) async {
    _favorites.removeWhere((f) => f.barcode == barcode);
    await _save();
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = _favorites.map((f) => jsonEncode(f.toJson())).toList();
    await prefs.setStringList(_key, encoded);
  }
}

/// Minimal product snapshot for display in favorites list.
class FavoriteProduct {
  final String barcode;
  final String name;
  final String? brand;
  final String halalStatus;
  final String? imageUrl;
  final DateTime favoritedAt;

  FavoriteProduct({
    required this.barcode,
    required this.name,
    this.brand,
    required this.halalStatus,
    this.imageUrl,
    DateTime? favoritedAt,
  }) : favoritedAt = favoritedAt ?? DateTime.now();

  factory FavoriteProduct.fromJson(Map<String, dynamic> json) {
    return FavoriteProduct(
      barcode: json['barcode'] ?? '',
      name: json['name'] ?? '',
      brand: json['brand'],
      halalStatus: (json['halal_status'] ?? json['halalStatus'] ?? 'UNKNOWN')
          .toString()
          .toUpperCase(),
      imageUrl: json['image_url'] ?? json['imageUrl'],
      favoritedAt: json['favorited_at'] != null
          ? DateTime.tryParse(json['favorited_at']) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'barcode': barcode,
        'name': name,
        'brand': brand,
        'halal_status': halalStatus,
        'image_url': imageUrl,
        'favorited_at': favoritedAt.toIso8601String(),
      };

  FavoriteProduct copyWith({DateTime? favoritedAt}) => FavoriteProduct(
        barcode: barcode,
        name: name,
        brand: brand,
        halalStatus: halalStatus,
        imageUrl: imageUrl,
        favoritedAt: favoritedAt ?? this.favoritedAt,
      );
}
