// Copyright © 2025 Oliver & Haidar. All rights reserved.
// This file is part of the Ummaly project and may not be reused,
// modified, or distributed without express written permission.

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ummaly/features/auth/auth_gate.dart';
import 'package:ummaly/features/account/change_password_screen.dart';
import 'package:ummaly/features/account/account_settings_screen.dart';
import 'package:easy_localization/easy_localization.dart'; // Localization
import 'package:ummaly/core/locale/locale_manager.dart'; // Locale reset on logout

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<String> _userNameFuture;

  @override
  void initState() {
    super.initState();
    _userNameFuture = getUserName();
  }

  Future<String> getUserName() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return tr('user');
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    return doc.data()?['name'] ?? tr('user');
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _userNameFuture,
      builder: (context, snapshot) {
        final userName = snapshot.data ?? '';

        return Scaffold(
          appBar: AppBar(
            title: Text('welcome_to_ummaly'.tr()),
            actions: [
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text(
                    '${tr('welcome')}, $userName',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) async {
                  if (value == 'settings') {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AccountSettingsScreen()),
                    );
                    setState(() {
                      _userNameFuture = getUserName();
                    });
                  } else if (value == 'change_password') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ChangePasswordScreen()),
                    );
                  } else if (value == 'logout') {
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (_) => const Center(child: CircularProgressIndicator()),
                    );

                    try {
                      await FirebaseAuth.instance.signOut();

                      // Reset locale to device default on logout
                      LocaleManager().resetToDeviceLocale();

                      Navigator.of(context).pop(); // remove loading dialog
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('signed_out_successfully'.tr())),
                      );

                      // Navigate to AuthGate (login/registration entry point)
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (context) => const AuthGate()),
                            (route) => false,
                      );
                    } catch (_) {
                      Navigator.of(context).pop(); // remove loading dialog
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('sign_out_failed'.tr()),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.account_circle),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'settings',
                    child: Text('account_settings'.tr()),
                  ),
                  PopupMenuItem(
                    value: 'change_password',
                    child: Text('change_password'.tr()),
                  ),
                  PopupMenuItem(
                    value: 'logout',
                    child: Text('logout'.tr()),
                  ),
                ],
              ),
            ],
          ),
          body: Center(
            child: Text('home_screen_content'.tr()),
          ),
        );
      },
    );
  }
}
