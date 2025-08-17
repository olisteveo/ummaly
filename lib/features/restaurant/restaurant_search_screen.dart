import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:ummaly/theme/styles.dart';
import 'package:ummaly/theme/map_styles.dart';
import 'package:ummaly/config/config.dart';
import 'package:ummaly/features/restaurant/widgets/restaurant_card.dart'; // RestaurantCardLite

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

  // ---------- MAP ----------
  GoogleMapController? _mapCtrl;
  final Set<Marker> _markers = <Marker>{};
  LatLng _center = const LatLng(51.5074, -0.1278); // London default
  double _radiusKm = 5.0; // stored internally in KM (0.5–40.0)

  static const _fallbackCamera =
  CameraPosition(target: LatLng(51.5074, -0.1278), zoom: 11);

  // Sheet control (so the handle actually drags)
  final DraggableScrollableController _sheetCtrl =
  DraggableScrollableController();
  static const double _sheetMin = 0.12;
  static const double _sheetInit = 0.20;
  static const double _sheetMax = 0.75;

  // UX helpers
  Timer? _radiusDebounce;
  int _requestSerial = 0;

  // bootstrap guard (center on user once on load)
  bool _didBootstrapCenter = false;

  @override
  void initState() {
    super.initState();
    _bootstrapLocationCenter(); // try to center on user ASAP
  }

  @override
  void dispose() {
    _qCtrl.dispose();
    _nearCtrl.dispose();
    _radiusDebounce?.cancel();
    _mapCtrl?.dispose();
    super.dispose();
  }

  // --- Units (KM vs MI) ---
  bool get _useMiles {
    final cc = Localizations.localeOf(context).countryCode?.toUpperCase();
    return cc == 'GB' || cc == 'US' || cc == 'LR' || cc == 'MM'; // UK included
  }

  double get _kmToMi => 0.621371;
  String _radiusLabel() {
    if (_useMiles) {
      final mi = _radiusKm * _kmToMi;
      final digits = mi < 10 ? 1 : 0;
      return '${mi.toStringAsFixed(digits)} mi';
    } else {
      if (_radiusKm < 1) return '${(_radiusKm * 1000).round()} m';
      return '${_radiusKm.toStringAsFixed(1)} km';
    }
  }

  // --- helpers ---
  double? _asDouble(dynamic v) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }

  Future<Position?> _tryGetPosition() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );
      _center = LatLng(pos.latitude, pos.longitude);
      return pos;
    } catch (_) {
      return null;
    }
  }

  // Try to center the map on the user's location at startup
  Future<void> _bootstrapLocationCenter() async {
    if (_didBootstrapCenter) return;
    _didBootstrapCenter = true;

    final pos = await _tryGetPosition(); // sets _center if success
    if (!mounted || pos == null) return;

    if (_mapCtrl != null) {
      await _mapCtrl!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: _center,
            zoom: _zoomForRadiusMeters(_radiusKm * 1000),
          ),
        ),
      );
    }
  }

  // Zoom so a radius fits the screen width nicely
  double _zoomForRadiusMeters(double radiusMeters) {
    final r = radiusMeters.clamp(100.0, 80000.0);
    const world = 40075016.686; // meters at equator
    const viewPortFraction = 0.6; // diameter ~60% of width
    final metersPerPixel = (r * 2) / (viewPortFraction * 256);
    final zoom = math.log(world / metersPerPixel) / math.ln2;
    return zoom.clamp(3.0, 21.0);
  }

  Future<void> _fitMapToPinsRespectingRadius() async {
    if (_mapCtrl == null) return;

    if (_markers.isEmpty) {
      await _mapCtrl!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: _center,
            zoom: _zoomForRadiusMeters(_radiusKm * 1000),
          ),
        ),
      );
      return;
    }

    final points = _markers.map((m) => m.position).toList();
    double minLat = points.first.latitude, maxLat = points.first.latitude;
    double minLng = points.first.longitude, maxLng = points.first.longitude;

    for (final p in points.skip(1)) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }

    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );

    await Future<void>.delayed(const Duration(milliseconds: 50));
    try {
      await _mapCtrl!.animateCamera(
        CameraUpdate.newLatLngBounds(bounds, 60),
      );
    } catch (_) {
      await _mapCtrl!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: points.first, zoom: 15),
        ),
      );
    }

    final currentZoom = await _mapCtrl!.getZoomLevel();
    final radiusZoom = _zoomForRadiusMeters(_radiusKm * 1000);
    if (currentZoom > radiusZoom) {
      await _mapCtrl!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: _center, zoom: radiusZoom),
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
          icon: BitmapDescriptor.defaultMarkerWithHue(275), // Ummaly hue
          position: LatLng(lat, lng),
          // Tapping the info window opens directions now
          infoWindow: InfoWindow(
            title: name,
            snippet: address,
            onTap: () => _openInMaps(lat, lng, name),
          ),
        ),
      );
    }
    setState(() => _markers
      ..clear()
      ..addAll(markers));
  }

  // distance + maps
  double _haversineMeters(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371000.0;
    double toRad(double d) => d * (math.pi / 180.0);
    final dLat = toRad(lat2 - lat1), dLon = toRad(lon2 - lon1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(toRad(lat1)) *
            math.cos(toRad(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    return 2 * R * math.asin(math.sqrt(a));
  }

  String _distanceLabel(double lat, double lng) {
    final m =
    _haversineMeters(_center.latitude, _center.longitude, lat, lng);
    if (_useMiles) {
      final mi = m / 1609.344;
      final digits = mi < 10 ? 1 : 0;
      return '${mi.toStringAsFixed(digits)} mi away';
    }
    return m < 1000
        ? '${m.round()} m away'
        : '${(m / 1000).toStringAsFixed(m < 10000 ? 1 : 0)} km away';
  }

  Future<void> _openInMaps(double lat, double lng, String name) async {
    final query = Uri.encodeComponent(name);
    final geo = Uri.parse('geo:$lat,$lng?q=$lat,$lng($query)'); // Android
    final apple =
    Uri.parse('http://maps.apple.com/?q=$query&ll=$lat,$lng'); // iOS
    if (await canLaunchUrl(geo)) {
      await launchUrl(geo);
    } else {
      await launchUrl(apple, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _search() async {
    if (_loading) return;
    FocusScope.of(context).unfocus();

    setState(() {
      _loading = true;
      _error = null;
      _items = [];
      _markers.clear();
    });

    final myTurn = ++_requestSerial;

    try {
      final q = _qCtrl.text.trim();
      final near = _nearCtrl.text.trim();

      Position? pos;
      if (near.isEmpty) {
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

      final qp = <String, String>{
        'page': '1',
        'pageSize': '20',
        // backend expects meters; keep internal in KM
        'radiusMeters': (_radiusKm * 1000).round().toString(),
        if (q.isNotEmpty) 'query': q,
        if (near.isNotEmpty) 'near': near,
        if (pos != null) 'lat': pos.latitude.toString(),
        if (pos != null) 'lng': pos.longitude.toString(),
      };

      final uri = Uri.parse(Config.restaurantsSearchEndpoint)
          .replace(queryParameters: qp);

      if (kDebugMode) debugPrint('[Search] GET $uri');

      final resp = await HttpClientBinding.get(uri, headers: headers);

      if (resp.statusCode < 200 || resp.statusCode >= 300) {
        throw Exception('Restaurant search failed (${resp.statusCode})');
      }

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

      // TODO(backend): if you enrich items with Google Places details,
      // surface keys like 'googleRating' and 'googleUserRatings' here,
      // and optionally 'googlePlaceId' for deeplinks.

      if (myTurn != _requestSerial) return;

      setState(() => _items = items);

      _rebuildMarkersFromItems();

      if (_markers.isNotEmpty) {
        final pts = _markers.map((m) => m.position).toList();
        final avgLat =
            pts.map((e) => e.latitude).reduce((a, b) => a + b) / pts.length;
        final avgLng =
            pts.map((e) => e.longitude).reduce((a, b) => a + b) / pts.length;
        _center = LatLng(avgLat, avgLng);
      }

      await _fitMapToPinsRespectingRadius();
    } catch (e) {
      if (myTurn != _requestSerial) return;
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (!mounted || myTurn != _requestSerial) return;
      setState(() => _loading = false);
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

  // drag the sheet using the pill
  void _dragSheetByPixels(double deltaPixels) {
    final h = MediaQuery.of(context).size.height;
    final current = _sheetCtrl.size;
    final delta = -deltaPixels / h;
    final next = (current + delta).clamp(_sheetMin, _sheetMax);
    _sheetCtrl.jumpTo(next);
  }

  @override
  Widget build(BuildContext context) {
    final radiusLabel = _radiusLabel();
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    // preset values shown to the user in their local unit
    final presets = _useMiles ? [1.0, 3.0, 10.0] : [1.0, 5.0, 10.0];

    void _applyPresetUnits(double valueInUnits) {
      final km = _useMiles ? (valueInUnits / _kmToMi) : valueInUnits;
      setState(() => _radiusKm = km);
      _search();
    }

    String _labelForUnit(double valueInUnits) =>
        _useMiles ? '${valueInUnits.toStringAsFixed(0)} mi'
            : '${valueInUnits.toStringAsFixed(0)} km';

    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: false, // keep stack stable while keyboard shows
      appBar: AppBar(
        title: const Text('Restaurant Lookup'),
        elevation: 0,
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
      ),
      body: Stack(
        children: [
          // --- Fullscreen Map ---
          Positioned.fill(
            child: GoogleMap(
              initialCameraPosition: _fallbackCamera,
              markers: _markers,
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              tiltGesturesEnabled: false,
              rotateGesturesEnabled: true,
              zoomGesturesEnabled: true,
              onMapCreated: (c) async {
                _mapCtrl = c;
                await UmmalyMapStyles.apply(c, context);
                await _bootstrapLocationCenter();      // NEW: center on user if available
                await _fitMapToPinsRespectingRadius(); // smart fit
              },
            ),
          ),

          // --- Top overlay: search + radius controls ---
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.l, AppSpacing.l, AppSpacing.l, 0),
              child: Material(
                color: AppColors.surface,
                elevation: 2,
                borderRadius: BorderRadius.circular(AppRadius.l),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.l),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _qCtrl,
                              textInputAction: TextInputAction.search,
                              decoration: AppInput.decoration(
                                label: 'Search',
                                hint: 'e.g. halal, pizza',
                                prefix: Icons.search,
                              ),
                              onSubmitted: (_) => _search(),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.l),
                          Expanded(
                            child: TextField(
                              controller: _nearCtrl,
                              textInputAction: TextInputAction.search,
                              decoration: AppInput.decoration(
                                label: 'Near',
                                hint: 'city/postcode (optional)',
                                prefix: Icons.place_outlined,
                              ),
                              onSubmitted: (_) => _search(),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.m),

                      // radius label on its own row (no crowding)
                      Row(
                        children: [
                          const Icon(Icons.radar,
                              size: 20, color: AppColors.textSecondary),
                          const SizedBox(width: AppSpacing.s),
                          Text('Search radius',
                              style: AppTextStyles.caption
                                  .copyWith(fontSize: 13)),
                          const Spacer(),
                          Text(radiusLabel,
                              style: AppTextStyles.caption
                                  .copyWith(fontWeight: FontWeight.w600)),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.s),

                      // Presets wrap under label
                      Wrap(
                        spacing: AppSpacing.s,
                        runSpacing: AppSpacing.s,
                        children: [
                          for (final p in presets)
                            _PresetChip(
                              label: _labelForUnit(p),
                              onTap: () => _applyPresetUnits(p),
                            ),
                        ],
                      ),

                      // Slider (still uses KM internally)
                      Slider(
                        value: _radiusKm,
                        min: 0.5,
                        max: 40.0,
                        divisions: 79,
                        label: radiusLabel,
                        onChanged: (v) {
                          setState(() => _radiusKm = v);
                          _radiusDebounce?.cancel();
                          _radiusDebounce =
                              Timer(const Duration(milliseconds: 250), _search);
                        },
                        onChangeEnd: (_) {
                          _radiusDebounce?.cancel();
                          _search();
                        },
                      ),

                      // Search button (explicit, like before)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _loading ? null : _search,
                          icon: const Icon(Icons.search),
                          label: const Text('Search'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // --- Recenter button ---
          Positioned(
            top: 140, // below the search card
            right: AppSpacing.l,
            child: Material(
              color: AppColors.surface,
              shape: const CircleBorder(),
              elevation: 2,
              child: IconButton(
                tooltip: 'Recenter',
                onPressed: _fitMapToPinsRespectingRadius,
                icon: const Icon(Icons.center_focus_strong),
              ),
            ),
          ),

          // --- Draggable results sheet ---
          DraggableScrollableSheet(
            controller: _sheetCtrl,
            initialChildSize: _sheetInit,
            minChildSize: _sheetMin,
            maxChildSize: _sheetMax,
            snap: true,
            builder: (context, scrollController) {
              return Container(
                padding: EdgeInsets.only(bottom: bottomInset), // keyboard safe
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(AppRadius.xl),
                    topRight: Radius.circular(AppRadius.xl),
                  ),
                  boxShadow: AppCards.modalShadows,
                ),
                child: Column(
                  children: [
                    const SizedBox(height: AppSpacing.s),

                    // drag handle – now actually drags the sheet
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onVerticalDragUpdate: (d) =>
                          _dragSheetByPixels(d.primaryDelta ?? 0),
                      onDoubleTap: () {
                        final target =
                        (_sheetCtrl.size < (_sheetMin + _sheetMax) / 2)
                            ? 0.45
                            : _sheetMin;
                        _sheetCtrl.animateTo(
                          target,
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeOut,
                        );
                      },
                      child: Container(
                        width: 56,
                        height: 20,
                        alignment: Alignment.center,
                        child: Container(
                          width: 44,
                          height: 5,
                          decoration: BoxDecoration(
                            color: Colors.black12,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                    ),

                    Padding(
                      padding:
                      const EdgeInsets.symmetric(horizontal: AppSpacing.l),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          _error != null
                              ? 'Error'
                              : _items.isEmpty
                              ? 'Results'
                              : '${(_items.length)} places found',
                          style: AppTextStyles.instruction,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s),

                    Expanded(
                      child: _error != null
                          ? ListView(
                        controller: scrollController,
                        keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                        padding:
                        const EdgeInsets.all(AppSpacing.l),
                        children: [
                          Text(_error!,
                              style: AppTextStyles.error,
                              textAlign: TextAlign.center),
                          const SizedBox(height: AppSpacing.m),
                          ElevatedButton(
                            style: AppButtons.dangerButton,
                            onPressed: _loading ? null : _search,
                            child: const Text('Retry'),
                          ),
                        ],
                      )
                          : (_items.isEmpty && !_loading)
                          ? ListView(
                        controller: scrollController,
                        keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                        padding:
                        const EdgeInsets.all(AppSpacing.l),
                        children: const [
                          SizedBox(height: AppSpacing.s),
                          Text(
                            'No results yet — try a search.',
                            style: AppTextStyles.instruction,
                          ),
                        ],
                      )
                          : ListView.builder(
                        controller: scrollController,
                        keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                        padding: const EdgeInsets.fromLTRB(
                            AppSpacing.l, 0, AppSpacing.l, AppSpacing.l),
                        itemCount: _items.length,
                        itemBuilder: (context, i) {
                          final m = _items[i] as Map;
                          final name =
                              m['name']?.toString() ?? 'Unknown';
                          final address =
                              m['address']?.toString() ?? '';
                          final lat = _asDouble(m['latitude']);
                          final lng = _asDouble(m['longitude']);
                          final dist = (lat != null && lng != null)
                              ? _distanceLabel(lat, lng)
                              : null;

                          return RestaurantCardLite(
                            name: name,
                            address: address,
                            rating: (m['rating'] as num?)?.toDouble() ??
                                (m['googleRating'] as num?)?.toDouble(), // optional
                            ratingCount: (m['ratingCount'] as num?)?.toInt() ??
                                (m['googleUserRatings'] as num?)?.toInt(), // optional
                            categories: (m['categories'] as List?)
                                ?.map((e) => e.toString())
                                .toList() ??
                                const [],
                            provider:
                            m['provider']?.toString() ?? 'EXT',
                            priceLevel:
                            (m['priceLevel'] as num?)?.toInt(),
                            distance: dist,
                            onTap: () => _centerOnItem(m),
                            onDirections: (lat != null && lng != null)
                                ? () => _openInMaps(lat, lng, name)
                                : null,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: (_loading)
          ? FloatingActionButton(
        onPressed: () {},
        backgroundColor: AppColors.primary,
        child: const SizedBox(
          height: 22,
          width: 22,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.white,
          ),
        ),
      )
          : null,
    );
  }
}

class _PresetChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _PresetChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.m, vertical: AppSpacing.s),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.08),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppColors.primary.withOpacity(0.25)),
        ),
        child: Text(
          label,
          style: AppTextStyles.caption.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}

class HttpClientBinding {
  static Future<_HttpResponse> get(Uri uri,
      {Map<String, String>? headers}) async {
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
