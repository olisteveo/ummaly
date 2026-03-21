import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;

/// RevenueCat configuration constants.
///
/// Setup steps:
/// 1. Create a RevenueCat project at https://app.revenuecat.com
/// 2. Connect Apple App Store (shared secret) and Google Play (service credentials)
/// 3. Create products in App Store Connect & Google Play Console:
///    - ummaly_premium_monthly  → £3.99/month
///    - ummaly_premium_yearly   → £29.99/year
/// 4. In RevenueCat dashboard:
///    - Create entitlement: "premium"
///    - Create offering: "default"
///    - Attach both products to the offering
/// 5. Copy your API keys below
class SubscriptionConfig {
  // ── RevenueCat public API keys (safe to include in client code) ──
  // Replace these after creating your RevenueCat project
  static const String revenueCatAppleKey = 'appl_YOUR_REVENUECAT_API_KEY';
  static const String revenueCatGoogleKey = 'goog_YOUR_REVENUECAT_API_KEY';

  /// Returns the correct API key for the current platform
  static String get revenueCatApiKey {
    if (kIsWeb) {
      // RevenueCat doesn't support web — web users can't subscribe in-app
      // They'd need to be directed to a Stripe checkout page
      return '';
    }
    final platform = defaultTargetPlatform;
    if (platform == TargetPlatform.iOS || platform == TargetPlatform.macOS) {
      return revenueCatAppleKey;
    }
    if (platform == TargetPlatform.android) return revenueCatGoogleKey;
    return '';
  }

  // ── Entitlement identifier (must match RevenueCat dashboard) ──
  static const String premiumEntitlement = 'premium';

  // ── Product identifiers (must match App Store Connect / Google Play Console) ──
  static const String monthlyProductId = 'ummaly_premium_monthly';
  static const String yearlyProductId = 'ummaly_premium_yearly';

  // ── Display pricing (fallback if RevenueCat doesn't return localized prices) ──
  static const String monthlyPriceFallback = '£3.99';
  static const String yearlyPriceFallback = '£29.99';
  static const String yearlySavingsPercent = '37';
}
