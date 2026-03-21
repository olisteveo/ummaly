import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ummaly/config/subscription_config.dart';

/// Singleton wrapper around RevenueCat.
///
/// Responsibilities:
///   • Initialise the SDK once at app startup
///   • Identify / log out users (synced to Firebase UID)
///   • Expose premium entitlement status
///   • Fetch available offerings (monthly / yearly packages)
///   • Execute purchases and restore transactions
///
/// Usage:
///   await SubscriptionService.instance.init();
///   final isPremium = await SubscriptionService.instance.isPremium;
class SubscriptionService extends ChangeNotifier {
  SubscriptionService._();
  static final SubscriptionService instance = SubscriptionService._();

  bool _initialised = false;
  bool _isPremium = false;
  Offerings? _offerings;

  // ── Public getters ──

  bool get isPremium => _isPremium;
  Offerings? get offerings => _offerings;

  /// The default offering (contains monthly + yearly packages)
  Offering? get currentOffering => _offerings?.current;

  /// Convenience: monthly package from the current offering
  Package? get monthlyPackage => currentOffering?.monthly;

  /// Convenience: annual package from the current offering
  Package? get annualPackage => currentOffering?.annual;

  // ── Initialisation ──

  /// Call once in main() after Firebase.initializeApp().
  /// Safe to call multiple times — subsequent calls are no-ops.
  Future<void> init() async {
    if (_initialised) return;

    final apiKey = SubscriptionConfig.revenueCatApiKey;
    if (apiKey.isEmpty) {
      if (kDebugMode) {
        debugPrint('[SubscriptionService] No RevenueCat API key for this platform — skipping init');
      }
      return;
    }

    try {
      await Purchases.configure(
        PurchasesConfiguration(apiKey)
          ..appUserID = FirebaseAuth.instance.currentUser?.uid,
      );

      // Listen for customer info changes (e.g. subscription expires / renews)
      Purchases.addCustomerInfoUpdateListener(_onCustomerInfoUpdated);

      // Seed initial state
      await _refreshEntitlement();
      await _refreshOfferings();

      _initialised = true;
      if (kDebugMode) {
        debugPrint('[SubscriptionService] Initialised. Premium: $_isPremium');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[SubscriptionService] Init error: $e');
      }
    }
  }

  // ── User identity ──

  /// Call on login/register to associate the Firebase UID with RevenueCat.
  /// This ensures subscription entitlements follow the user across devices.
  Future<void> identify(String firebaseUid) async {
    if (!_initialised) return;
    try {
      await Purchases.logIn(firebaseUid);
      await _refreshEntitlement();
      if (kDebugMode) {
        debugPrint('[SubscriptionService] Identified user: $firebaseUid. Premium: $_isPremium');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[SubscriptionService] Identify error: $e');
      }
    }
  }

  /// Call on sign out to reset the anonymous user in RevenueCat.
  Future<void> logOut() async {
    if (!_initialised) return;
    try {
      await Purchases.logOut();
      _isPremium = false;
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[SubscriptionService] LogOut error: $e');
      }
    }
  }

  // ── Entitlement checks ──

  /// Force-refresh premium status from RevenueCat.
  Future<bool> checkPremium() async {
    await _refreshEntitlement();
    return _isPremium;
  }

  // ── Purchases ──

  /// Purchase a package (monthly or yearly).
  /// Returns true on success, false on cancellation.
  /// Throws on error (network, store issue, etc).
  Future<bool> purchasePackage(Package package) async {
    try {
      final result = await Purchases.purchase(PurchaseParams.package(package));
      _updatePremium(result.customerInfo);
      return _isPremium;
    } on PurchasesErrorCode catch (e) {
      if (e == PurchasesErrorCode.purchaseCancelledError) {
        return false; // User cancelled — not an error
      }
      rethrow;
    }
  }

  /// Restore previous purchases (e.g. after reinstall or new device).
  Future<bool> restorePurchases() async {
    try {
      final info = await Purchases.restorePurchases();
      _updatePremium(info);
      return _isPremium;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[SubscriptionService] Restore error: $e');
      }
      rethrow;
    }
  }

  // ── Private helpers ──

  void _onCustomerInfoUpdated(CustomerInfo info) {
    _updatePremium(info);
  }

  void _updatePremium(CustomerInfo info) {
    final wasPremium = _isPremium;
    _isPremium = info.entitlements.active
        .containsKey(SubscriptionConfig.premiumEntitlement);
    if (wasPremium != _isPremium) {
      notifyListeners();
      if (kDebugMode) {
        debugPrint('[SubscriptionService] Premium status changed → $_isPremium');
      }
    }
  }

  Future<void> _refreshEntitlement() async {
    try {
      final info = await Purchases.getCustomerInfo();
      _updatePremium(info);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[SubscriptionService] Refresh entitlement error: $e');
      }
    }
  }

  Future<void> _refreshOfferings() async {
    try {
      _offerings = await Purchases.getOfferings();
      if (kDebugMode) {
        final current = _offerings?.current;
        debugPrint(
          '[SubscriptionService] Offerings loaded. '
          'Current: ${current?.identifier ?? "none"}, '
          'packages: ${current?.availablePackages.length ?? 0}',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[SubscriptionService] Offerings error: $e');
      }
    }
  }
}
