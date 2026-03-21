import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:easy_localization/easy_localization.dart';

import 'package:ummaly/firebase_options.dart';
import 'package:ummaly/core/locale/locale_manager.dart';
import 'package:ummaly/theme/styles.dart';

import 'package:ummaly/features/onboarding/onboarding_screen.dart';
import 'package:ummaly/features/auth/auth_gate.dart';
import 'package:ummaly/features/pillars/pillar_content_service.dart';
import 'package:ummaly/core/services/prayer_time_service.dart';
import 'package:ummaly/features/splash/mosque_splash.dart';
import 'package:ummaly/core/services/subscription_service.dart';
import 'package:ummaly/core/services/favorites_service.dart';
import 'package:ummaly/core/services/prayer_notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── Critical path (must complete before UI) ──
  await Future.wait([
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]),
    _initFirebase(),
    EasyLocalization.ensureInitialized(),
  ]);

  // Set locale from device (no Firestore call — AuthGate handles
  // the server-side language preference for logged-in users).
  LocaleManager().initFromDevice();

  // ── Launch UI immediately — splash screen plays while services load ──
  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en')],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      startLocale: LocaleManager().currentLocale,
      child: const UmmalyApp(),
    ),
  );

  // ── Background init (runs while splash is showing) ──
  // These all run in parallel, none blocks the UI.
  Future.wait([
    PillarContentService.init(),
    SubscriptionService.instance.init(),
    FavoritesService.instance.load(),
    PrayerNotificationService.instance.load(),
  ]);

  // Fire-and-forget — prayer times load in the background.
  PrayerTimeService.instance.fetch();
}

/// Initialise Firebase with error recovery.
Future<void> _initFirebase() async {
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  } catch (_) {
    Firebase.app();
  }
}

class UmmalyApp extends StatelessWidget {
  const UmmalyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Ummaly',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: AppColors.background,
        useMaterial3: true,
      ),
      home: const AppLauncher(),
    );
  }
}

// ---------------------------------------------------------------------------
// AppLauncher — Always plays the cinematic splash, then routes based on
// whether the user has an active Firebase session:
//   • Logged in  → AuthGate (verifies session, loads locale, goes to AppShell)
//   • Logged out → OnboardingScreen (slides → Get Started / Guest / Sign In)
// ---------------------------------------------------------------------------
class AppLauncher extends StatefulWidget {
  const AppLauncher({super.key});

  @override
  State<AppLauncher> createState() => _AppLauncherState();
}

class _AppLauncherState extends State<AppLauncher> {
  bool _splashComplete = false;

  void _onSplashComplete() {
    if (!mounted || _splashComplete) return;
    setState(() => _splashComplete = true);
  }

  @override
  Widget build(BuildContext context) {
    if (_splashComplete) {
      // Check if user already has an active Firebase session
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        // Returning logged-in user → AuthGate handles verification + locale + AppShell
        return const AuthGate();
      }
      // Not logged in → show onboarding slides with login/guest options
      return const OnboardingScreen();
    }

    // Splash playing — dark navy background underneath, splash overlay on top
    return Scaffold(
      backgroundColor: const Color(0xFF0F1A2E),
      body: GestureDetector(
        onTap: _onSplashComplete, // tap to skip
        child: MosqueSplashScreen(
          onComplete: _onSplashComplete,
          duration: const Duration(milliseconds: 5500),
        ),
      ),
    );
  }
}
