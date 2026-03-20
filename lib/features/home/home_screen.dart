// Copyright © 2025 Oliver & Haidar. All rights reserved.

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
import 'package:ummaly/features/pillars/pillar_content_service.dart';
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
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
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
                                          'Unlock unlimited scans & save your history',
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
                            // Barcode Scanner - Hero card
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
                            ),
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

                    // ── Daily Inspiration Banner ──
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
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
                    'بِسْمِ ٱللّٰهِ ٱلرَّحْمٰنِ ٱلرَّحِيمِ',
                    textDirection: dart_ui.TextDirection.rtl,
                    style: TextStyle(
                      color: AppColors.gold.withOpacity(0.7),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'In the name of Allah, the Most Gracious, the Most Merciful',
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
