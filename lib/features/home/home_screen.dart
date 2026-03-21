// Copyright © 2025 Oliver & Haidar. All rights reserved.

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:ui' as dart_ui;
import 'package:get/get.dart' hide Trans;
import 'package:ummaly/features/auth/login_screen.dart';
import 'package:ummaly/features/onboarding/onboarding_screen.dart';
import 'package:ummaly/features/account/change_password_screen.dart';
import 'package:ummaly/features/account/account_settings_screen.dart';
import 'package:ummaly/features/scanner/barcode_scan_screen.dart';
import 'package:ummaly/features/restaurant/restaurant_search_screen.dart';
import 'package:ummaly/core/services/restaurant_service.dart';
import 'package:ummaly/core/locale/locale_manager.dart';
import 'package:ummaly/theme/styles.dart';
import 'package:ummaly/theme/islamic_patterns.dart';
import 'package:ummaly/theme/animated_logo.dart';
import 'package:ummaly/core/services/subscription_service.dart';
import 'package:ummaly/core/services/favorites_service.dart';
import 'package:ummaly/features/pillars/pillar_content_service.dart';
import 'package:ummaly/core/services/prayer_time_service.dart';
import 'package:easy_localization/easy_localization.dart';
import 'dart:math' as math;

class HomeScreen extends StatefulWidget {
  final bool isGuest;
  const HomeScreen({super.key, this.isGuest = false});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late Future<String> _userNameFuture;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  final _prayerService = PrayerTimeService.instance;
  final _favService = FavoritesService.instance;

  @override
  void initState() {
    super.initState();
    _userNameFuture = getUserName();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fadeController.forward();
    _prayerService.addListener(_onUpdate);
    _favService.addListener(_onUpdate);
  }

  @override
  void dispose() {
    _prayerService.removeListener(_onUpdate);
    _favService.removeListener(_onUpdate);
    _fadeController.dispose();
    super.dispose();
  }

  void _onUpdate() {
    if (mounted) setState(() {});
  }

