import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

/// Provides daily-rotating Islamic content for the Five Pillars section.
/// Content rotates based on the day of the year, so users see something
/// new every day without needing a backend API.
///
/// Call [PillarContentService.init()] once at app startup to pre-load all
/// JSON data.  After that, use [PillarContentService.instance] everywhere.
class PillarContentService {
  PillarContentService._();
  static final instance = PillarContentService._();

  // Whether JSON data has been loaded.
  bool _loaded = false;

  // ============================================================
  // DATA POOLS — populated from JSON assets
  // ============================================================
  List<Map<String, dynamic>> _quranicVerses = [];
  List<Map<String, dynamic>> _hadiths = [];
  List<Map<String, dynamic>> _proverbs = [];

  // Pillar-specific
  List<String> _shahadahFacts = [];
  List<String> _salahFacts = [];
  List<String> _zakatFacts = [];
  List<String> _sawmFacts = [];
  List<String> _hajjFacts = [];

  List<String> _shahadahReflections = [];
  List<String> _salahReflections = [];
  List<String> _zakatReflections = [];
  List<String> _sawmReflections = [];
  List<String> _hajjReflections = [];

  // ============================================================
  // INIT — call once at startup (e.g. in main.dart)
  // ============================================================
  static Future<void> init() async {
    final svc = instance;
    if (svc._loaded) return;

    // Load all JSON files in parallel.
    final results = await Future.wait([
      _loadJsonList('assets/islamic_data/quranic_verses.json'),   // 0
      _loadJsonList('assets/islamic_data/hadiths.json'),           // 1
      _loadJsonList('assets/islamic_data/proverbs.json'),          // 2
      _loadJsonMap('assets/islamic_data/shahadah_facts.json'),     // 3
      _loadJsonMap('assets/islamic_data/salah_facts.json'),        // 4
      _loadJsonMap('assets/islamic_data/zakat_facts.json'),        // 5
      _loadJsonMap('assets/islamic_data/sawm_facts.json'),         // 6
      _loadJsonMap('assets/islamic_data/hajj_facts.json'),         // 7
    ]);

    svc._quranicVerses = List<Map<String, dynamic>>.from(results[0] as List);
    svc._hadiths = List<Map<String, dynamic>>.from(results[1] as List);
    svc._proverbs = List<Map<String, dynamic>>.from(results[2] as List);

    final shahadah = results[3] as Map<String, dynamic>;
    final salah = results[4] as Map<String, dynamic>;
    final zakat = results[5] as Map<String, dynamic>;
    final sawm = results[6] as Map<String, dynamic>;
    final hajj = results[7] as Map<String, dynamic>;

    svc._shahadahFacts = List<String>.from(shahadah['facts'] ?? []);
    svc._salahFacts = List<String>.from(salah['facts'] ?? []);
    svc._zakatFacts = List<String>.from(zakat['facts'] ?? []);
    svc._sawmFacts = List<String>.from(sawm['facts'] ?? []);
    svc._hajjFacts = List<String>.from(hajj['facts'] ?? []);

    svc._shahadahReflections = List<String>.from(shahadah['reflections'] ?? []);
    svc._salahReflections = List<String>.from(salah['reflections'] ?? []);
    svc._zakatReflections = List<String>.from(zakat['reflections'] ?? []);
    svc._sawmReflections = List<String>.from(sawm['reflections'] ?? []);
    svc._hajjReflections = List<String>.from(hajj['reflections'] ?? []);

    svc._loaded = true;
  }

  // ============================================================
  // JSON HELPERS
  // ============================================================
  static Future<List<dynamic>> _loadJsonList(String path) async {
    try {
      final raw = await rootBundle.loadString(path);
      return json.decode(raw) as List<dynamic>;
    } catch (_) {
      return [];
    }
  }

