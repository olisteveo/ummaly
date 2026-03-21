// Copyright © 2025 Oliver & Haidar. All rights reserved.
// This file is part of the Ummaly project and may not be reused,
// modified, or distributed without express written permission.

import 'dart:convert';
import 'dart:ui';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:easy_localization/easy_localization.dart';

class LocaleManager {
  static final LocaleManager _instance = LocaleManager._internal();
  factory LocaleManager() => _instance;
  LocaleManager._internal();

  Locale _currentLocale = const Locale('en');
  Locale get currentLocale => _currentLocale;

  /// Full init — loads locale from Firestore if logged in.
  /// Prefer [initFromDevice] at startup to avoid blocking on network.
  Future<void> init() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await _loadLocaleFromFirestore(user.uid);
    } else {
      _setLocaleFromDevice();
    }
  }

  /// Fast init — uses device locale only (no network call).
  /// The server-side language preference is loaded later by AuthGate.
  void initFromDevice() {
    _setLocaleFromDevice();
  }

  /// Loads saved locale from Firestore if available.
  Future<void> _loadLocaleFromFirestore(String userId) async {
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      final langCode = doc.data()?['language_preference'];
      if (langCode != null) {
        _currentLocale = Locale(langCode);
      } else {
        _setLocaleFromDevice();
      }
    } catch (e) {
      _setLocaleFromDevice();
    }
  }

  /// Sets locale from device language if supported.
  void _setLocaleFromDevice() {
    final systemLocale = PlatformDispatcher.instance.locale;
    final supportedLangs = ['en', 'ar', 'fr', 'ur'];
    _currentLocale = supportedLangs.contains(systemLocale.languageCode)
        ? Locale(systemLocale.languageCode)
        : const Locale('en');
  }

  /// Updates the user’s locale in Firestore and locally.
  Future<void> updateUserLocale(String languageCode) async {
    _currentLocale = Locale(languageCode);
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'language_preference': languageCode,
      });
    }
  }

  /// Static helper for settings screens etc.
  static Future<void> setLocale(Locale locale) async {
    await LocaleManager().updateUserLocale(locale.languageCode);
  }

  /// Resets to system locale after logout or account deletion.
  void resetToDeviceLocale() {
    _setLocaleFromDevice();
  }

  /// Returns system locale if supported, otherwise defaults to English.
  Locale getDeviceLocaleOrDefault() {
    final systemLocale = PlatformDispatcher.instance.locale;
    final supportedLangs = ['en', 'ar', 'fr', 'ur'];
    return supportedLangs.contains(systemLocale.languageCode)
        ? Locale(systemLocale.languageCode)
        : const Locale('en');
  }

  /// Returns the display name of a language code based on the current locale.
  String getLanguageName(String code, Locale currentLocale) {
    final names = {
      'en': {'en': 'English', 'fr': 'Anglais', 'ar': 'الإنجليزية', 'ur': 'انگریزی'},
      'fr': {'en': 'French', 'fr': 'Français', 'ar': 'الفرنسية', 'ur': 'فرانسیسی'},
      'ar': {'en': 'Arabic', 'fr': 'Arabe', 'ar': 'العربية', 'ur': 'عربی'},
      'ur': {'en': 'Urdu', 'fr': 'Ourdou', 'ar': 'الأردية', 'ur': 'اردو'},
    };
    return names[code]?[currentLocale.languageCode] ?? code;
  }

  /// 🚀 NEW: Lazy load languages on demand
  Future<void> loadLazyLocale(BuildContext context, String langCode) async {
    if (langCode == 'en') {
      await context.setLocale(const Locale('en'));
      return;
    }

    try {
      // ✅ Load JSON dynamically from assets/translations_lazy
      final jsonString =
      await rootBundle.loadString('assets/translations_lazy/$langCode.json');
      final Map<String, dynamic> newTranslations = json.decode(jsonString);

      // ✅ Add this locale to supportedLocales if missing
      if (!EasyLocalization.of(context)!.supportedLocales.contains(Locale(langCode))) {
        EasyLocalization.of(context)!.supportedLocales.add(Locale(langCode));
      }

      // ✅ Switch to the new locale
      await context.setLocale(Locale(langCode));

      // ✅ Trigger EasyLocalization to reload the new locale’s translations
      // NOTE: EasyLocalization doesn’t expose `translations.addTranslations()`
      // so we “force reload” by calling its localizationDelegates
      await EasyLocalization.of(context)!
          .delegate
          .load(Locale(langCode));

    } catch (e) {
      print('❌ Failed to load locale: $langCode → $e');
    }
  }
}