  Future<String> getUserName() async {
    if (widget.isGuest) return 'Guest';
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return 'Guest';
    try {
      final doc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      return doc.data()?['name'] ?? tr('user');
    } catch (_) {
      return tr('user');
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _userNameFuture,
      builder: (context, snapshot) {
        final userName = snapshot.data ?? '';

        return Scaffold(
          backgroundColor: AppColors.background,
          body: IslamicPatternBackground(
            color: AppColors.primary.withOpacity(0.03),
            child: SafeArea(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: CustomScrollView(
                  slivers: [
                    // ── Header ──
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Assalamu Alaikum',
                                    style: AppTextStyles.caption.copyWith(
                                      color: AppColors.primary,
                                      letterSpacing: 1.2,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    userName.isEmpty ? 'Welcome' : userName,
                                    style: AppTextStyles.title.copyWith(
                                      fontSize: 28,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Profile menu — different for guest vs signed-in
                            widget.isGuest
                                ? _buildGuestProfileButton()
                                : _buildAuthProfileButton(),
                          ],
                        ),
                      ),
                    ),

                    // ── Guest banner ──
                    if (widget.isGuest)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                          child: GestureDetector(
                            onTap: () => Get.off(() => const LoginScreen()),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF0D7377), Color(0xFF14897E)],
                                ),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.person_add_rounded,
                                      color: Colors.white, size: 20),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Create an account',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                            fontFamily: 'Poppins',
                                          ),
                                        ),
                                        Text(
                                          kIsWeb
                                              ? 'Save favourites, get prayer notifications & more'
                                              : 'Unlock unlimited scans & save your history',
                                          style: TextStyle(
                                            color: Colors.white.withOpacity(0.8),
                                            fontSize: 12,
                                            fontFamily: 'Poppins',
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(Icons.arrow_forward_ios_rounded,
                                      color: Colors.white.withOpacity(0.7),
                                      size: 16),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                    // ── Hero Feature Cards ──
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                        child: Text(
                          'HALAL TOOLS',
                          style: AppTextStyles.label.copyWith(
                            color: AppColors.textSecondary,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                    ),

                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          children: [
                            // Barcode Scanner (mobile) / Download CTA (web)
                            if (!kIsWeb)
                              _buildHeroCard(
                                icon: Icons.qr_code_scanner_rounded,
                                title: tr('barcode_scanner'),
                                subtitle: 'Scan any product to check halal status',
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF0D7377),
                                    Color(0xFF14897E),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                onTap: () {
                                  Get.to(() => const BarcodeScanScreen());
                                },
                              )
                            else
                              _buildDownloadAppCard(),
                            const SizedBox(height: 16),

                            // Restaurant Finder - Hero card
                            _buildHeroCard(
                              icon: Icons.restaurant_rounded,
                              title: tr('find_restaurants'),
                              subtitle:
                                  'Discover halal restaurants near you',
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFF166534),
                                  Color(0xFF22863A),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              onTap: () {
                                Get.to(() => RestaurantSearchScreen(
                                      service: const RestaurantService(),
                                    ));
                              },
                            ),
                          ],
                        ),
                      ),
                    ),

                    // ── Favorite Scans (mobile only — scanning not available on web) ──
                    if (!kIsWeb && _favService.favorites.isNotEmpty) ...[
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
                          child: Row(
                            children: [
                              Text(
                                'FAVORITE SCANS',
                                style: AppTextStyles.label.copyWith(
                                  color: AppColors.textSecondary,
                                  letterSpacing: 2,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '${_favService.count}',
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: SizedBox(
                          height: 120,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            itemCount: _favService.favorites.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 12),
                            itemBuilder: (context, i) {
                              final fav = _favService.favorites[i];
                              return _FavoriteScanCard(
                                fav: fav,
                                onTap: () {
                                  // Navigate to scanner (could pre-fill barcode)
                                  Get.to(() => const BarcodeScanScreen());
                                },
                                onRemove: () async {
                                  await _favService.remove(fav.barcode);
                                },
                              );
                            },
                          ),
                        ),
                      ),
                    ],

                    // ── Next Prayer Card ──
                    if (_prayerService.times.isNotEmpty)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                          child: _buildNextPrayerHomeCard(),
                        ),
                      ),

                    // ── Daily Inspiration Banner ──
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                        child: _buildDailyInspirationCard(),
                      ),
                    ),

                    // ── Islamic Art Footer ──
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                        child: _buildIslamicArtCard(),
                      ),
                    ),

                    // ── Bottom spacer ──
                    const SliverToBoxAdapter(
                      child: SizedBox(height: 20),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ---------- Guest profile button ----------
  Widget _buildGuestProfileButton() {
    return GestureDetector(
      onTap: () => Get.off(() => const LoginScreen()),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFD4A574), Color(0xFFC49660)],
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.login_rounded, color: Colors.white, size: 18),
            SizedBox(width: 6),
            Text(
              'Sign In',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 13,
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------- Authenticated profile button ----------
  Widget _buildAuthProfileButton() {
    return PopupMenuButton<String>(
      onSelected: (value) async {
        if (value == 'settings') {
          await Get.to(() => const AccountSettingsScreen());
          setState(() {
            _userNameFuture = getUserName();
          });
        } else if (value == 'change_password') {
          Get.to(() => const ChangePasswordScreen());
        } else if (value == 'logout') {
          _handleLogout();
        }
      },
      icon: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.person_rounded,
            color: AppColors.primary, size: 24),
      ),
      itemBuilder: (context) => [
        PopupMenuItem(
            value: 'settings',
            child: Text('account_settings'.tr())),
        PopupMenuItem(
            value: 'change_password',
            child: Text('change_password'.tr())),
        PopupMenuItem(
            value: 'logout',
            child: Text('logout'.tr())),
      ],
    );
  }

  /// Big hero card for primary features
  Widget _buildHeroCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Gradient gradient,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: (gradient as LinearGradient).colors.first.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: Colors.white, size: 32),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.85),
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded,
                color: Colors.white.withOpacity(0.6), size: 18),
          ],
        ),
      ),
    );
  }

  /// Download app CTA card — shown on web in place of the barcode scanner.
  Widget _buildDownloadAppCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0D7377), Color(0xFF14897E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0D7377).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.qr_code_scanner_rounded,
                    color: Colors.white, size: 32),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Halal Barcode Scanner',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Download the Ummaly app to scan any product and instantly verify its halal status',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.85),
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _DownloadButton(
                  icon: Icons.apple,
                  label: 'App Store',
                  onTap: () {
                    // TODO: Replace with actual App Store URL
                    // launchUrl(Uri.parse('https://apps.apple.com/app/ummaly/id...'));
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _DownloadButton(
                  icon: Icons.shop_rounded,
                  label: 'Google Play',
                  onTap: () {
                    // TODO: Replace with actual Play Store URL
                    // launchUrl(Uri.parse('https://play.google.com/store/apps/details?id=com.ummaly.ummaly'));
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Compact next-prayer card for the home screen.
  Widget _buildNextPrayerHomeCard() {
    final next = _prayerService.nextPrayer;
    if (next == null || next.name == 'Sunrise') return const SizedBox.shrink();

    final timeUntil = _prayerService.timeUntilNext;
    const accent = Color(0xFF0D7377);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F1A2E), Color(0xFF162035)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withOpacity(0.25)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: accent.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.mosque_rounded,
              color: accent,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Next Prayer',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      next.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      next.arabic,
                      style: TextStyle(
                        color: accent.withOpacity(0.7),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                next.formatted,
                style: const TextStyle(
                  color: accent,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (timeUntil.isNotEmpty)
                Text(
                  'in $timeUntil',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.4),
                    fontSize: 11,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  /// Daily inspiration card with verse/hadith from PillarContentService
  Widget _buildDailyInspirationCard() {
    final svc = PillarContentService.instance;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.gold.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Subtle geometric pattern overlay
            Positioned.fill(
              child: CustomPaint(
                painter: _SubtlePatternPainter(
                  color: AppColors.gold.withOpacity(0.04),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.auto_stories, color: AppColors.gold, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'DAILY INSPIRATION',
                        style: TextStyle(
                          color: AppColors.gold,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    svc.dailyVerse,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 16,
                      fontStyle: FontStyle.italic,
                      height: 1.6,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  if (svc.dailyVerseArabic != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      svc.dailyVerseArabic!,
                      textAlign: TextAlign.center,
                      textDirection: dart_ui.TextDirection.rtl,
                      style: TextStyle(
                        color: AppColors.gold.withOpacity(0.7),
                        fontSize: 18,
                        height: 1.8,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Text(
                    svc.dailyVerseReference,
                    style: TextStyle(
                      color: AppColors.gold.withOpacity(0.6),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Beautiful Islamic art decorative card
  Widget _buildIslamicArtCard() {
    return Container(
      width: double.infinity,
      height: 180,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFFFF8E7).withOpacity(0.95),
            const Color(0xFFFFF0D4).withOpacity(0.95),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.gold.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: AppColors.gold.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Gold geometric pattern background
            Positioned.fill(
              child: CustomPaint(
                painter: _IslamicArtPainter(
                  color: AppColors.gold.withOpacity(0.12),
                  strokeColor: AppColors.gold.withOpacity(0.2),
                ),
              ),
            ),
            // Arabesque border
            Positioned.fill(
              child: CustomPaint(
                painter: ArabescueBorder(
                  color: AppColors.gold.withOpacity(0.35),
                  strokeWidth: 1.2,
                  cornerRadius: 20,
                ),
              ),
            ),
            // Center logo
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  UmmalyLogo(size: 64, color: AppColors.gold.withOpacity(0.6)),
                  const SizedBox(height: 8),
                  Text(
                    PillarContentService.instance.monthlyArabic,
                    textDirection: dart_ui.TextDirection.rtl,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.gold.withOpacity(0.7),
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    PillarContentService.instance.monthlyEnglish,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.gold.withOpacity(0.45),
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleLogout() async {
    Get.dialog(
      const Center(child: CircularProgressIndicator()),
      barrierDismissible: false,
    );
    try {
      await SubscriptionService.instance.logOut();
      await FirebaseAuth.instance.signOut();
      LocaleManager().resetToDeviceLocale();
      Get.back(); // close dialog
      Get.snackbar('', 'signed_out_successfully'.tr());
      Get.offAll(() => const LoginScreen());
    } catch (_) {
      Get.back(); // close dialog
      Get.snackbar('Error', 'sign_out_failed'.tr(),
          backgroundColor: AppColors.error,
          colorText: Colors.white);
    }
  }
}

// ---------------------------------------------------------------------------
// Favorite scan compact card (horizontal scroll)
// ---------------------------------------------------------------------------

class _FavoriteScanCard extends StatelessWidget {
  final FavoriteProduct fav;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _FavoriteScanCard({
    required this.fav,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = AppStyleHelpers.halalStatusColor(fav.halalStatus);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 160,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: image + remove
            Row(
              children: [
                // Tiny product image
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: (fav.imageUrl != null && fav.imageUrl!.isNotEmpty)
                      ? Image.network(
                          fav.imageUrl!,
                          width: 36,
                          height: 36,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _placeholder(),
                        )
                      : _placeholder(),
                ),
                const Spacer(),
                // Remove heart
                GestureDetector(
                  onTap: onRemove,
                  child: const Icon(
                    Icons.favorite_rounded,
                    color: Colors.redAccent,
                    size: 18,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Product name
            Text(
              fav.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                height: 1.2,
              ),
            ),
            const Spacer(),

            // Status chip
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: statusColor.withOpacity(0.4)),
              ),
              child: Text(
                fav.halalStatus,
                style: TextStyle(
                  color: statusColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(Icons.image, color: Colors.grey[400], size: 18),
    );
  }
}

// ---------------------------------------------------------------------------
// Custom painters for the home screen decorative elements
// ---------------------------------------------------------------------------

/// Subtle repeating geometric pattern (used behind the daily inspiration card).
class _SubtlePatternPainter extends CustomPainter {
  _SubtlePatternPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    const double spacing = 40.0;
    final int cols = (size.width / spacing).ceil() + 1;
    final int rows = (size.height / spacing).ceil() + 1;

    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final double cx = c * spacing;
        final double cy = r * spacing;
        // Small diamond
        final path = Path()
          ..moveTo(cx, cy - 8)
          ..lineTo(cx + 8, cy)
          ..lineTo(cx, cy + 8)
          ..lineTo(cx - 8, cy)
          ..close();
        canvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_SubtlePatternPainter oldDelegate) => false;
}

/// Beautiful Islamic geometric art with interlocking stars and arabesques.
class _IslamicArtPainter extends CustomPainter {
  _IslamicArtPainter({required this.color, required this.strokeColor});
  final Color color;
  final Color strokeColor;

  @override
  void paint(Canvas canvas, Size size) {
    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..strokeCap = StrokeCap.round;

    const double spacing = 52.0;
    final int cols = (size.width / spacing).ceil() + 2;
    final int rows = (size.height / spacing).ceil() + 2;

    for (int r = -1; r < rows; r++) {
      for (int c = -1; c < cols; c++) {
        final double cx = c * spacing + (r.isOdd ? spacing / 2 : 0);
        final double cy = r * spacing;

        // 8-pointed star
        _drawEightPointStar(canvas, strokePaint, cx, cy, spacing * 0.3);

        // Small filled circle at center
        canvas.drawCircle(Offset(cx, cy), 2.5, fillPaint);
      }
    }

    // Connecting arcs between stars
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols - 1; c++) {
        final double x1 = c * spacing + (r.isOdd ? spacing / 2 : 0);
        final double x2 = x1 + spacing;
        final double y = r * spacing;

        final arcPath = Path()
          ..moveTo(x1 + spacing * 0.3, y)
          ..quadraticBezierTo(
            (x1 + x2) / 2,
            y - spacing * 0.12,
            x2 - spacing * 0.3,
            y,
          );
        canvas.drawPath(arcPath, strokePaint);
      }
    }
  }

  void _drawEightPointStar(
      Canvas canvas, Paint paint, double cx, double cy, double radius) {
    final double innerRadius = radius * 0.42;
    final path = Path();

    for (int i = 0; i < 8; i++) {
      final double outerAngle = (i * math.pi / 4) - math.pi / 2;
      final double innerAngle = outerAngle + math.pi / 8;

      final double ox = cx + radius * math.cos(outerAngle);
      final double oy = cy + radius * math.sin(outerAngle);
      final double ix = cx + innerRadius * math.cos(innerAngle);
      final double iy = cy + innerRadius * math.sin(innerAngle);

      if (i == 0) {
        path.moveTo(ox, oy);
      } else {
        path.lineTo(ox, oy);
      }
      path.lineTo(ix, iy);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_IslamicArtPainter oldDelegate) => false;
}

/// Store download button used in the web-only download CTA card.
class _DownloadButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _DownloadButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withOpacity(0.18),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 22),
              const SizedBox(width: 10),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
