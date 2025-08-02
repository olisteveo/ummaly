import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:ummaly/firebase_options.dart';
import 'package:ummaly/features/auth/auth_gate.dart';
import 'package:ummaly/features/auth/forgot_password.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:ummaly/core/locale/locale_manager.dart';
import 'package:flutter/services.dart'; // ✅ Added for orientation lock

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Lock to portrait only
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // ✅ Safe Firebase init: will NOT re-init if another plugin already did
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } else {
      Firebase.app();
    }
  } catch (e) {
    // ✅ If it *still* complains about duplicate-app, just use the existing one
    print('⚠️ Firebase already initialized, using existing app.');
    Firebase.app();
  }

  // ✅ Initialize EasyLocalization
  await EasyLocalization.ensureInitialized();

  // ✅ Initialize LocaleManager AFTER Firebase
  await LocaleManager().init();

  runApp(
    EasyLocalization(
      supportedLocales: const [
        Locale('en'),
        Locale('fr'),
        Locale('ar'),
        Locale('ur'),
      ],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      startLocale: LocaleManager().currentLocale,
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Ummaly',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: false,
      ),
      home: const AuthGate(),
      routes: {
        '/forgot-password': (context) => const ForgotPasswordPage(),
      },
    );
  }
}
