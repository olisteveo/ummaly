import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/scheduler.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:ummaly/theme/styles.dart';
import 'package:ummaly/theme/map_styles.dart';
import 'package:ummaly/config/config.dart';
import 'package:ummaly/features/restaurant/widgets/restaurant_card.dart';
import 'package:ummaly/features/restaurant/widgets/search_header.dart';
import 'package:ummaly/features/restaurant/widgets/restaurant_map.dart';
import 'package:ummaly/features/restaurant/widgets/results_sheet.dart';
import 'package:ummaly/shared/http/http_client_binding.dart';

/// Background JSON parsing to keep the UI thread smooth.
List<dynamic> _parseRestaurantsIsolate(String body) {
  final decoded = jsonDecode(body);
  if (decoded is List) return decoded;
  if (decoded is Map) {
    return (decoded['items'] ??
        decoded['data'] ??
        decoded['results'] ??
        decoded['restaurants'] ??
        []) as List<dynamic>;
  }
  return const [];
}

class RestaurantSearchScreen extends StatefulWidget {
  final dynamic service;
  const RestaurantSearchScreen({super.key, required this.service});

  @override
  State<RestaurantSearchScreen> createState() => _RestaurantSearchScreenState();
}

class _RestaurantSearchScreenState extends State<RestaurantSearchScreen> {
  // Inputs
  final TextEditingController _qCtrl = TextEditingController(text: 'halal');
  final TextEditingController _nearCtrl = TextEditingController();

  // State
  bool _loading = false;
  String? _error;
  List<dynamic> _items = [];

  // Track per-item submit spinners for submit buttons
  final Set<int> _submittingIdx = <int>{};

  // Persisted memory of my proposals (across sessions)
  // Legacy (kept): CERTIFY reports you submitted
  static const String _prefsKeyProposedLegacy = 'halalProposedKeys';
  // New: split memory -> certify vs dispute
  static const String _prefsKeyProposedCert = 'halalProposedKeysCert';
  static const String _prefsKeyProposedDispute = 'halalProposedKeysDispute';

  // Persist last-used search inputs
  static const String _prefsKeyLastQuery = 'resto_last_query';
  static const String _prefsKeyLastNear = 'resto_last_near';
  static const String _prefsKeyLastRadiusKm = 'resto_last_radius_km';
  static const String _prefsKeyRadiusExpanded = 'resto_radius_expanded';

  // Local memory maps
  final Map<String, bool> _alreadyProposedCertByMe = <String, bool>{};
  final Map<String, bool> _alreadyDisputedByMe = <String, bool>{};

  // Optional local display tweak for community count
  final Map<String, int> _localReportCounts = <String, int>{};

  // --- Map + sheet tuning ---
  static const double _oneCardSheetApproxPx = 260.0;

  String _placeKey(Map m) {
    final ext = m['externalId']?.toString();
    if (ext != null && ext.isNotEmpty) return 'g:$ext';
    final pid = m['googlePlaceId']?.toString();
    if (pid != null && pid.isNotEmpty) return 'g:$pid';
    final id = m['id']?.toString();
    return (id != null && id.isNotEmpty) ? id : '';
  }

  Future<void> _loadLocalProposals() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Upgrade legacy -> CERTIFY
      final legacy = prefs.getStringList(_prefsKeyProposedLegacy) ?? const <String>[];
      for (final k in legacy) {
        _alreadyProposedCertByMe[k] = true;
      }

      // New buckets
      final cert = prefs.getStringList(_prefsKeyProposedCert) ?? const <String>[];
      final dispute = prefs.getStringList(_prefsKeyProposedDispute) ?? const <String>[];

      for (final k in cert) {
        _alreadyProposedCertByMe[k] = true;
      }
      for (final k in dispute) {
        _alreadyDisputedByMe[k] = true;
      }

      // restore last query/near/radius
      final q = prefs.getString(_prefsKeyLastQuery);
      final near = prefs.getString(_prefsKeyLastNear);
      final radius = prefs.getDouble(_prefsKeyLastRadiusKm);
      final exp = prefs.getBool(_prefsKeyRadiusExpanded);