  static Future<Map<String, dynamic>> _loadJsonMap(String path) async {
    try {
      final raw = await rootBundle.loadString(path);
      return json.decode(raw) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }

  // ============================================================
  // DAY INDEX
  // ============================================================

  /// Returns the day-of-year (0-365) used to rotate content.
  int get _dayIndex {
    final now = DateTime.now();
    return now.difference(DateTime(now.year)).inDays;
  }

  /// Pick an item from a list based on the day, with an optional offset
  /// so different sections don't show the same index.
  T _daily<T>(List<T> pool, [int offset = 0]) {
    if (pool.isEmpty) throw StateError('Content pool is empty — call PillarContentService.init() first');
    return pool[(_dayIndex + offset) % pool.length];
  }

  // ============================================================
  // DAILY QURANIC VERSE
  // ============================================================
  String get dailyVerse {
    final v = _daily(_quranicVerses);
    return '"${v['text']}"';
  }

  String get dailyVerseReference {
    final v = _daily(_quranicVerses);
    return v['ref'] as String;
  }

  String? get dailyVerseArabic {
    final v = _daily(_quranicVerses);
    return v['arabic'] as String?;
  }

  // ============================================================
  // DAILY HADITH
  // ============================================================
  String get dailyHadith {
    final h = _daily(_hadiths, 7);
    return '"${h['text']}"';
  }

  String get dailyHadithSource {
    final h = _daily(_hadiths, 7);
    return h['source'] as String;
  }

  // ============================================================
  // DAILY PROVERB / WISDOM
  // ============================================================
  String get dailyProverb {
    final p = _daily(_proverbs, 13);
    return p['text'] as String;
  }

  String get dailyProverbOrigin {
    final p = _daily(_proverbs, 13);
    return p['origin'] as String;
  }

  // ============================================================
  // PILLAR-SPECIFIC: "DID YOU KNOW?" FACTS
  // ============================================================
  String shahadahFact() => _daily(_shahadahFacts, 3);
  String salahFact() => _daily(_salahFacts, 5);
  String zakatFact() => _daily(_zakatFacts, 11);
  String sawmFact() => _daily(_sawmFacts, 17);
  String hajjFact() => _daily(_hajjFacts, 23);

  // ============================================================
  // DAILY REFLECTION PROMPTS (per pillar)
  // ============================================================
  String shahadahReflection() => _daily(_shahadahReflections, 2);
  String salahReflection() => _daily(_salahReflections, 4);
  String zakatReflection() => _daily(_zakatReflections, 6);
  String sawmReflection() => _daily(_sawmReflections, 8);
  String hajjReflection() => _daily(_hajjReflections, 10);

  // ============================================================
  // RAMADAN & HAJJ COUNTDOWNS
  // ============================================================

  /// Approximate Ramadan start dates (Hijri calendar varies).
  /// These shift ~10-11 days earlier each Gregorian year.
  static final _ramadanStarts = {
    2025: DateTime(2025, 2, 28),
    2026: DateTime(2026, 2, 18),
    2027: DateTime(2027, 2, 7),
    2028: DateTime(2028, 1, 28),
  };

  static final _hajjStarts = {
    2025: DateTime(2025, 6, 5),
    2026: DateTime(2026, 5, 26),
    2027: DateTime(2027, 5, 15),
    2028: DateTime(2028, 5, 4),
  };

  /// Returns days until next Ramadan, or current day if active.
  ({int days, bool isActive, String label}) ramadanCountdown() {
    final now = DateTime.now();
    for (final year in [now.year, now.year + 1]) {
      final start = _ramadanStarts[year];
      if (start == null) continue;
      final end = start.add(const Duration(days: 30));
      if (now.isBefore(end) && now.isAfter(start.subtract(const Duration(days: 1)))) {
        final dayOfRamadan = now.difference(start).inDays + 1;
        return (days: dayOfRamadan, isActive: true, label: 'Day $dayOfRamadan of Ramadan');
      }
      if (now.isBefore(start)) {
        final daysUntil = start.difference(now).inDays;
        return (days: daysUntil, isActive: false, label: '$daysUntil days until Ramadan');
      }
    }
    return (days: 0, isActive: false, label: 'Ramadan dates updating soon');
  }

  ({int days, bool isActive, String label}) hajjCountdown() {
    final now = DateTime.now();
    for (final year in [now.year, now.year + 1]) {
      final start = _hajjStarts[year];
      if (start == null) continue;
      final end = start.add(const Duration(days: 6));
      if (now.isBefore(end) && now.isAfter(start.subtract(const Duration(days: 1)))) {
        final dayOfHajj = now.difference(start).inDays + 1;
        return (days: dayOfHajj, isActive: true, label: 'Day $dayOfHajj of Hajj');
      }
      if (now.isBefore(start)) {
        final daysUntil = start.difference(now).inDays;
        return (days: daysUntil, isActive: false, label: '$daysUntil days until Hajj');
      }
    }
    return (days: 0, isActive: false, label: 'Hajj dates updating soon');
  }
}
