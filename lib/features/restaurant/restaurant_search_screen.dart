import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:ummaly/core/models/restaurant.dart';
import 'package:ummaly/core/services/restaurant_service.dart';
import 'widgets/restaurant_card.dart';

class RestaurantSearchScreen extends StatefulWidget {
  const RestaurantSearchScreen({super.key, required this.service});
  final RestaurantService service;

  @override
  State<RestaurantSearchScreen> createState() => _RestaurantSearchScreenState();
}

class _RestaurantSearchScreenState extends State<RestaurantSearchScreen> {
  final _qCtrl = TextEditingController(text: 'halal');
  final _nearCtrl = TextEditingController(text: 'London, UK');
  final _scroll = ScrollController();

  final _items = <Restaurant>[];
  bool _loading = false;
  bool _error = false;
  String? _errorMsg;
  int _page = 1;
  final int _pageSize = 20;
  bool _hasMore = true;
  Timer? _debounce;

  double? _lat;
  double? _lng;

  @override
  void initState() {
    super.initState();
    _initLocation();
    _scroll.addListener(() {
      if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 200 &&
          !_loading &&
          _hasMore) {
        _fetch();
      }
    });
  }

  @override
  void dispose() {
    _qCtrl.dispose();
    _nearCtrl.dispose();
    _scroll.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _initLocation() async {
    final has = await _ensureLocationPermission();
    if (!has) {
      _fetch(reset: true);
      return;
    }
    try {
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _lat = pos.latitude;
        _lng = pos.longitude;
        _nearCtrl.clear(); // Use coordinates directly
      });
      _fetch(reset: true);
    } catch (e) {
      debugPrint('Location error: $e');
      _fetch(reset: true);
    }
  }

  Future<bool> _ensureLocationPermission() async {
    if (!await Geolocator.isLocationServiceEnabled()) return false;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return false;
    }
    if (permission == LocationPermission.deniedForever) return false;
    return true;
  }

  Future<void> _fetch({bool reset = false}) async {
    if (_loading) return;
    setState(() {
      _loading = true;
      if (reset) {
        _items.clear();
        _page = 1;
        _hasMore = true;
        _error = false;
        _errorMsg = null;
      }
    });

    try {
      final res = await widget.service.search(
        query: _qCtrl.text.trim().isEmpty ? 'restaurant' : _qCtrl.text.trim(),
        near: (_lat == null && _lng == null && _nearCtrl.text.trim().isNotEmpty)
            ? _nearCtrl.text.trim()
            : null,
        lat: _lat,
        lng: _lng,
        page: _page,
        pageSize: _pageSize,
      );

      setState(() {
        _items.addAll(res.items);
        _hasMore = res.items.length >= _pageSize;
        if (_hasMore) _page += 1;
      });
    } catch (e) {
      setState(() {
        _error = true;
        _errorMsg = e.toString();
      });
    } finally {
      setState(() => _loading = false);
    }
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(
      const Duration(milliseconds: 500),
          () => _fetch(reset: true),
    );
  }

  Future<void> _useMyLocation() async {
    setState(() {
      _nearCtrl.clear();
      _lat = null;
      _lng = null;
    });
    await _initLocation();
  }

  @override
  Widget build(BuildContext context) {
    final list = _error
        ? Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(_errorMsg ?? 'Something went wrong'),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () => _fetch(reset: true),
            child: const Text('Retry'),
          ),
        ],
      ),
    )
        : RefreshIndicator(
      onRefresh: () => _fetch(reset: true),
      child: ListView.builder(
        controller: _scroll,
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _items.length + (_loading ? 1 : 0),
        itemBuilder: (ctx, i) {
          if (i >= _items.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          return RestaurantCard(item: _items[i]);
        },
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Restaurant Lookup'),
        actions: [
          IconButton(
            tooltip: 'Use My Location',
            icon: const Icon(Icons.my_location),
            onPressed: _useMyLocation,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _qCtrl,
                    onChanged: (_) => _onSearchChanged(),
                    decoration: const InputDecoration(
                      labelText: 'Search',
                      hintText: 'e.g. halal, burgers, pizza',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _nearCtrl,
                    onChanged: (_) => _onSearchChanged(),
                    decoration: const InputDecoration(
                      labelText: 'Near',
                      hintText: 'City or "lat,lng"',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(child: list),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _fetch(reset: true),
        icon: const Icon(Icons.search),
        label: const Text('Search'),
      ),
    );
  }
}
