import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ummaly/theme/animated_logo.dart';
import 'package:ummaly/theme/islamic_patterns.dart';
import 'package:ummaly/features/onboarding/onboarding_screen.dart';
import 'package:ummaly/features/auth/auth_gate.dart';

/// Splash screen shown on app launch.
/// Plays the animated logo (crescent + star + mosque merging together),
/// then transitions to onboarding or auth gate.
class SplashScreen extends StatefulWidget {
  final bool onboardingSeen;

  const SplashScreen({super.key, required this.onboardingSeen});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _fadeController;
  late final Animation<double> _titleFade;
  late final Animation<double> _subtitleFade;
  bool _logoComplete = false;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _titleFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );

    _subtitleFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: const Interval(0.3, 0.8, curve: Curves.easeIn),
      ),
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  void _onLogoAnimationComplete() {
    setState(() => _logoComplete = true);
    _fadeController.forward();

    // Navigate after a short pause to let the user appreciate the logo
    Future.delayed(const Duration(milliseconds: 2000), () {
      if (!mounted) return;
      if (widget.onboardingSeen) {
        Get.off(() => const AuthGate(), transition: Transition.fadeIn);
      } else {
        Get.off(() => const OnboardingScreen(), transition: Transition.fadeIn);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1A2E),
      body: IslamicPatternBackground(
        color: IslamicColors.goldSubtle,
        strokeWidth: 0.5,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated logo
              AnimatedUmmalyLogo(
                size: 180,
                color: IslamicColors.gold,
                duration: const Duration(milliseconds: 2500),
                onAnimationComplete: _onLogoAnimationComplete,
              ),

              const SizedBox(height: 32),

              // App name fades in after logo animation
              AnimatedBuilder(
                animation: _fadeController,
                builder: (context, _) {
                  return Opacity(
                    opacity: _titleFade.value,
                    child: Transform.translate(
                      offset: Offset(0, 10 * (1 - _titleFade.value)),
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
                  );
                },
              ),

              const SizedBox(height: 8),

              // Tagline
              AnimatedBuilder(
                animation: _fadeController,
                builder: (context, _) {
                  return Opacity(
                    opacity: _subtitleFade.value,
                    child: Transform.translate(
                      offset: Offset(0, 8 * (1 - _subtitleFade.value)),
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
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
