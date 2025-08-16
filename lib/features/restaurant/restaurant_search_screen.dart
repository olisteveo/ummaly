import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart'; // NEW

import '../../config/config.dart'; // ✅ Single source of truth for base URL/endpoints

class RestaurantSearchScreen extends StatefulWidget {
  final dynamic service;
  const RestaurantSearchScreen({super.key, required this.service});

  @override
  State<RestaurantSearchScreen> createState() => _RestaurantSearchScreenState();
}

class _RestaurantSearchScreenState extends State<RestaurantSearchScreen> {
  final TextEditingController _qCtrl = TextEditingController(text: 'halal');
  final TextEditingController _nearCtrl = TextEditingController();

  bool _loading = false;
  String? _error;

  List<dynamic> _items = [];

  // diagnostics (last attempt only)
  String? _lastUrl;
  int? _lastStatus;
  String? _lastBodySnippet;

  bool _inFlight = false;

  // ---------- MAP STATE ----------
  GoogleMapController? _mapCtrl;
  final Set<Marker> _markers = <Marker>{};
  LatLng? _userLatLng;
  static const _fallbackCamera =
  CameraPosition(target: LatLng(51.5074, -0.1278), zoom: 11); // London

  @override
  void dispose() {
    _qCtrl.dispose();
    _nearCtrl.dispose();
    _mapCtrl?.dispose();
    super.dispose();
  }

