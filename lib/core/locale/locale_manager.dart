// Copyright © 2025 Oliver & Haidar. All rights reserved.
// This file is part of the Ummaly project and may not be reused,
// modified, or distributed without express written permission.

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LocaleManager {
  static final LocaleManager _instance = LocaleManager._internal();
  factory LocaleManager() => _instance;
  LocaleManager._internal();

  Locale _currentLocale = const Locale('en');
  Locale get currentLocale => _currentLocale;

  /// Call this during app startup BEFORE runApp()
  /// Loads saved user locale if logged in, otherwise uses device locale.
  Future<void> init() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await _loadLocaleFromFirestore(user.uid);
    } else {
      _setLocaleFromDevice();
    }
  }

  /// Loads user's saved locale from Firestore if available.
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

  /// Sets the locale from the device language if supported.
  void _setLocaleFromDevice() {
    final systemLocale = PlatformDispatcher.instance.locale;
    final supportedLangs = ['en', 'ar', 'fr', 'ur'];
    _currentLocale = supportedLangs.contains(systemLocale.languageCode)
        ? Locale(systemLocale.languageCode)
        : const Locale('en');
  }

  /// Updates the user's locale in Firestore and locally stores it.
  /// Use this when saving language changes in settings screen.
  Future<void> updateUserLocale(String languageCode) async {
    _currentLocale = Locale(languageCode);

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'language_preference': languageCode,
      });
    }
  }

  /// Used by settings screen to both update Firestore and local cache.
  /// Keeps naming consistent with context.setLocale() usage.
  static Future<void> setLocale(Locale locale) async {
    await LocaleManager().updateUserLocale(locale.languageCode);
  }

  /// Resets to system locale after logout or account deletion
  void resetToDeviceLocale() {
    _setLocaleFromDevice();
  }

  /// Returns system locale if supported, otherwise defaults to English
  Locale getDeviceLocaleOrDefault() {
    final systemLocale = PlatformDispatcher.instance.locale;
    final supportedLangs = ['en', 'ar', 'fr', 'ur'];
    return supportedLangs.contains(systemLocale.languageCode)
        ? Locale(systemLocale.languageCode)
        : const Locale('en');
  }

  /// Returns the display name of a language code based on the current locale
  String getLanguageName(String code, Locale currentLocale) {
    final names = {
      'en': {
        'en': 'English',
        'fr': 'Anglais',
        'ar': 'الإنجليزية',
        'ur': 'انگریزی',
      },
      'fr': {
        'en': 'French',
        'fr': 'Français',
        'ar': 'الفرنسية',
        'ur': 'فرانسیسی',
      },
      'ar': {
        'en': 'Arabic',
        'fr': 'Arabe',
        'ar': 'العربية',
        'ur': 'عربی',
      },
      'ur': {
        'en': 'Urdu',
        'fr': 'Ourdou',
        'ar': 'الأردية',
        'ur': 'اردو',
      },
    };

    return names[code]?[currentLocale.languageCode] ?? code;
  }
}
