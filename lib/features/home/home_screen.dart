// Copyright © 2025 Oliver & Haidar. All rights reserved.
// This file is part of the Ummaly project and may not be reused,
// modified, or distributed without express written permission.

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ummaly/features/auth/auth_gate.dart';
import 'package:ummaly/features/account/change_password_screen.dart';
import 'package:ummaly/features/account/account_settings_screen.dart';

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
    if (uid == null) return 'User';

    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    return doc.data()?['name'] ?? 'User';
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _userNameFuture,
      builder: (context, snapshot) {
        final userName = snapshot.data ?? '';

        return Scaffold(
          appBar: AppBar(
            title: const Text('Welcome to Ummaly'),
            actions: [
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text(
                    'Welcome, $userName',
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

                      Navigator.of(context).pop(); // Remove loader

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Signed out successfully')),
                      );

                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (context) => const AuthGate()),
                            (route) => false,
                      );
                    } catch (_) {
                      Navigator.of(context).pop(); // Remove loader

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Sign out failed'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.account_circle),
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: 'settings',
                    child: Text('Account Settings'),
                  ),
                  PopupMenuItem(
                    value: 'change_password',
                    child: Text('Change Password'),
                  ),
                  PopupMenuItem(
                    value: 'logout',
                    child: Text('Logout'),
                  ),
                ],
              ),
            ],
          ),
          body: const Center(
            child: Text('Home screen content goes here'),
          ),
        );
      },
    );
  }
}