      if (q != null && q.isNotEmpty) _qCtrl.text = q;
      if (near != null) _nearCtrl.text = near;
      if (radius != null) _radiusKm = radius;
      if (exp != null) _radiusExpanded = exp;

      setStateSafe(() {});
    } catch (_) {}
  }

  Future<void> _saveLocalProposalKey(String key, String intent) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final listName =
      (intent.toUpperCase() == 'DISPUTE') ? _prefsKeyProposedDispute : _prefsKeyProposedCert;

      final list = prefs.getStringList(listName) ?? <String>[];
      if (!list.contains(key)) {
        list.add(key);
        await prefs.setStringList(listName, list);
      }

      // Do not write to legacy again; we only read it for upgrade.
    } catch (_) {}
  }

  Future<void> _persistSearchInputs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKeyLastQuery, _qCtrl.text.trim());
      await prefs.setString(_prefsKeyLastNear, _nearCtrl.text.trim());
      await prefs.setDouble(_prefsKeyLastRadiusKm, _radiusKm);
      await prefs.setBool(_prefsKeyRadiusExpanded, _radiusExpanded);
    } catch (_) {}
  }

  // Map
  GoogleMapController? _mapCtrl;
  final Set<Marker> _markers = <Marker>{};
  LatLng _center = const LatLng(51.5074, -0.1278);
  double _radiusKm = 5.0;

  static const _fallbackCamera =
  CameraPosition(target: LatLng(51.5074, -0.1278), zoom: 11);

  // Sheet
  final DraggableScrollableController _sheetCtrl =
  DraggableScrollableController();
  static const double _sheetMin = 0.12;
  static const double _sheetInit = 0.20;
  static const double _sheetMax = 0.75;

  // UX
  Timer? _radiusDebounce;
  int _requestSerial = 0;
  bool _didBootstrapCenter = false;
  int _expandedIndex = -1;
  String? _selectedMarkerId;

  bool _radiusExpanded = true;

  // Search header measurement
  final GlobalKey _searchCardKey = GlobalKey();
  double _searchCardBottomPx = 0.0;
  double get _mapTopUiPaddingPx => _searchCardBottomPx + 8.0;

  // Keep a handle to the results ListView’s controller so we can auto-scroll.
  ScrollController? _resultsScrollCtrl;

  // One GlobalKey per list item to ensureVisible() precisely.
  List<GlobalKey> _itemKeys = const [];

  // ===== lifecycle =====
  @override
  void initState() {
    super.initState();
    _loadLocalProposals();
    _bootstrapLocationCenter();
    _sheetCtrl.addListener(_onSheetSizeChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _measureSearchCard();
      _applyMapPadding(); // safe no-op
    });
  }

  @override
  void dispose() {
    _qCtrl.dispose();
    _nearCtrl.dispose();
    _radiusDebounce?.cancel();
    _sheetCtrl.removeListener(_onSheetSizeChanged);
    _sheetCtrl.dispose();
    _mapCtrl?.dispose();
    super.dispose();
  }

  // Safe setState
  void setStateSafe(VoidCallback fn) {
    if (!mounted) return;
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(fn);
      });
    } else {
      setState(fn);
    }
  }

  // ===== Units =====
  bool get _useMiles {
    final cc = Localizations.localeOf(context).countryCode?.toUpperCase();
    return cc == 'GB' || cc == 'US' || cc == 'LR' || cc == 'MM';
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

  // ===== Helpers =====
  double? _asDouble(dynamic v) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }

  bool _isTrue(dynamic x) => x == true;
  int _asInt(dynamic x) => (x is num) ? x.toInt() : 0;

  // Build proposals endpoint from restaurantsSearchEndpoint host.
  Uri _halalProposalsUri() {
    final rs = Uri.parse(AppConfig.restaurantsSearchEndpoint);
    return Uri(
      scheme: rs.scheme,
      host: rs.host,
      port: rs.hasPort ? rs.port : null,
      path: '/api/halal/proposals',
    );
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

  Future<void> _bootstrapLocationCenter() async {
    if (_didBootstrapCenter) return;
    _didBootstrapCenter = true;

    final pos = await _tryGetPosition();
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

  /// Prefer a backend-provided Google Maps URL if present; else fall back to geo:lat,lng.
  Future<void> _openMapsUrlOrLatLng(Map m, double? lat, double? lng, String name) async {
    final rawUrl = m['googleMapsUrl']?.toString();
    if (rawUrl != null && rawUrl.isNotEmpty) {
      try {
        final uri = Uri.parse(rawUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          return;
        }
      } catch (_) {
        // fall through to lat/lng
      }
    }
    if (lat != null && lng != null) {
      await _openInMaps(lat, lng, name);
    }
  }

  Future<void> _focusMapOnItem(Map e, {double minZoom = 16}) async {
    final lat = _asDouble(e['latitude']);
    final lng = _asDouble(e['longitude']);
    if (_mapCtrl == null || lat == null || lng == null) return;

    final currentZoom = await _mapCtrl!.getZoomLevel();
    final target = LatLng(lat, lng);

    await _mapCtrl!.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: target, zoom: math.max(currentZoom, minZoom)),
      ),
    );
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
      final isSelected = _expandedIndex == i;
      // Selected: gold accent (45°), Default: emerald teal (174°)
      final hue = isSelected ? BitmapDescriptor.hueOrange : 174.0;

      final key = _placeKey(e);
      final id = key.isNotEmpty ? 'r_$key' : 'r_$i';

      markers.add(
        Marker(
          markerId: MarkerId(id),
          icon: BitmapDescriptor.defaultMarkerWithHue(hue),
          position: LatLng(lat, lng),
          infoWindow: InfoWindow(
            title: name,
            snippet: address,
            onTap: () => _openMapsUrlOrLatLng(e, lat, lng, name),
          ),
          onTap: () => _onMarkerTap(i),
        ),
      );
    }
    setStateSafe(() {
      _markers
        ..clear()
        ..addAll(markers);
      _applyMapPadding();
    });
  }

  // ===== Map padding to avoid UI overlap =====
  Future<void> _applyMapPadding() async {
    if (_mapCtrl == null) return;
  }

  void _onSheetSizeChanged() {
    _applyMapPadding();
  }

  // ===== Distance + external maps =====
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
    final m = _haversineMeters(_center.latitude, _center.longitude, lat, lng);
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

  Future<void> _callPhone(String phone) async {
    final sanitized = phone.replaceAll(' ', '');
    final uri = Uri.parse('tel:$sanitized');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _openWebsite(String url) async {
    Uri uri;
    try {
      uri = Uri.parse(url);
    } catch (_) {
      return;
    }
    if (!uri.hasScheme) {
      uri = Uri.parse('https://$url');
    }
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  // ===== Dialogs / toasts =====
  Future<String?> _promptEvidence() async {
    final ctrl = TextEditingController();
    String? val;
    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Optional evidence'),
          content: TextField(
            controller: ctrl,
            decoration: const InputDecoration(
              hintText: 'e.g., “HMC sticker on the door” or a URL',
            ),
            maxLines: 3,
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                val = ctrl.text.trim();
                Navigator.pop(ctx);
              },
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );
    return (val != null && val!.isEmpty) ? null : val;
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // ===== Sheet sizing / snapping =====
  void _measureSearchCard() {
    final ctx = _searchCardKey.currentContext;
    if (ctx == null) return;
    final box = ctx.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return;
    final topLeft = box.localToGlobal(Offset.zero);
    final bottom = topLeft.dy + box.size.height;
    setStateSafe(() {
      _searchCardBottomPx = bottom;
      _applyMapPadding();
    });
  }

  double _sizeForTopGapPx(double topGapPx) {
    final h = MediaQuery.of(context).size.height;
    if (h <= 0) return _sheetInit;
    final desired = 1.0 - (topGapPx / h);
    return desired.clamp(_sheetMin, _sheetMax);
  }

  double _sizeForSheetHeightPx(double sheetPx) {
    final h = MediaQuery.of(context).size.height;
    if (h <= 0) return _sheetInit;
    return (sheetPx / h).clamp(_sheetMin, _sheetMax);
  }

  void _snapSheetUnderSearch() {
    final target = _sizeForTopGapPx(_searchCardBottomPx + 8);
    _sheetCtrl.animateTo(
      target,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
  }

  void _collapseSheetToOneCard() {
    final target = _sizeForSheetHeightPx(_oneCardSheetApproxPx);
    _sheetCtrl.animateTo(
      target,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  void _toggleSheetSnapTap() {
    final target = _sizeForTopGapPx(_searchCardBottomPx + 8);
    final sz = _sheetCtrl.size;
    final mid = (target + _sheetMin) / 2;
    final goUp = sz < (mid - 0.02);
    _sheetCtrl.animateTo(
      goUp ? target : _sheetMin,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
  }

  void _collapseSheet() {
    _sheetCtrl.animateTo(
      _sheetMin,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
  }

  void _expandSheetToContent() => _snapSheetUnderSearch();

  void _dragSheetByPixels(double deltaPixels) {
    final h = MediaQuery.of(context).size.height;
    final current = _sheetCtrl.size;
    final delta = -deltaPixels / h;
    final next = (current + delta).clamp(_sheetMin, _sheetMax);
    _sheetCtrl.jumpTo(next);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _measureSearchCard();
      _applyMapPadding();
    });
  }

  // ===== Search =====
  Future<void> _search() async {
    if (_loading) return;
    FocusScope.of(context).unfocus();

    setStateSafe(() {
      _loading = true;
      _error = null;
      _items = [];
      _markers.clear();
      _expandedIndex = -1;
      _selectedMarkerId = null;
      _itemKeys = const []; // reset keys on new search
      _submittingIdx.clear();
    });

    final myTurn = ++_requestSerial;

    try {
      final q = _qCtrl.text.trim();
      final near = _nearCtrl.text.trim();

      // persist inputs
      _persistSearchInputs();

      Position? pos;
      if (near.isEmpty) {
        pos = await _tryGetPosition();
      }

      // Token is optional — restaurant search is free for guests + logged-in users
      final token = await FirebaseAuth.instance.currentUser?.getIdToken();

      final headers = <String, String>{
        if (token != null) 'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      };

      final qp = <String, String>{
        'page': '1',
        'pageSize': '20',
        'radiusMeters': (_radiusKm * 1000).round().toString(),
        'sort': 'distance',
        if (q.isNotEmpty) 'query': q,
        if (near.isNotEmpty) 'near': near,
        if (pos != null) 'lat': pos.latitude.toString(),
        if (pos != null) 'lng': pos.longitude.toString(),
      };

      final uri = Uri.parse(AppConfig.restaurantsSearchEndpoint)
          .replace(queryParameters: qp);

      if (kDebugMode) debugPrint('[Search] GET $uri');

      final resp = await HttpClientBinding.get(uri, headers: headers);

      if (resp.statusCode < 200 || resp.statusCode >= 300) {
        throw Exception('Restaurant search failed (${resp.statusCode})');
      }

      // Parse in background isolate
      final items = await compute(_parseRestaurantsIsolate, resp.body);

      if (myTurn != _requestSerial) return;

      // Build keys once we know the item count and fold in local vote memory
      _itemKeys = List<GlobalKey>.generate(items.length, (_) => GlobalKey());

      for (final e in items) {
        if (e is! Map) continue;
        final k = _placeKey(e);
        if (k.isEmpty) continue;

        // annotate with my local actions
        if (_alreadyProposedCertByMe[k] == true) {
          e['alreadyProposedByMe'] = true; // legacy flag for CERTIFY
        }
        if (_alreadyDisputedByMe[k] == true) {
          e['alreadyDisputedByMe'] = true;
        }

        final localCnt = _localReportCounts[k];
        if (localCnt != null) {
          final current = _asInt(e['communityHalalCount']);
          if (localCnt > current) {
            e['communityHalalCount'] = localCnt;
          }
        }
      }

      setStateSafe(() => _items = items);
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
      setStateSafe(
              () => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (!mounted || myTurn != _requestSerial) return;
      setStateSafe(() => _loading = false);
    }
  }

  // ===== Selection handlers =====
  Future<void> _onMarkerTap(int index) async {
    if (_expandedIndex == index) {
      setStateSafe(() => _expandedIndex = -1);
      _selectedMarkerId = null;
    } else {
      setStateSafe(() => _expandedIndex = index);
      _selectedMarkerId = 'r$index';
    }
    _rebuildMarkersFromItems();

    HapticFeedback.selectionClick();

    await _focusMapOnItem(_items[index] as Map);
    _scrollToIndex(index);

    // Collapse to one-card view
    _collapseSheetToOneCard();
  }

  Future<void> _onCardTap(int index, Map m) async {
    if (_expandedIndex == index) {
      setStateSafe(() => _expandedIndex = -1);
      _selectedMarkerId = null;
    } else {
      setStateSafe(() => _expandedIndex = index);
      _selectedMarkerId = 'r$index';
    }
    _rebuildMarkersFromItems();

    HapticFeedback.selectionClick();

    await _focusMapOnItem(m);
    _scrollToIndex(index);

    // Collapse to one-card view
    _collapseSheetToOneCard();
  }

  // Smoothly scroll the results list to a given index using GlobalKey.
  void _scrollToIndex(int index) {
    try {
      final key =
      (index >= 0 && index < _itemKeys.length) ? _itemKeys[index] : null;
      final ctx = key?.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(
          ctx,
          alignment: 0.02, // keep the selected card near the top of the sheet
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
        );
      } else if (_resultsScrollCtrl != null) {
        _resultsScrollCtrl!.animateTo(
          _resultsScrollCtrl!.offset + 180.0,
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOut,
        );
      }
    } catch (_) {}
  }

  // ===== Proposal submit =====
  bool _isVerified(Map m) {
    final status = m['halalStatusEffective']?.toString().toUpperCase();
    return (m['isVerifiedHalal'] == true) ||
        (m['halalVerified'] == true) ||
        status == 'CERTIFIED' ||
        status == 'ADMIN_VERIFIED';
  }

  bool _canCertify(Map m) {
    final provider = (m['provider']?.toString() ?? '').toLowerCase();
    final hasGoogleId = (m['externalId']?.toString().isNotEmpty ?? false);
    final alreadyCert = m['alreadyProposedByMe'] == true;
    return provider == 'google' && hasGoogleId && !_isVerified(m) && !alreadyCert;
  }

  bool _canDispute(Map m) {
    final provider = (m['provider']?.toString() ?? '').toLowerCase();
    final hasGoogleId = (m['externalId']?.toString().isNotEmpty ?? false);
    final alreadyDispute = m['alreadyDisputedByMe'] == true;
    return provider == 'google' && hasGoogleId && _isVerified(m) && !alreadyDispute;
  }

  Future<void> _submitProposal(int index, Map m, {required String intent}) async {
    if (_submittingIdx.contains(index)) return;

    final key = _placeKey(m);

    // Block double-submit based on the specific intent
    if (intent.toUpperCase() == 'DISPUTE') {
      if (key.isNotEmpty && _alreadyDisputedByMe[key] == true) {
        _toast('You already disputed this verification.');
        return;
      }
    } else {
      if (key.isNotEmpty && _alreadyProposedCertByMe[key] == true) {
        _toast('You already submitted a report for this place.');
        return;
      }
    }

    final evidence = await _promptEvidence();
    final token = await FirebaseAuth.instance.currentUser?.getIdToken();
    if (token == null) {
      _toast('Not signed in.');
      return;
    }

    final lat = _asDouble(m['latitude']);
    final lng = _asDouble(m['longitude']);
    final googlePlaceId = m['externalId']?.toString() ?? '';

    if (googlePlaceId.isEmpty || lat == null || lng == null) {
      _toast('Missing place information.');
      return;
    }

    setStateSafe(() => _submittingIdx.add(index));

    try {
      final body = jsonEncode({
        // Preferred modern payload the backend accepts
        'provider': 'google',
        'externalId': googlePlaceId,
        'evidenceText': evidence,
        'evidenceUrls': <String>[],
        'intent': intent, // <<<<<<<< IMPORTANT
        // Legacy fields still included harmlessly
        'googlePlaceId': googlePlaceId,
        'name': m['name']?.toString() ?? '',
        'lat': lat,
        'lng': lng,
        'address': m['address']?.toString(),
      });

      final resp = await HttpClientBinding.post(
        _halalProposalsUri(),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: body,
      );

      if (resp.statusCode == 409) {
        // already submitted (for that intent) — set local flags
        if (key.isNotEmpty) {
          await _saveLocalProposalKey(key, intent);
          if (intent.toUpperCase() == 'DISPUTE') {
            _alreadyDisputedByMe[key] = true;
            setStateSafe(() => m['alreadyDisputedByMe'] = true);
          } else {
            _alreadyProposedCertByMe[key] = true;
            setStateSafe(() => m['alreadyProposedByMe'] = true);
          }
        }
        _toast(intent.toUpperCase() == 'DISPUTE'
            ? 'You already disputed this place.'
            : 'You already submitted a report for this place.');
        return;
      }

      if (resp.statusCode < 200 || resp.statusCode >= 300) {
        throw Exception('Server responded ${resp.statusCode}');
      }

      // Optimistic local state
      if (key.isNotEmpty) {
        await _saveLocalProposalKey(key, intent);
        if (intent.toUpperCase() == 'DISPUTE') {
          _alreadyDisputedByMe[key] = true;
          setStateSafe(() => m['alreadyDisputedByMe'] = true);
        } else {
          _alreadyProposedCertByMe[key] = true;
          setStateSafe(() => m['alreadyProposedByMe'] = true);

          // bump the community count for certify flows only
          final current = _asInt(m['communityHalalCount']);
          final next = current + 1;
          _localReportCounts[key] = next;
          m['communityHalalCount'] = next;
        }
      }

      _toast(intent.toUpperCase() == 'DISPUTE'
          ? 'Thanks — dispute submitted'
          : 'Thanks! We’ll review shortly.');
    } catch (e) {
      _toast('Failed to submit: ${e.toString().replaceFirst('Exception: ', '')}');
    } finally {
      if (mounted) setStateSafe(() => _submittingIdx.remove(index));
    }
  }

  Widget _chip(String text, {Color? bg, Color? fg, IconData? icon}) {
    final chipBg = bg ?? AppColors.primary.withOpacity(0.08);
    final chipFg = fg ?? AppColors.textPrimary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: chipBg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: (bg != null ? bg.withOpacity(0.4) : AppColors.primary.withOpacity(0.2)),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: chipFg),
            const SizedBox(width: 6),
          ],
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: chipFg,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ===== Build =====
  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    // ADAPTIVE min size to avoid bottom overflow when the keyboard is open.
    final minSizeAdaptive = bottomInset > 0 ? 0.18 : _sheetMin;

    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text('Restaurant Lookup'),
        elevation: 0,
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
      ),
      body: Stack(
        children: [
          // Map
          Positioned.fill(
            child: RestaurantMap(
              initialCamera: _fallbackCamera,
              markers: _markers,
              onMapCreated: (c) async {
                _mapCtrl = c;
                await UmmalyMapStyles.apply(c, context);
                _applyMapPadding(); // safe no-op
                await _bootstrapLocationCenter();
                await _fitMapToPinsRespectingRadius();
              },
              myLocationEnabled: true,
              onRecenter: _fitMapToPinsRespectingRadius,
              recenterTop: 140,
            ),
          ),

          // Search header
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.l, AppSpacing.l, AppSpacing.l, 0),
              child: SearchHeader(
                key: _searchCardKey,
                qController: _qCtrl,
                nearController: _nearCtrl,
                radiusKm: _radiusKm,
                radiusExpanded: _radiusExpanded,
                useMiles: _useMiles,
                radiusLabel: _radiusLabel(),
                onMeasureRequested: () {
                  _measureSearchCard();
                  _applyMapPadding();
                },
                onCollapseSheet: _collapseSheet,

                // When radius expands, drop results; when it collapses, do nothing.
                onToggleRadius: () {
                  setStateSafe(() => _radiusExpanded = !_radiusExpanded);
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _measureSearchCard();
                    _applyMapPadding();
                  });
                  if (_radiusExpanded) {
                    _collapseSheet();
                  }
                  _persistSearchInputs();
                },

                onSearchPressed: () {
                  if (_radiusExpanded) {
                    setStateSafe(() => _radiusExpanded = false);
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _measureSearchCard();
                      _applyMapPadding();
                    });
                  }
                  _search();
                  _snapSheetUnderSearch();
                },
                onSubmit: () {
                  if (_radiusExpanded) {
                    setStateSafe(() => _radiusExpanded = false);
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _measureSearchCard();
                      _applyMapPadding();
                    });
                  }
                  _search();
                  _snapSheetUnderSearch();
                },
                onPresetTap: (double valueInUnits) {
                  final km = _useMiles ? (valueInUnits / _kmToMi) : valueInUnits;
                  setStateSafe(() => _radiusKm = km);
                  _persistSearchInputs();
                  _search();
                },
                onRadiusChanged: (double v) {
                  setStateSafe(() => _radiusKm = v);
                  _persistSearchInputs();
                  _radiusDebounce?.cancel();
                  _radiusDebounce =
                      Timer(const Duration(milliseconds: 250), _search);
                },
                onRadiusChangeEnd: (_) {
                  _radiusDebounce?.cancel();
                  _persistSearchInputs();
                  _search();
                },
              ),
            ),
          ),

          // Results sheet
          ResultsSheet(
            controller: _sheetCtrl,
            initialSize: _sheetInit,
            minSize: minSizeAdaptive, // adaptive to keyboard
            maxSize: _sheetMax,
            bottomInset: bottomInset,
            title: _error != null
                ? 'Error'
                : _items.isEmpty
                ? 'Results'
                : '${_items.length} places found',
            onHeaderTap: _toggleSheetSnapTap,
            onHeaderDragUpdate: (d) => _dragSheetByPixels(d.primaryDelta ?? 0),
            error: _error,
            loading: _loading,
            isEmpty: _items.isEmpty,
            onRetry: _search,
            bodyBuilder: (scrollController) {
              _resultsScrollCtrl ??= scrollController;

              return ListView.builder(
                controller: _resultsScrollCtrl,
                keyboardDismissBehavior:
                ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.l, 0, AppSpacing.l, AppSpacing.l),
                itemCount: _items.length,
                itemBuilder: (context, i) {
                  final item = _items[i];
                  if (item is! Map) return const SizedBox.shrink();
                  final m = item;
                  final name = m['name']?.toString() ?? 'Unknown';
                  final address = m['address']?.toString() ?? '';
                  final lat = _asDouble(m['latitude']);
                  final lng = _asDouble(m['longitude']);
                  final dist = (lat != null && lng != null)
                      ? _distanceLabel(lat, lng)
                      : null;

                  // New halal field handling (backward-compatible):
                  final halalVerified = _isVerified(m);
                  final status =
                  m['halalStatusEffective']?.toString().toUpperCase();
                  final isNotHalal = status == 'NOT_HALAL';
                  final claimedHalal =
                      (m['claimedHalal'] == true) || status == 'CLAIMED_HALAL';

                  final communityCount = _asInt(m['communityHalalCount']);

                  // Intent-specific "already by me" flags
                  final k = _placeKey(m);
                  final alreadyCert =
                      m['alreadyProposedByMe'] == true || _alreadyProposedCertByMe[k] == true;
                  final alreadyDispute =
                      m['alreadyDisputedByMe'] == true || _alreadyDisputedByMe[k] == true;

                  final canCert = _canCertify(m);
                  final canDispute = _canDispute(m);

                  final isExpanded = i == _expandedIndex;

                  final phone = m['phone']?.toString();
                  final website = m['website']?.toString();
                  final mapsUrl = m['googleMapsUrl']?.toString();
                  final hasDirections =
                      (lat != null && lng != null) || (mapsUrl != null && mapsUrl.isNotEmpty);

                  return Container(
                    key: (i < _itemKeys.length) ? _itemKeys[i] : null,
                    margin: const EdgeInsets.only(bottom: AppSpacing.s),
                    child: RestaurantCardLite(
                      name: name,
                      address: address,
                      rating: (m['rating'] as num?)?.toDouble() ??
                          (m['googleRating'] as num?)?.toDouble(),
                      ratingCount: (m['ratingCount'] as num?)?.toInt() ??
                          (m['googleUserRatings'] as num?)?.toInt(),
                      categories: (m['categories'] as List?)
                          ?.map((e) => e.toString())
                          .toList() ??
                          const [],
                      provider:
                      m['provider']?.toString().toUpperCase() ?? 'EXT',
                      priceLevel: (m['priceLevel'] as num?)?.toInt(),
                      distance: dist,
                      phone: phone,
                      website: website,
                      openingNow: m['openingNow'] as bool?,
                      openingHours: (m['openingHours'] as List?)
                          ?.map((e) => e.toString())
                          .toList(),
                      isExpanded: isExpanded,
                      onTap: () => _onCardTap(i, m),
                      onDirections: hasDirections
                          ? () => _openMapsUrlOrLatLng(m, lat, lng, name)
                          : null,
                      onCall: (phone != null && phone.isNotEmpty)
                          ? () => _callPhone(phone)
                          : null,
                      onOpenWebsite: (website != null && website.isNotEmpty)
                          ? () => _openWebsite(website)
                          : null,

                      // Chips + action row INSIDE the card
                      footer: !isExpanded
                          ? null
                          : Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          if (halalVerified)
                            _chip(
                              'Halal (Verified)',
                              bg: AppColors.halal.withOpacity(0.1),
                              fg: AppColors.halal,
                              icon: Icons.verified,
                            ),
                          if (!halalVerified && isNotHalal)
                            _chip(
                              'Not Halal',
                              bg: AppColors.haram.withOpacity(0.1),
                              fg: AppColors.haram,
                              icon: Icons.block,
                            ),
                          if (!halalVerified &&
                              !isNotHalal &&
                              (claimedHalal || communityCount > 0))
                            _chip(
                              communityCount > 0
                                  ? 'Claimed halal • $communityCount reports'
                                  : 'Claimed halal',
                              bg: AppColors.conditional.withOpacity(0.1),
                              fg: AppColors.conditional,
                              icon: Icons.info_outline,
                            ),

                          // My actions
                          if (halalVerified && alreadyDispute)
                            _chip(
                              'You disputed',
                              bg: AppColors.primary.withOpacity(0.1),
                              fg: AppColors.primary,
                              icon: Icons.person,
                            ),
                          if (!halalVerified && alreadyCert)
                            _chip(
                              'You reported',
                              bg: AppColors.primary.withOpacity(0.1),
                              fg: AppColors.primary,
                              icon: Icons.person,
                            ),

                          // Buttons (intent-aware)
                          if (!halalVerified && canCert)
                            Padding(
                              padding: const EdgeInsets.only(left: 4),
                              child: OutlinedButton.icon(
                                icon: _submittingIdx.contains(i)
                                    ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                                    : const Icon(Icons.add_task),
                                label: Text(alreadyCert
                                    ? 'Submitted'
                                    : 'Mark as halal'),
                                onPressed: _submittingIdx.contains(i)
                                    ? null
                                    : () => _submitProposal(i, m, intent: 'CERTIFY'),
                              ),
                            ),

                          if (halalVerified && canDispute)
                            Padding(
                              padding: const EdgeInsets.only(left: 4),
                              child: OutlinedButton.icon(
                                icon: _submittingIdx.contains(i)
                                    ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                                    : const Icon(Icons.report_gmailerrorred),
                                label: const Text('Dispute verification'),
                                onPressed: _submittingIdx.contains(i)
                                    ? null
                                    : () => _submitProposal(i, m, intent: 'DISPUTE'),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
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
