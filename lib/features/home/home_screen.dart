// Copyright © 2025 Oliver & Haidar. All rights reserved.
// This file is part of the Ummaly project and may not be reused,
// modified, or distributed without express written permission.

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ummaly/features/auth/auth_gate.dart';
import 'package:ummaly/features/account/change_password_screen.dart';
import 'package:ummaly/features/account/account_settings_screen.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:ummaly/core/locale/locale_manager.dart';
import 'package:ummaly/theme/styles.dart'; // Use shared styles

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
              // Display logged-in user's name in the AppBar
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text(
                    '${tr('welcome')}, $userName',
                    style: AppTextStyles.body,
                  ),
                ),
              ),

              // Popup menu for account actions
              PopupMenuButton<String>(
                onSelected: (value) async {
                  if (value == 'settings') {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AccountSettingsScreen()),
                    );
                    setState(() {
                      _userNameFuture = getUserName(); // refresh name if changed
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
                      LocaleManager().resetToDeviceLocale();

                      Navigator.of(context).pop(); // remove loading dialog
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('signed_out_successfully'.tr())),
                      );

                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (context) => const AuthGate()),
                            (route) => false,
                      );
                    } catch (_) {
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('sign_out_failed'.tr()),
                          backgroundColor: AppColors.error,
                        ),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.account_circle),
                itemBuilder: (context) => [
                  PopupMenuItem(value: 'settings', child: Text('account_settings'.tr())),
                  PopupMenuItem(value: 'change_password', child: Text('change_password'.tr())),
                  PopupMenuItem(value: 'logout', child: Text('logout'.tr())),
                ],
              ),
            ],
          ),

          // Dashboard layout for home screen
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: GridView.count(
              crossAxisCount: 2, // Two cards per row
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              children: [
                _buildFeatureCard(
                  icon: Icons.qr_code_scanner,
                  title: tr('barcode_scanner'),
                  color: AppColors.primary,
                  onTap: () {
                    // TODO: Navigate to barcode scanner screen
                  },
                ),
                _buildFeatureCard(
                  icon: Icons.restaurant,
                  title: tr('find_restaurants'),
                  color: AppColors.accent,
                  onTap: () {
                    // TODO: Navigate to restaurant lookup screen
                  },
                ),
                _buildFeatureCard(
                  icon: Icons.access_time,
                  title: tr('prayer_times'),
                  color: Colors.orange,
                  onTap: () {
                    // TODO: Future feature: prayer times
                  },
                ),
                _buildFeatureCard(
                  icon: Icons.event,
                  title: tr('events'),
                  color: Colors.teal,
                  onTap: () {
                    // TODO: Future feature: events
                  },
                ),
                _buildFeatureCard(
                  icon: Icons.article,
                  title: tr('blog_posts'),
                  color: Colors.pink,
                  onTap: () {
                    // TODO: Future feature: blog
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Builds a tappable feature card for the home screen
  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        color: color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 4,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 48, color: AppColors.white),
              const SizedBox(height: 12),
              Text(
                title,
                style: AppTextStyles.button, // White bold text from styles.dart
              ),
            ],
          ),
        ),
      ),
    );
  }
}
