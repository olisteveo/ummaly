import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:easy_localization/easy_localization.dart';

import 'package:ummaly/firebase_options.dart';
import 'package:ummaly/core/locale/locale_manager.dart';
import 'package:ummaly/theme/styles.dart';

import 'package:ummaly/features/onboarding/onboarding_screen.dart';
import 'package:ummaly/features/auth/auth_gate.dart';
import 'package:ummaly/features/shell/app_shell.dart';
import 'package:ummaly/features/pillars/pillar_content_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // Firebase init
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  } catch (_) {
    Firebase.app();
  }

  await EasyLocalization.ensureInitialized();
  await LocaleManager().init();

  // Pre-load Islamic content data from JSON assets.
  await PillarContentService.init();

  // Check if onboarding has been completed
  final prefs = await SharedPreferences.getInstance();
  final onboardingSeen = prefs.getBool('onboarding_seen') ?? false;

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en')],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      startLocale: LocaleManager().currentLocale,
      child: UmmalyApp(onboardingSeen: onboardingSeen),
    ),
  );
}

class UmmalyApp extends StatelessWidget {
  final bool onboardingSeen;

  const UmmalyApp({super.key, required this.onboardingSeen});

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
      home: onboardingSeen ? const AuthGate() : const OnboardingScreen(),
    );
  }
}
