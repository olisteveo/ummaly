import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Prayer time data for a single prayer.
class PrayerTime {
  final String name;
  final String arabic;
  final String time; // "HH:mm" 24-hr format from API
  final String description;

  const PrayerTime({
    required this.name,
    required this.arabic,
    required this.time,
    required this.description,
  });

  /// Formatted 12-hour time string e.g. "05:42 AM"
  String get formatted {
    final parts = time.split(':');
    if (parts.length < 2) return time;
    var hour = int.tryParse(parts[0]) ?? 0;
    final minute = parts[1].replaceAll(RegExp(r'[^0-9]'), '');
    final amPm = hour >= 12 ? 'PM' : 'AM';
    if (hour == 0) {
      hour = 12;
    } else if (hour > 12) {
      hour -= 12;
    }
    return '${hour.toString().padLeft(2, '0')}:$minute $amPm';
  }

  /// Returns true if this prayer time has already passed today.
  bool get hasPassed {
    final parts = time.split(':');
    if (parts.length < 2) return false;
    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = int.tryParse(parts[1].replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    final now = DateTime.now();
    final prayerTime = DateTime(now.year, now.month, now.day, hour, minute);
    return now.isAfter(prayerTime);
  }
}

/// Service that fetches and caches prayer times based on user location.
/// Uses the free Aladhan API (https://aladhan.com/prayer-times-api).
class PrayerTimeService extends ChangeNotifier {
  static final PrayerTimeService _instance = PrayerTimeService._();
  static PrayerTimeService get instance => _instance;
  PrayerTimeService._();

  List<PrayerTime> _times = [];
  List<PrayerTime> get times => _times;

  String _locationName = '';
  String get locationName => _locationName;

  String _hijriDate = '';
  String get hijriDate => _hijriDate;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  DateTime? _lastFetched;

  // Calculation method: 15 = Muslim World League (good for UK)
  // School: 0 = Shafi (standard), 1 = Hanafi (Asr later)
  static const int _method = 15; // Muslim World League
  static const int _school = 0;  // Shafi

