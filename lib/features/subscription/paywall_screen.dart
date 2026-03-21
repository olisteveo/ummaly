import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:ummaly/theme/styles.dart';
import 'package:ummaly/config/subscription_config.dart';
import 'package:ummaly/core/services/subscription_service.dart';
import 'package:ummaly/features/auth/register_screen.dart';

/// Premium paywall screen.
///
/// Shows monthly and yearly plans fetched from RevenueCat.
/// If the user is a guest, prompts them to create an account first.
class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  final _sub = SubscriptionService.instance;
  bool _loading = false;
  bool _restoring = false;
  String? _error;
  _PlanChoice _selectedPlan = _PlanChoice.yearly; // default to best value

  @override
  Widget build(BuildContext context) {
    final isGuest = FirebaseAuth.instance.currentUser == null;
    final monthly = _sub.monthlyPackage;
    final annual = _sub.annualPackage;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 8),

              // ── Hero ──
              _buildHero(),
              const SizedBox(height: 32),

              // ── Feature list ──
              _buildFeatureList(),
              const SizedBox(height: 32),

              // ── Plan cards ──
              if (monthly != null)
                _PlanCard(
                  title: 'Monthly',
                  price: monthly.storeProduct.priceString,
                  period: '/month',
                  selected: _selectedPlan == _PlanChoice.monthly,
                  onTap: () => setState(() => _selectedPlan = _PlanChoice.monthly),
                ),
              if (monthly != null && annual != null)
                const SizedBox(height: 12),
              if (annual != null)
                _PlanCard(
                  title: 'Yearly',
                  price: annual.storeProduct.priceString,
                  period: '/year',
                  badge: 'Save ${SubscriptionConfig.yearlySavingsPercent}%',
                  selected: _selectedPlan == _PlanChoice.yearly,
                  onTap: () => setState(() => _selectedPlan = _PlanChoice.yearly),
                ),

              // Fallback when RevenueCat offerings aren't loaded
              if (monthly == null && annual == null) ...[
                _PlanCard(
                  title: 'Monthly',
                  price: SubscriptionConfig.monthlyPriceFallback,
                  period: '/month',
                  selected: _selectedPlan == _PlanChoice.monthly,
                  onTap: () => setState(() => _selectedPlan = _PlanChoice.monthly),
                ),
                const SizedBox(height: 12),
                _PlanCard(
                  title: 'Yearly',
                  price: SubscriptionConfig.yearlyPriceFallback,
                  period: '/year',
                  badge: 'Save ${SubscriptionConfig.yearlySavingsPercent}%',
                  selected: _selectedPlan == _PlanChoice.yearly,
                  onTap: () => setState(() => _selectedPlan = _PlanChoice.yearly),
                ),
              ],

              const SizedBox(height: 24),

              // ── Error message ──
              if (_error != null) ...[
                Text(
                  _error!,
                  style: AppTextStyles.error,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
              ],

              // ── Subscribe button ──
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: AppButtons.primaryButton,
                  onPressed: _loading ? null : () => _handleSubscribe(isGuest),
                  child: _loading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                          ),
                        )
                      : Text(isGuest
                          ? 'Create Account & Subscribe'
                          : 'Subscribe Now'),
                ),
              ),
              const SizedBox(height: 12),

              // ── Restore purchases ──
              TextButton(
                onPressed: _restoring ? null : _handleRestore,
                child: _restoring
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Restore Purchases'),
              ),
              const SizedBox(height: 8),

              // ── Legal ──
              Text(
                'Payment will be charged to your Apple ID or Google Play account. '
                'Subscription auto-renews unless cancelled at least 24 hours '
                'before the end of the current period.',
                textAlign: TextAlign.center,
                style: AppTextStyles.caption.copyWith(fontSize: 11),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // ── Hero section ──

  Widget _buildHero() {
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            gradient: AppGradients.emeraldGold,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(Icons.workspace_premium, color: Colors.white, size: 36),
        ),
        const SizedBox(height: 16),
        const Text(
          'Ummaly Premium',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Unlimited halal verification scans',
          style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }

  // ── Feature list ──

  Widget _buildFeatureList() {
    const features = [
      ('Unlimited barcode scans', Icons.qr_code_scanner_rounded),
      ('Full scan history', Icons.history_rounded),
      ('Priority analysis speed', Icons.speed_rounded),
      ('Support Ummaly development', Icons.favorite_rounded),
    ];

    return Column(
      children: features.map((f) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(f.$2, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  f.$1,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const Icon(Icons.check_circle, color: AppColors.success, size: 20),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ── Handlers ──

  Future<void> _handleSubscribe(bool isGuest) async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // If guest, make them register first
      if (isGuest) {
        final registered = await Navigator.of(context).push<bool>(
          MaterialPageRoute(builder: (_) => const RegisterScreen()),
        );
        // If they didn't complete registration, abort
        if (registered != true || FirebaseAuth.instance.currentUser == null) {
          setState(() => _loading = false);
          return;
        }
        // Identify with RevenueCat after registration
        await _sub.identify(FirebaseAuth.instance.currentUser!.uid);
      }

      // Select the right package
      final package = _selectedPlan == _PlanChoice.yearly
          ? _sub.annualPackage
          : _sub.monthlyPackage;

      if (package == null) {
        setState(() {
          _error = 'Subscription plans are not available right now. Please try again later.';
          _loading = false;
        });
        return;
      }

      final success = await _sub.purchasePackage(package);
      if (success && mounted) {
        Navigator.of(context).pop(true); // return success to caller
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Welcome to Ummaly Premium! Unlimited scans unlocked.'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Purchase failed. Please try again.';
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _handleRestore() async {
    setState(() {
      _restoring = true;
      _error = null;
    });

    try {
      final restored = await _sub.restorePurchases();
      if (mounted) {
        if (restored) {
          Navigator.of(context).pop(true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Subscription restored successfully!')),
          );
        } else {
          setState(() {
            _error = 'No active subscription found to restore.';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Could not restore purchases. Please try again.';
        });
      }
    } finally {
      if (mounted) setState(() => _restoring = false);
    }
  }
}

// ── Plan choice ──

enum _PlanChoice { monthly, yearly }

// ── Plan card widget ──

class _PlanCard extends StatelessWidget {
  final String title;
  final String price;
  final String period;
  final String? badge;
  final bool selected;
  final VoidCallback onTap;

  const _PlanCard({
    required this.title,
    required this.price,
    required this.period,
    this.badge,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = selected ? AppColors.primary : AppColors.divider;
    final bgColor = selected
        ? AppColors.primary.withOpacity(0.05)
        : AppColors.cardBackground;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: selected ? 2 : 1),
        ),
        child: Row(
          children: [
            // Radio indicator
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? AppColors.primary : AppColors.textSecondary,
                  width: 2,
                ),
              ),
              child: selected
                  ? Center(
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primary,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 14),

            // Title + badge
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: selected
                              ? AppColors.textPrimary
                              : AppColors.textSecondary,
                        ),
                      ),
                      if (badge != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.gold,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            badge!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // Price
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  price,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: selected ? AppColors.primary : AppColors.textPrimary,
                  ),
                ),
                Text(
                  period,
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
