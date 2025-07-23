// Copyright © 2025 Oliver & Haidar. All rights reserved.
// This file is part of the Ummaly project and may not be reused,
// modified, or distributed without express written permission.

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ummaly/features/auth/auth_gate.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:ummaly/core/locale/locale_manager.dart';
import 'package:ummaly/core/widgets/snackbar_helper.dart';

class AccountSettingsScreen extends StatefulWidget {
  const AccountSettingsScreen({super.key});

  @override
  State<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;

  final List<Map<String, String>> _languageOptions = [
    {'label': 'English', 'code': 'en'},
    {'label': 'Français', 'code': 'fr'},
    {'label': 'العربية', 'code': 'ar'},
    {'label': 'اردو', 'code': 'ur'},
  ];

  String _selectedLanguage = 'en';

  @override
  void initState() {
    super.initState();
    loadUserData();
  }

  Future<void> loadUserData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    final data = doc.data();

    if (data != null) {
      _nameController.text = data['name'] ?? '';
      _emailController.text = data['email'] ?? '';
      _selectedLanguage = data['language_preference'] ?? 'en';
    }
  }

  Future<void> reauthenticate(String password) async {
    final user = FirebaseAuth.instance.currentUser;
    final cred = EmailAuthProvider.credential(
      email: user?.email ?? '',
      password: password,
    );
    await user?.reauthenticateWithCredential(cred);
  }

  Future<void> updateUserData() async {
    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      final uid = user?.uid;

      if (user == null || uid == null) throw Exception("No user");

      if (_nameController.text.trim().isEmpty || _emailController.text.trim().isEmpty) {
        throw Exception(tr('name_email_required'));
      }

      if (_passwordController.text.trim().isEmpty) {
        throw Exception(tr('password_required'));
      }

      await reauthenticate(_passwordController.text.trim());
      await user.updateEmail(_emailController.text.trim());

      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'language_preference': _selectedLanguage,
        'updated_at': Timestamp.now(),
      });

      await LocaleManager().updateUserLocale(_selectedLanguage, context: context);

      WidgetsBinding.instance.addPostFrameCallback((_) {
        SnackbarHelper.show(context, tr('account_updated_success'));
      });
    } catch (e) {
      SnackbarHelper.show(
        context,
        e.toString().contains('password') ? e.toString() : tr('update_failed'),
        backgroundColor: Colors.red,
      );
    } finally {
      setState(() => _isLoading = false);
      _passwordController.clear(); // ✅ clear password
    }
  }

  Future<void> deleteAccount() async {
    if (_passwordController.text.trim().isEmpty) {
      SnackbarHelper.show(context, tr('password_required'), backgroundColor: Colors.red);
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tr('delete_account')),
        content: Text(tr('delete_account_confirm')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(tr('cancel'))),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(tr('delete'), style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      final uid = user?.uid;
      if (user == null || uid == null) throw Exception("No user");

      await reauthenticate(_passwordController.text.trim());

      await FirebaseFirestore.instance.collection('users').doc(uid).delete();
      await user.delete();

      _passwordController.clear(); // ✅ clear password before navigating
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const AuthGate()),
            (route) => false,
      );
    } catch (e) {
      SnackbarHelper.show(
        context,
        e.toString().contains('password') ? e.toString() : tr('delete_failed'),
        backgroundColor: Colors.red,
      );
      setState(() => _isLoading = false);
      _passwordController.clear(); // ✅ also clear on failure
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(tr('manage_account')),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            const SizedBox(height: 10),
            Text(tr('account_update_note'), style: const TextStyle(color: Colors.black87)),
            const SizedBox(height: 20),

            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: tr('name')),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: tr('email')),
            ),
            const SizedBox(height: 10),

            DropdownButtonFormField<String>(
              value: _selectedLanguage,
              decoration: InputDecoration(labelText: tr('language_preference')),
              items: _languageOptions.map((lang) {
                return DropdownMenuItem<String>(
                  value: lang['code'],
                  child: Text(lang['label'] ?? ''),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedLanguage = value;
                  });
                }
              },
            ),

            const SizedBox(height: 10),
            TextField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: tr('current_password'),
                suffixIcon: IconButton(
                  icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: updateUserData,
              child: Text(tr('update_account')),
            ),
            const SizedBox(height: 20),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(48),
              ),
              onPressed: deleteAccount,
              child: Text(tr('delete_account')),
            ),
          ],
        ),
      ),
    );
  }
}
