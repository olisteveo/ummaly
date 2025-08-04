import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:ummaly/firebase_options.dart';
import 'package:ummaly/features/auth/auth_gate.dart';
import 'package:ummaly/features/auth/forgot_password.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:ummaly/core/locale/locale_manager.dart';
import 'package:flutter/services.dart'; // ✅ For portrait lock

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Lock to portrait only
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // ✅ Safe Firebase init
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } else {
      Firebase.app();
    }
  } catch (e) {
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
        Locale('en'), // ✅ only preload English
      ],
      path: 'assets/translations', // ✅ only English here
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
