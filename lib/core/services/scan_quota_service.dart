import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ummaly/core/services/subscription_service.dart';

/// Scan quota — same for guests and free users:
///   • 5 scans per month
///   • After 5, 1 scan per day
///   • Premium (paid) users: unlimited
///
/// Guests see "Create account" CTA.
/// Free users see "Upgrade" CTA.
enum ScanTier { guest, free, premium }

class ScanQuotaService {
  // ── Prefs keys ──
  static const _monthlyCountKey = 'scan_monthly_count';
  static const _monthlyResetKey = 'scan_monthly_reset';
  static const _dailyCountKey = 'scan_daily_count';
  static const _dailyResetKey = 'scan_daily_reset';

  /// Emails with full access (no paywall). Case-insensitive.
  /// Add team members, testers, friends here.
  static const Set<String> _allowlistEmails = {
    // Add emails here, e.g.:
    // 'oliver@example.com',
    // 'haidar@example.com',
  };

  /// Check if the current user's email is in the allowlist
  bool get _isAllowlisted {
    final email = FirebaseAuth.instance.currentUser?.email?.toLowerCase();
    if (email == null) return false;
    return _allowlistEmails.contains(email);
  }

  // ── Limits ──
  static const int monthlyLimit = 5;
  static const int dailyLimit = 1;

  // ── Messages ──
  static const String monthlyExhaustedMessage =
      "You've used your $monthlyLimit free scans this month. "
      "You can still scan 1 product per day.";
  static const String dailyLimitGuestMessage =
      "You've used today's free scan. Create an account and subscribe "
      "for unlimited scans, or come back tomorrow.";
  static const String dailyLimitFreeMessage =
      "You've used today's free scan. Subscribe for unlimited scans, "
      "or come back tomorrow.";

  /// Current tier based on auth + subscription status
  ScanTier get currentTier {
    if (SubscriptionService.instance.isPremium) return ScanTier.premium;
    final user = FirebaseAuth.instance.currentUser;
    return user == null ? ScanTier.guest : ScanTier.free;
  }

  /// Check if scan is allowed. Returns null if OK, or an error message if blocked.
  Future<String?> checkQuota() async {
    // Premium or allowlisted: always allowed
    if (SubscriptionService.instance.isPremium) return null;
    if (_isAllowlisted) return null;

    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = FirebaseAuth.instance.currentUser != null;

    final now = DateTime.now();
    final monthKey = '${now.year}-${now.month}';
    final dayKey = '${now.year}-${now.month}-${now.day}';

    // Reset monthly counter if new month
    if ((prefs.getString(_monthlyResetKey) ?? '') != monthKey) {
      await prefs.setInt(_monthlyCountKey, 0);
      await prefs.setString(_monthlyResetKey, monthKey);
    }

    final monthlyCount = prefs.getInt(_monthlyCountKey) ?? 0;

    // Still within monthly allowance
    if (monthlyCount < monthlyLimit) return null;

    // Monthly used → check daily
    if ((prefs.getString(_dailyResetKey) ?? '') != dayKey) {
      await prefs.setInt(_dailyCountKey, 0);
      await prefs.setString(_dailyResetKey, dayKey);
    }

    final dailyCount = prefs.getInt(_dailyCountKey) ?? 0;
    if (dailyCount >= dailyLimit) {
      return isLoggedIn ? dailyLimitFreeMessage : dailyLimitGuestMessage;
    }

    return null; // 1 daily scan still available
  }

  /// Record a successful scan
  Future<void> recordScan() async {
    // Premium or allowlisted — no tracking
    if (SubscriptionService.instance.isPremium) return;
    if (_isAllowlisted) return;

    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final monthKey = '${now.year}-${now.month}';
    final dayKey = '${now.year}-${now.month}-${now.day}';

    // Ensure reset keys are current
    if ((prefs.getString(_monthlyResetKey) ?? '') != monthKey) {
      await prefs.setInt(_monthlyCountKey, 0);
      await prefs.setString(_monthlyResetKey, monthKey);
    }
    if ((prefs.getString(_dailyResetKey) ?? '') != dayKey) {
      await prefs.setInt(_dailyCountKey, 0);
      await prefs.setString(_dailyResetKey, dayKey);
    }

    final mc = prefs.getInt(_monthlyCountKey) ?? 0;
    await prefs.setInt(_monthlyCountKey, mc + 1);

    final dc = prefs.getInt(_dailyCountKey) ?? 0;
    await prefs.setInt(_dailyCountKey, dc + 1);
  }

  /// Reset counters (call on login/registration to give a fresh start)
  Future<void> resetCounters() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_monthlyCountKey);
    await prefs.remove(_monthlyResetKey);
    await prefs.remove(_dailyCountKey);
    await prefs.remove(_dailyResetKey);
    // Also clear legacy guest key
    await prefs.remove('guest_scan_count');
  }

  /// Get quota info for UI display
  Future<ScanQuotaInfo> getQuotaInfo() async {
    final tier = currentTier;
    if (tier == ScanTier.premium || _isAllowlisted) {
      return ScanQuotaInfo(tier: ScanTier.premium, remaining: -1);
    }

    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final monthKey = '${now.year}-${now.month}';
    final dayKey = '${now.year}-${now.month}-${now.day}';

    // Ensure month is current
    if ((prefs.getString(_monthlyResetKey) ?? '') != monthKey) {
      return ScanQuotaInfo(tier: tier, remaining: monthlyLimit);
    }

    final mc = prefs.getInt(_monthlyCountKey) ?? 0;
    if (mc < monthlyLimit) {
      return ScanQuotaInfo(tier: tier, remaining: monthlyLimit - mc);
    }

    // Monthly used — check daily
    if ((prefs.getString(_dailyResetKey) ?? '') != dayKey) {
      return ScanQuotaInfo(tier: tier, remaining: dailyLimit, isInDailyMode: true);
    }
    final dc = prefs.getInt(_dailyCountKey) ?? 0;
    return ScanQuotaInfo(
      tier: tier,
      remaining: (dailyLimit - dc).clamp(0, dailyLimit),
      isInDailyMode: true,
    );
  }
}

/// Info object for UI display
class ScanQuotaInfo {
  final ScanTier tier;
  final int remaining; // -1 = unlimited
  final bool isInDailyMode;

  const ScanQuotaInfo({
    required this.tier,
    required this.remaining,
    this.isInDailyMode = false,
  });

  bool get isUnlimited => remaining == -1;
  bool get canScan => remaining != 0;
}