  /// Fetch prayer times for user's current location.
  /// Caches results for the day.
  Future<void> fetch({bool force = false}) async {
    final now = DateTime.now();

    // If already fetched today and not forced, skip
    if (!force &&
        _lastFetched != null &&
        _lastFetched!.day == now.day &&
        _times.isNotEmpty) {
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // 1. Get location
      final position = await _getLocation();
      if (position == null) {
        // Try cached/default UK location
        await _fetchForCoordinates(51.5074, -0.1278, 'London, UK');
        return;
      }

      // 2. Reverse geocode city name from Aladhan response
      await _fetchForCoordinates(
        position.latitude,
        position.longitude,
        null, // will extract from API response
      );
    } catch (e) {
      debugPrint('❌ PrayerTimeService error: $e');
      _error = 'Could not load prayer times';

      // Try to load from cache
      await _loadFromCache();

      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _fetchForCoordinates(
    double lat,
    double lng,
    String? fallbackCity,
  ) async {
    try {
      final now = DateTime.now();
      final url = Uri.parse(
        'https://api.aladhan.com/v1/timings/${now.day}-${now.month}-${now.year}'
        '?latitude=$lat&longitude=$lng&method=$_method&school=$_school',
      );

      final response = await http.get(url).timeout(
        const Duration(seconds: 10),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final timings = data['data']['timings'] as Map<String, dynamic>;
        final meta = data['data']['meta'] as Map<String, dynamic>?;
        final dateData = data['data']['date'] as Map<String, dynamic>?;

        // Extract location name
        final timezone = meta?['timezone'] as String? ?? '';
        if (fallbackCity != null) {
          _locationName = fallbackCity;
        } else {
          // Extract city from timezone e.g. "Europe/London" -> "London"
          _locationName = timezone.contains('/')
              ? timezone.split('/').last.replaceAll('_', ' ')
              : timezone;
        }

        // Extract Hijri date
        final hijri = dateData?['hijri'] as Map<String, dynamic>?;
        if (hijri != null) {
          final hDay = hijri['day'] ?? '';
          final hMonth = (hijri['month'] as Map<String, dynamic>?)?['en'] ?? '';
          final hYear = hijri['year'] ?? '';
          _hijriDate = '$hDay $hMonth $hYear AH';
        }

        // Parse the 5 obligatory prayer times
        _times = [
          PrayerTime(
            name: 'Fajr',
            arabic: 'الفجر',
            time: _cleanTime(timings['Fajr']),
            description: 'Dawn prayer — before sunrise',
          ),
          PrayerTime(
            name: 'Sunrise',
            arabic: 'الشروق',
            time: _cleanTime(timings['Sunrise']),
            description: 'End of Fajr time',
          ),
          PrayerTime(
            name: 'Dhuhr',
            arabic: 'الظهر',
            time: _cleanTime(timings['Dhuhr']),
            description: 'Midday prayer',
          ),
          PrayerTime(
            name: 'Asr',
            arabic: 'العصر',
            time: _cleanTime(timings['Asr']),
            description: 'Afternoon prayer',
          ),
          PrayerTime(
            name: 'Maghrib',
            arabic: 'المغرب',
            time: _cleanTime(timings['Maghrib']),
            description: 'Sunset prayer',
          ),
          PrayerTime(
            name: 'Isha',
            arabic: 'العشاء',
            time: _cleanTime(timings['Isha']),
            description: 'Night prayer',
          ),
        ];

        // Cache the results
        await _saveToCache();

        _lastFetched = now;
        _error = null;
      } else {
        _error = 'API returned ${response.statusCode}';
        await _loadFromCache();
      }
    } catch (e) {
      debugPrint('❌ PrayerTimeService fetch error: $e');
      _error = 'Could not load prayer times';
      await _loadFromCache();
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Strip timezone info from time string e.g. "05:42 (BST)" -> "05:42"
  String _cleanTime(dynamic raw) {
    if (raw == null) return '00:00';
    final s = raw.toString();
    // Remove anything in parentheses and trim
    return s.replaceAll(RegExp(r'\s*\(.*\)'), '').trim();
  }

  /// Get the next upcoming prayer.
  PrayerTime? get nextPrayer {
    for (final p in _times) {
      if (!p.hasPassed) return p;
    }
    // All prayers passed today — next is Fajr
    return _times.isNotEmpty ? _times.first : null;
  }

  /// Get time remaining until next prayer as a formatted string.
  String get timeUntilNext {
    final next = nextPrayer;
    if (next == null) return '';

    final parts = next.time.split(':');
    if (parts.length < 2) return '';

    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = int.tryParse(parts[1].replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

    final now = DateTime.now();
    var prayerTime = DateTime(now.year, now.month, now.day, hour, minute);

    // If all prayers passed, next Fajr is tomorrow
    if (prayerTime.isBefore(now)) {
      prayerTime = prayerTime.add(const Duration(days: 1));
    }

    final diff = prayerTime.difference(now);
    final hours = diff.inHours;
    final mins = diff.inMinutes % 60;

    if (hours > 0) {
      return '${hours}h ${mins}m';
    }
    return '${mins}m';
  }

  Future<Position?> _getLocation() async {
    try {
      // Check if location services are enabled
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('📍 Location services disabled, using default');
        return null;
      }

      // Check permission
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('📍 Location permission denied, using default');
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('📍 Location permission permanently denied, using default');
        return null;
      }

      // Get current position
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low, // city-level is fine
      );
    } catch (e) {
      debugPrint('📍 Location error: $e');
      return null;
    }
  }

  /// Save prayer times to SharedPreferences for offline/fast reload.
  Future<void> _saveToCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = {
        'location': _locationName,
        'hijri': _hijriDate,
        'date': DateTime.now().toIso8601String(),
        'times': _times
            .map((t) => {
                  'name': t.name,
                  'arabic': t.arabic,
                  'time': t.time,
                  'description': t.description,
                })
            .toList(),
      };
      await prefs.setString('cached_prayer_times', jsonEncode(data));
    } catch (e) {
      debugPrint('Cache save error: $e');
    }
  }

  /// Load cached prayer times.
  Future<void> _loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString('cached_prayer_times');
      if (cached == null) return;

      final data = jsonDecode(cached) as Map<String, dynamic>;
      _locationName = data['location'] ?? '';
      _hijriDate = data['hijri'] ?? '';

      final timesList = data['times'] as List<dynamic>? ?? [];
      _times = timesList
          .map((t) => PrayerTime(
                name: t['name'],
                arabic: t['arabic'],
                time: t['time'],
                description: t['description'],
              ))
          .toList();
    } catch (e) {
      debugPrint('Cache load error: $e');
    }
  }
}
