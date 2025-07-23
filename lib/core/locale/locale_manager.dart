// Copyright © 2025 Oliver & Haidar. All rights reserved.
// This file is part of the Ummaly project and may not be reused,
// modified, or distributed without express written permission.

import 'dart:ui';
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

  /// Call this during app startup BEFORE runApp()
  Future<void> init() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await _loadLocaleFromFirestore(user.uid);
    } else {
      _setLocaleFromDevice();
    }
  }

  /// Loads user's saved locale from Firestore
  Future<void> _loadLocaleFromFirestore(String userId) async {
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      final langCode = doc.data()?['language_preference'];
      if (langCode != null) {
        _currentLocale = Locale(langCode);
      } else {
        _setLocaleFromDevice(); // fallback if field missing
      }
    } catch (e) {
      _setLocaleFromDevice(); // fallback on error
    }
  }

  /// Sets the locale from the device
  void _setLocaleFromDevice() {
    final systemLocale = PlatformDispatcher.instance.locale;
    final supportedLangs = ['en', 'ar', 'fr', 'ur'];
    _currentLocale = supportedLangs.contains(systemLocale.languageCode)
        ? Locale(systemLocale.languageCode)
        : const Locale('en');
  }

  /// Updates user's locale manually from dropdown etc.
  /// Also applies it via context if passed.
  Future<void> updateUserLocale(String languageCode, {BuildContext? context}) async {
    _currentLocale = Locale(languageCode);

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'language_preference': languageCode,
      });
    }

    if (context != null) {
      await context.setLocale(Locale(languageCode));
    }
  }

  /// Resets to device locale on logout
  void resetToDeviceLocale() {
    _setLocaleFromDevice();
  }

  /// Used after logout to restore system/default locale in UI
  Locale getDeviceLocaleOrDefault() {
    final systemLocale = PlatformDispatcher.instance.locale;
    final supportedLangs = ['en', 'ar', 'fr', 'ur'];
    return supportedLangs.contains(systemLocale.languageCode)
        ? Locale(systemLocale.languageCode)
        : const Locale('en');
  }
}