  double? _asDouble(dynamic v) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }

  Future<Position?> _tryGetPosition() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('[Search] Location services disabled');
        return null;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        debugPrint('[Search] Location permission denied: $permission');
        return null;
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );
      debugPrint('[Search] Got location ${pos.latitude}, ${pos.longitude}');
      _userLatLng = LatLng(pos.latitude, pos.longitude);
      return pos;
    } catch (e, st) {
      debugPrint('[Search] Failed to get location: $e\n$st');
      return null;
    }
  }

  Future<void> _fitMapToMarkers() async {
    if (_mapCtrl == null || _markers.isEmpty) {
      // No markers but we might still center on user
      if (_mapCtrl != null && _userLatLng != null) {
        await _mapCtrl!.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(target: _userLatLng!, zoom: 13),
          ),
        );
      }
      return;
    }

    // Build bounds from all markers (+ user if available)
    final points = <LatLng>[
      for (final m in _markers) m.position,
      if (_userLatLng != null) _userLatLng!,
    ];

    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (final p in points.skip(1)) {
      minLat = p.latitude < minLat ? p.latitude : minLat;
      maxLat = p.latitude > maxLat ? p.latitude : maxLat;
      minLng = p.longitude < minLng ? p.longitude : minLng;
      maxLng = p.longitude > maxLng ? p.longitude : maxLng;
    }

    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );

    // Animate after the first frame so the map has a size
    await Future<void>.delayed(const Duration(milliseconds: 50));
    try {
      await _mapCtrl!.animateCamera(
        CameraUpdate.newLatLngBounds(bounds, 60),
      );
    } catch (_) {
      // If bounds are “invalid” (identical points), fall back to a zoom-in
      await _mapCtrl!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: points.first, zoom: 14),
        ),
      );
    }
  }

  void _rebuildMarkersFromItems() {
    final markers = <Marker>{};

    for (var i = 0; i < _items.length; i++) {
      final e = _items[i];
      if (e is! Map) continue;

      final lat = _asDouble(e['latitude']);
      final lng = _asDouble(e['longitude']);
      if (lat == null || lng == null) continue;

      final name = (e['name'] ?? '') as String? ?? '';
      final address = (e['address'] ?? '') as String? ?? '';

      markers.add(
        Marker(
          markerId: MarkerId('r$i'),
          position: LatLng(lat, lng),
          infoWindow: InfoWindow(title: name, snippet: address),
        ),
      );
    }

    setState(() => _markers
      ..clear()
      ..addAll(markers));

    _fitMapToMarkers();
  }

  Future<void> _search() async {
    if (_loading || _inFlight) return;
    FocusScope.of(context).unfocus();

    setState(() {
      _loading = true;
      _error = null;
      _inFlight = true;
      _items = [];
      _markers.clear();
    });

    try {
      final q = _qCtrl.text.trim();
      final near = _nearCtrl.text.trim();

      Position? pos;
      if (near.isEmpty) {
        // Only try GPS if "Near" is empty; otherwise rely on backend geocoding.
        pos = await _tryGetPosition();
      }

      final token = await FirebaseAuth.instance.currentUser?.getIdToken();
      if (token == null) {
        throw Exception('Not authenticated (no Firebase ID token).');
      }
      final headers = <String, String>{
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      };

      // --------- build attempts (progressively relax constraints) ----------
      final attempts = <Map<String, String>>[
        {
          'page': '1',
          'pageSize': '20',
          'radiusMeters': '3000',
          if (q.isNotEmpty) 'query': q,
          if (near.isNotEmpty) 'near': near,
          if (pos != null) 'lat': pos.latitude.toString(),
          if (pos != null) 'lng': pos.longitude.toString(),
        },
        {
          'page': '1',
          'pageSize': '20',
          'radiusMeters': '10000',
          if (q.isNotEmpty) 'query': q,
          if (near.isNotEmpty) 'near': near,
          if (pos != null) 'lat': pos.latitude.toString(),
          if (pos != null) 'lng': pos.longitude.toString(),
        },
        {
          'page': '1',
          'pageSize': '20',
          'radiusMeters': '20000',
          'query': q.isNotEmpty ? q : 'restaurant',
          'q': q.isNotEmpty ? q : 'restaurant',
          if (near.isNotEmpty) 'near': near,
          if (pos != null) 'lat': pos.latitude.toString(),
          if (pos != null) 'lng': pos.longitude.toString(),
        },
      ];

      List<dynamic> found = [];
      int? lastStatusLocal;
      String? lastUrlLocal;
      String? lastBodyLocal;

      for (var i = 0; i < attempts.length; i++) {
        final qp = attempts[i];
        final uri = Uri.parse(Config.restaurantsSearchEndpoint)
            .replace(queryParameters: qp);

        _lastUrl = lastUrlLocal = uri.toString();
        _lastStatus = lastStatusLocal = null;
        _lastBodySnippet = lastBodyLocal = null;

        debugPrint('[Search] → GET $uri  (attempt ${i + 1}/${attempts.length})');
        debugPrint(
            '[Search] headers: ${headers.keys.join(', ')} (tokenLen=${token.length})');

        final resp = await HttpClientBinding.get(uri, headers: headers);

        _lastStatus = lastStatusLocal = resp.statusCode;
        _lastBodySnippet = lastBodyLocal =
        resp.body.length > 1200 ? '${resp.body.substring(0, 1200)}…' : resp.body;

        debugPrint('[Search] ← status ${resp.statusCode}');
        if (kDebugMode) {
          debugPrint('[Search] body (snippet): $lastBodyLocal');
        }

        if (resp.statusCode < 200 || resp.statusCode >= 300) {
          if (i == attempts.length - 1) {
            throw Exception('Restaurant search failed (${resp.statusCode})');
          }
          continue;
        }

        // decode
        final decoded = jsonDecode(resp.body);
        List<dynamic> items;
        if (decoded is List) {
          items = decoded;
        } else if (decoded is Map) {
          items = (decoded['items'] ??
              decoded['data'] ??
              decoded['results'] ??
              decoded['restaurants'] ??
              []) as List<dynamic>;
        } else {
          items = const [];
        }

        if (items.isNotEmpty) {
          found = items;
          break;
        }
      }

      setState(() {
        _items = found;
        _lastUrl = lastUrlLocal;
        _lastStatus = lastStatusLocal;
        _lastBodySnippet = lastBodyLocal;
      });

      _rebuildMarkersFromItems();
    } catch (e, st) {
      debugPrint('[Search] ERROR: $e\n$st');
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
          _inFlight = false;
        });
      }
    }
  }

  Future<void> _centerOnItem(Map e) async {
    final lat = _asDouble(e['latitude']);
    final lng = _asDouble(e['longitude']);
    if (_mapCtrl == null || lat == null || lng == null) return;
    await _mapCtrl!.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: LatLng(lat, lng), zoom: 15),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Restaurant Lookup'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {},
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // --- Search controls ---
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _qCtrl,
                  textInputAction: TextInputAction.search,
                  decoration: const InputDecoration(
                    labelText: 'Search',
                    hintText: 'e.g. halal, pizza',
                  ),
                  onSubmitted: (_) => _search(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _nearCtrl,
                  textInputAction: TextInputAction.search,
                  decoration: const InputDecoration(
                    labelText: 'Near',
                    hintText: 'city/postcode (optional)',
                  ),
                  onSubmitted: (_) => _search(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _loading ? null : _search,
              icon: const Icon(Icons.search),
              label: _loading
                  ? const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
                  : const Text('Search'),
            ),
          ),
          const SizedBox(height: 16),

          // --- Map above the results ---
          SizedBox(
            height: 260,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: GoogleMap(
                initialCameraPosition: _fallbackCamera,
                markers: _markers,
                myLocationEnabled: true,
                myLocationButtonEnabled: true,
                zoomControlsEnabled: false,
                onMapCreated: (c) async {
                  _mapCtrl = c;
                  // Center on user (or fit markers) once the map is ready.
                  await _fitMapToMarkers();
                },
              ),
            ),
          ),
          const SizedBox(height: 16),

          // --- Errors / diagnostics ---
          if (_error != null) ...[
            Center(
              child: Column(
                children: [
                  Text(
                    'Exception: $_error',
                    style: theme.textTheme.bodyMedium!
                        .copyWith(color: theme.colorScheme.error),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _loading ? null : _search,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          if (_lastUrl != null)
            _DiagnosticsCard(
              url: _lastUrl!,
              status: _lastStatus,
              bodySnippet: _lastBodySnippet,
            ),

          // --- Empty state ---
          if (!_loading && _items.isEmpty && _error == null)
            const Padding(
              padding: EdgeInsets.only(top: 24),
              child: Center(child: Text('No results yet — try a search.')),
            ),

          // --- Results list with tap-to-center ---
          if (_items.isNotEmpty)
            ..._items.map((e) {
              final name =
              (e is Map && e['name'] != null) ? e['name'].toString() : 'Unknown';
              final address =
              (e is Map && e['address'] != null) ? e['address'].toString() : '';
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: ListTile(
                  leading: const Icon(Icons.restaurant),
                  title: Text(name),
                  subtitle: Text(address),
                  onTap: () => _centerOnItem(e as Map),
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _DiagnosticsCard extends StatelessWidget {
  final String url;
  final int? status;
  final String? bodySnippet;

  const _DiagnosticsCard({
    required this.url,
    required this.status,
    required this.bodySnippet,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: theme.colorScheme.surfaceVariant.withOpacity(0.4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Diagnostics', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(url, style: theme.textTheme.bodySmall),
                ),
                IconButton(
                  tooltip: 'Copy URL',
                  icon: const Icon(Icons.copy, size: 18),
                  onPressed: () => Clipboard.setData(ClipboardData(text: url)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text('Status: ${status ?? '-'}', style: theme.textTheme.bodySmall),
            const SizedBox(height: 6),
            if (bodySnippet != null) ...[
              Text('Body (first 1.2k):', style: theme.textTheme.bodySmall),
              const SizedBox(height: 4),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  bodySnippet!,
                  style: theme.textTheme.bodySmall!
                      .copyWith(fontFamily: 'monospace'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class HttpClientBinding {
  static Future<_HttpResponse> get(Uri uri, {Map<String, String>? headers}) async {
    final client = HttpClient();
    try {
      final req = await client.getUrl(uri);
      headers?.forEach(req.headers.add);
      final res = await req.close();
      final body = await res.transform(utf8.decoder).join();
      return _HttpResponse(res.statusCode, body);
    } finally {
      client.close(force: true);
    }
  }
}

class _HttpResponse {
  final int statusCode;
  final String body;
  _HttpResponse(this.statusCode, this.body);
}
