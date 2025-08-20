import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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

  // Track per-item submit spinners for "Mark as halal"
  final Set<int> _submittingIdx = <int>{};

  // Persisted memory of my proposals (across sessions)
  static const String _prefsKeyProposed = 'halalProposedKeys';
  final Map<String, bool> _alreadyProposedByMe = <String, bool>{};
  final Map<String, int> _localReportCounts = <String, int>{};

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
      final saved = prefs.getStringList(_prefsKeyProposed) ?? const <String>[];
      setState(() {
        for (final k in saved) {
          _alreadyProposedByMe[k] = true;
        }
      });
    } catch (_) {}
  }

  Future<void> _saveLocalProposalKey(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getStringList(_prefsKeyProposed) ?? <String>[];
      if (!saved.contains(key)) {
        saved.add(key);
        await prefs.setStringList(_prefsKeyProposed, saved);
      }
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

  @override
  void initState() {
    super.initState();
    _loadLocalProposals();
    _bootstrapLocationCenter();
    WidgetsBinding.instance.addPostFrameCallback((_) => _measureSearchCard());
  }

  @override
  void dispose() {
    _qCtrl.dispose();
    _nearCtrl.dispose();
    _radiusDebounce?.cancel();
    _mapCtrl?.dispose();
    super.dispose();
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
    final rs = Uri.parse(Config.restaurantsSearchEndpoint);
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

  // Improved centering with generous vertical offset so pin isn’t under header/sheet.
  Future<void> _centerOnItemWithOffset(Map e, {double? yOffsetPx}) async {
    final lat = _asDouble(e['latitude']);
    final lng = _asDouble(e['longitude']);
    if (_mapCtrl == null || lat == null || lng == null) return;

    final currentZoom = await _mapCtrl!.getZoomLevel();
    final target = LatLng(lat, lng);

    final headerPad = _mapTopUiPaddingPx;
    final sheetBias = 92.0; // approx. header + handle space of sheet
    final totalYOffset = (yOffsetPx ?? (headerPad + sheetBias));

    final sc = await _mapCtrl!.getScreenCoordinate(target);
    final adjusted = ScreenCoordinate(
      x: sc.x,
      y: (sc.y - totalYOffset).toInt(),
    );
    final newLatLng = await _mapCtrl!.getLatLng(adjusted);

    await _mapCtrl!.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: newLatLng, zoom: math.max(currentZoom, 14)),
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
      final hue = isSelected ? 140.0 : 275.0;

      markers.add(
        Marker(
          markerId: MarkerId('r$i'),
          icon: BitmapDescriptor.defaultMarkerWithHue(hue),
          position: LatLng(lat, lng),
          infoWindow: InfoWindow(
            title: name,
            snippet: address,
            onTap: () => _openInMaps(lat, lng, name),
          ),
          onTap: () => _onMarkerTap(i),
        ),
      );
    }
    setState(() {
      _markers
        ..clear()
        ..addAll(markers);
    });
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
    final apple = Uri.parse('http://maps.apple.com/?q=$query&ll=$lat,$lng'); // iOS
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
    await launchUrl(uri, mode: LaunchMode.externalApplication);
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
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
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
    setState(() {
      _searchCardBottomPx = bottom;
    });
  }

  double _sizeForTopGapPx(double topGapPx) {
    final h = MediaQuery.of(context).size.height;
    if (h <= 0) return _sheetInit;
    final desired = 1.0 - (topGapPx / h);
    return desired.clamp(_sheetMin, _sheetMax);
  }

  void _snapSheetUnderSearch() {
    final target = _sizeForTopGapPx(_searchCardBottomPx + 8);
    _sheetCtrl.animateTo(
      target,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
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
    WidgetsBinding.instance.addPostFrameCallback((_) => _measureSearchCard());
  }

  // ===== Search =====
  Future<void> _search() async {
    if (_loading) return;
    FocusScope.of(context).unfocus();

    setState(() {
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
        'radiusMeters': (_radiusKm * 1000).round().toString(),
        'sort': 'distance',
        if (q.isNotEmpty) 'query': q,
        if (near.isNotEmpty) 'near': near,
        if (pos != null) 'lat': pos.latitude.toString(),
        if (pos != null) 'lng': pos.longitude.toString(),
      };

      final uri =
      Uri.parse(Config.restaurantsSearchEndpoint).replace(queryParameters: qp);

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

      if (myTurn != _requestSerial) return;

      // Build keys once we know the item count and fold in local vote memory
      _itemKeys = List<GlobalKey>.generate(items.length, (_) => GlobalKey());

      for (final e in items) {
        if (e is! Map) continue;
        final k = _placeKey(e);
        if (k.isEmpty) continue;

        if (_alreadyProposedByMe[k] == true) {
          e['alreadyProposedByMe'] = true;
        }

        final localCnt = _localReportCounts[k];
        if (localCnt != null) {
          final current = _asInt(e['communityHalalCount']);
          if (localCnt > current) {
            e['communityHalalCount'] = localCnt;
          }
        }
      }

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

  // ===== Selection handlers =====
  Future<void> _onMarkerTap(int index) async {
    if (_expandedIndex == index) {
      setState(() => _expandedIndex = -1);
      _selectedMarkerId = null;
    } else {
      setState(() => _expandedIndex = index);
      _selectedMarkerId = 'r$index';
    }
    _rebuildMarkersFromItems();

    await _centerOnItemWithOffset(_items[index] as Map);

    _scrollToIndex(index);

    _expandSheetToContent();
  }

  Future<void> _onCardTap(int index, Map m) async {
    if (_expandedIndex == index) {
      setState(() => _expandedIndex = -1);
      _selectedMarkerId = null;
    } else {
      setState(() => _expandedIndex = index);
      _selectedMarkerId = 'r$index';
    }
    _rebuildMarkersFromItems();

    await _centerOnItemWithOffset(m);

    _scrollToIndex(index);

    _expandSheetToContent();
  }

  // Smoothly scroll the results list to a given index using GlobalKey.
  void _scrollToIndex(int index) {
    try {
      final key = (index >= 0 && index < _itemKeys.length) ? _itemKeys[index] : null;
      final ctx = key?.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(
          ctx,
          alignment: 0.08,
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
  bool _canPropose(Map m) {
    final provider = (m['provider']?.toString() ?? '').toLowerCase();
    final hasGoogleId = (m['externalId']?.toString().isNotEmpty ?? false);
    final isVerified = _isTrue(m['halalVerified']);
    final already = m['alreadyProposedByMe'] == true;
    return provider == 'google' && hasGoogleId && !isVerified && !already;
  }

  Future<void> _submitProposal(int index, Map m) async {
    if (_submittingIdx.contains(index)) return;

    final key = _placeKey(m);
    if (key.isNotEmpty && _alreadyProposedByMe[key] == true) {
      _toast('You already submitted a report for this place.');
      return;
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

    setState(() => _submittingIdx.add(index));

    try {
      final body = jsonEncode({
        'googlePlaceId': googlePlaceId,
        'evidenceText': evidence,
        'evidenceUrls': <String>[],
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
        if (key.isNotEmpty) {
          _alreadyProposedByMe[key] = true;
          _saveLocalProposalKey(key);
        }
        setState(() {
          m['alreadyProposedByMe'] = true;
        });
        _toast('You already submitted a report for this place.');
        return;
      }

      if (resp.statusCode < 200 || resp.statusCode >= 300) {
        throw Exception('Server responded ${resp.statusCode}');
      }

      // Optimistic bump + mark submitted + persist
      final current = _asInt(m['communityHalalCount']);
      final next = current + 1;

      if (key.isNotEmpty) {
        _alreadyProposedByMe[key] = true;
        _localReportCounts[key] = next;
        _saveLocalProposalKey(key);
      }

      setState(() {
        m['communityHalalCount'] = next;
        m['alreadyProposedByMe'] = true;
      });

      _toast('Thanks! We’ll review shortly.');
    } catch (e) {
      _toast('Failed to submit: ${e.toString().replaceFirst('Exception: ', '')}');
    } finally {
      if (mounted) setState(() => _submittingIdx.remove(index));
    }
  }

  Widget _chip(String text, {Color? bg, Color? fg, IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: bg ?? Colors.black12,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: fg ?? Colors.black87),
            const SizedBox(width: 6),
          ],
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: fg ?? Colors.black87,
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
                await _bootstrapLocationCenter();
                await _fitMapToPinsRespectingRadius();
              },
              myLocationEnabled: true,
              onRecenter: _fitMapToPinsRespectingRadius,
              recenterTop: 140,
            ),
          ),

          // Re-center floating button (below the search header)
          Positioned(
            top: _mapTopUiPaddingPx,
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
                onMeasureRequested: _measureSearchCard,
                onCollapseSheet: _collapseSheet,

                // Flipped behavior: when radius EXPANDS, drop results; when it collapses, do nothing.
                onToggleRadius: () {
                  setState(() => _radiusExpanded = !_radiusExpanded);
                  WidgetsBinding.instance
                      .addPostFrameCallback((_) => _measureSearchCard());
                  if (_radiusExpanded) {
                    _collapseSheet();
                  }
                },

                onSearchPressed: () {
                  if (_radiusExpanded) {
                    setState(() => _radiusExpanded = false);
                    WidgetsBinding.instance
                        .addPostFrameCallback((_) => _measureSearchCard());
                  }
                  _search();
                  _snapSheetUnderSearch();
                },
                onSubmit: () {
                  if (_radiusExpanded) {
                    setState(() => _radiusExpanded = false);
                    WidgetsBinding.instance
                        .addPostFrameCallback((_) => _measureSearchCard());
                  }
                  _search();
                  _snapSheetUnderSearch();
                },
                onPresetTap: (double valueInUnits) {
                  final km = _useMiles ? (valueInUnits / _kmToMi) : valueInUnits;
                  setState(() => _radiusKm = km);
                  _search();
                },
                onRadiusChanged: (double v) {
                  setState(() => _radiusKm = v);
                  _radiusDebounce?.cancel();
                  _radiusDebounce =
                      Timer(const Duration(milliseconds: 250), _search);
                },
                onRadiusChangeEnd: (_) {
                  _radiusDebounce?.cancel();
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
                  final m = _items[i] as Map;
                  final name = m['name']?.toString() ?? 'Unknown';
                  final address = m['address']?.toString() ?? '';
                  final lat = _asDouble(m['latitude']);
                  final lng = _asDouble(m['longitude']);
                  final dist =
                  (lat != null && lng != null) ? _distanceLabel(lat, lng) : null;

                  final halalVerified = _isTrue(m['halalVerified']);
                  final claimedHalal = _isTrue(m['claimedHalal']);
                  final communityCount = _asInt(m['communityHalalCount']);
                  final canMark = _canPropose(m);
                  final alreadyByMe = m['alreadyProposedByMe'] == true;

                  final isExpanded = i == _expandedIndex;

                  final phone = m['phone']?.toString();
                  final website = m['website']?.toString();

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
                      onDirections: (lat != null && lng != null)
                          ? () => _openInMaps(lat, lng, name)
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
                              'Halal Verified',
                              bg: const Color(0xFFE6F5EC),
                              fg: const Color(0xFF0A7F3F),
                              icon: Icons.verified,
                            ),
                          if (!halalVerified &&
                              (claimedHalal || communityCount > 0))
                            _chip(
                              communityCount > 0
                                  ? 'Claimed halal • $communityCount reports'
                                  : 'Claimed halal',
                              bg: const Color(0xFFFFF3E0),
                              fg: const Color(0xFF9A5B00),
                              icon: Icons.info_outline,
                            ),
                          if (alreadyByMe)
                            _chip(
                              'You reported',
                              bg: const Color(0xFFE8EAF6),
                              fg: const Color(0xFF303F9F),
                              icon: Icons.person,
                            ),
                          if (!halalVerified && canMark)
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
                                label: Text(alreadyByMe
                                    ? 'Submitted'
                                    : 'Mark as halal'),
                                onPressed: _submittingIdx.contains(i)
                                    ? null
                                    : () => _submitProposal(i, m),
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
