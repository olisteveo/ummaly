import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ummaly/theme/styles.dart';
import 'package:ummaly/theme/islamic_patterns.dart';
import 'package:ummaly/theme/animated_logo.dart';
import 'package:ummaly/features/auth/login_screen.dart';
import 'package:ummaly/features/shell/app_shell.dart';

// ---------------------------------------------------------------------------
// Onboarding Screen
// 4 pages: animated logo intro → scan → restaurants → faith
// ---------------------------------------------------------------------------

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _autoAdvanceTimer;
  bool _userHasSwiped = false;

  // Fade-in animation controllers (one per page).
  late final List<AnimationController> _fadeControllers;
  late final List<Animation<double>> _fadeAnimations;

  static const int _pageCount = 4;
  static const Duration _autoAdvanceInterval = Duration(seconds: 5);
  static const Duration _fadeDuration = Duration(milliseconds: 800);

  @override
  void initState() {
    super.initState();

    // Build fade controllers.
    _fadeControllers = List.generate(
      _pageCount,
      (_) => AnimationController(vsync: this, duration: _fadeDuration),
    );
    _fadeAnimations = _fadeControllers
        .map((c) => CurvedAnimation(parent: c, curve: Curves.easeIn))
        .toList();

    // Trigger first page fade-in immediately.
    _fadeControllers[0].forward();

    // Start auto-advance after logo animation finishes (~3.5s)
    Future.delayed(const Duration(milliseconds: 4500), () {
      if (mounted && !_userHasSwiped) _startAutoAdvance();
    });
  }

  @override
  void dispose() {
    _autoAdvanceTimer?.cancel();
    _pageController.dispose();
    for (final c in _fadeControllers) {
      c.dispose();
    }
    super.dispose();
  }

  // ---- Auto-advance logic ----

  void _startAutoAdvance() {
    _autoAdvanceTimer?.cancel();
    _autoAdvanceTimer = Timer.periodic(_autoAdvanceInterval, (_) {
      if (_userHasSwiped) {
        _autoAdvanceTimer?.cancel();
        return;
      }
      final next = (_currentPage + 1) % _pageCount;
      _pageController.animateToPage(
        next,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
      );
    });
  }

  void _onPageChanged(int index) {
    setState(() => _currentPage = index);

    // Reset and play fade-in for the new page.
    _fadeControllers[index].reset();
    _fadeControllers[index].forward();
  }

  // ---- Navigation ----

  Future<void> _markOnboardingSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_seen', true);
  }

  void _navigateToLogin() {
    _markOnboardingSeen();
    Get.to(() => const LoginScreen());
  }

  void _navigateAsGuest() {
    _markOnboardingSeen();
    Get.off(() => const AppShell(isGuest: true));
  }

  // ---- Build ----

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Page view — takes remaining space.
          Expanded(
            child: NotificationListener<ScrollNotification>(
              onNotification: (notification) {
                if (notification is UserScrollNotification) {
                  _userHasSwiped = true;
                  _autoAdvanceTimer?.cancel();
                }
                return false;
              },
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                itemCount: _pageCount,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    // First page: animated logo intro
                    return _LogoIntroPage(fadeAnimation: _fadeAnimations[0]);
                  }
                  final page = _pages[index - 1]; // offset by 1
                  return _OnboardingPage(
                    data: page,
                    fadeAnimation: _fadeAnimations[index],
                  );
                },
              ),
            ),
          ),

          // Bottom section — indicators + buttons.
          _BottomSection(
            currentPage: _currentPage,
            pageCount: _pageCount,
            onGetStarted: _navigateToLogin,
            onSignIn: _navigateToLogin,
            onContinueAsGuest: _navigateAsGuest,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Page 1: Animated logo intro
// ---------------------------------------------------------------------------

class _LogoIntroPage extends StatelessWidget {
  const _LogoIntroPage({required this.fadeAnimation});

  final Animation<double> fadeAnimation;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0F1A2E), Color(0xFF1A2540)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: IslamicPatternBackground(
        color: IslamicColors.goldSubtle,
        strokeWidth: 0.5,
        child: SafeArea(
          bottom: false,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animated logo
                AnimatedUmmalyLogo(
                  size: 180,
                  color: IslamicColors.gold,
                  duration: const Duration(milliseconds: 2500),
                ),

                const SizedBox(height: 36),

                // App name
                FadeTransition(
                  opacity: fadeAnimation,
                  child: const Text(
                    'UMMALY',
                    style: TextStyle(
                      color: IslamicColors.gold,
                      fontSize: 36,
                      fontWeight: FontWeight.w300,
                      letterSpacing: 12,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Tagline
                FadeTransition(
                  opacity: fadeAnimation,
                  child: Text(
                    'Halal Verified',
                    style: TextStyle(
                      color: IslamicColors.gold.withValues(alpha: 0.6),
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Page data model
// ---------------------------------------------------------------------------

enum _PageIcon { scan, restaurant, mosque }

class _OnboardingPageData {
  const _OnboardingPageData({
    required this.icon,
    required this.headline,
    required this.subtext,
    required this.gradient,
  });

  final _PageIcon icon;
  final String headline;
  final String subtext;
  final LinearGradient gradient;
}

final List<_OnboardingPageData> _pages = [
  const _OnboardingPageData(
    icon: _PageIcon.scan,
    headline: 'Know What You Eat',
    subtext:
        'Instantly scan any barcode to verify if a product is halal. Powered by multiple databases and AI verification.',
    gradient: LinearGradient(
      colors: [Color(0xFF0F1A2E), Color(0xFF0D2B2E)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
  ),
  const _OnboardingPageData(
    icon: _PageIcon.restaurant,
    headline: 'Find Halal Dining',
    subtext:
        'Discover verified halal restaurants near you. Read reviews, check certifications, and dine with confidence.',
    gradient: LinearGradient(
      colors: [Color(0xFF0D7377), Color(0xFF115E59)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
  ),
  const _OnboardingPageData(
    icon: _PageIcon.mosque,
    headline: 'Live Your Faith',
    subtext:
        'Prayer times, Ramadan guides, Zakat calculator, and the Five Pillars \u2014 all in one beautiful app.',
    gradient: LinearGradient(
      colors: [Color(0xFF1A1A2E), Color(0xFF3D2E14)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
  ),
];

// ---------------------------------------------------------------------------
// Individual onboarding page (slides 2-4)
// ---------------------------------------------------------------------------

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({
    required this.data,
    required this.fadeAnimation,
  });

  final _OnboardingPageData data;
  final Animation<double> fadeAnimation;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Container(
      decoration: BoxDecoration(gradient: data.gradient),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const Spacer(flex: 2),

              // Icon area.
              _buildIcon(size),

              const SizedBox(height: 48),

              // Headline.
              FadeTransition(
                opacity: fadeAnimation,
                child: Text(
                  data.headline,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.title.copyWith(
                    color: AppColors.cream,
                    fontSize: 34,
                    letterSpacing: -0.5,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Subtext.
              FadeTransition(
                opacity: fadeAnimation,
                child: Text(
                  data.subtext,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.cream.withOpacity(0.75),
                    fontSize: 16,
                    height: 1.6,
                  ),
                ),
              ),

              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIcon(Size screenSize) {
    final double iconSize = screenSize.width * 0.35;

    switch (data.icon) {
      case _PageIcon.scan:
        return Container(
          width: iconSize,
          height: iconSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.gold.withOpacity(0.3),
              width: 2,
            ),
          ),
          child: Icon(
            Icons.qr_code_scanner_rounded,
            size: iconSize * 0.45,
            color: AppColors.gold,
          ),
        );

      case _PageIcon.restaurant:
        return Container(
          width: iconSize,
          height: iconSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.gold.withOpacity(0.3),
              width: 2,
            ),
          ),
          child: Icon(
            Icons.restaurant_rounded,
            size: iconSize * 0.45,
            color: AppColors.gold,
          ),
        );

      case _PageIcon.mosque:
        return SizedBox(
          width: iconSize * 1.4,
          height: iconSize,
          child: CustomPaint(
            painter: MosqueSilhouettePainter(
              color: AppColors.gold.withOpacity(0.6),
            ),
          ),
        );
    }
  }
}

// ---------------------------------------------------------------------------
// Bottom section — dot indicators, Get Started button, Sign In link
// ---------------------------------------------------------------------------

class _BottomSection extends StatelessWidget {
  const _BottomSection({
    required this.currentPage,
    required this.pageCount,
    required this.onGetStarted,
    required this.onSignIn,
    required this.onContinueAsGuest,
  });

  final int currentPage;
  final int pageCount;
  final VoidCallback onGetStarted;
  final VoidCallback onSignIn;
  final VoidCallback onContinueAsGuest;

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(32, 20, 32, 20 + bottomPadding),
      decoration: const BoxDecoration(
        color: Color(0xFF0F1A2E),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Dot indicators.
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(pageCount, (i) {
              final isActive = i == currentPage;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: isActive ? 28 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: isActive
                      ? AppColors.gold
                      : AppColors.cream.withOpacity(0.35),
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),

          const SizedBox(height: 28),

          // Get Started button.
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: AppButtons.goldButton,
              onPressed: onGetStarted,
              child: const Text('Get Started'),
            ),
          ),

          const SizedBox(height: 12),

          // Continue as Guest button.
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.cream,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                side: BorderSide(
                  color: AppColors.cream.withOpacity(0.3),
                  width: 1,
                ),
              ),
              onPressed: onContinueAsGuest,
              child: const Text(
                'Continue as Guest',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Sign In link.
          GestureDetector(
            onTap: onSignIn,
            child: Text.rich(
              TextSpan(
                text: 'Already have an account? ',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.cream.withOpacity(0.6),
                  fontSize: 14,
                ),
                children: [
                  TextSpan(
                    text: 'Sign in',
                    style: TextStyle(
                      color: AppColors.gold,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
