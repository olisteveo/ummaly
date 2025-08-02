// Copyright © 2025 Oliver & Haidar. All rights reserved.
// This file is part of the Ummaly project and may not be reused,
// modified, or distributed without express written permission.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:ummaly/core/locale/locale_manager.dart';
import 'package:ummaly/theme/styles.dart'; // ✅ Shared styles

class AccountSettingsScreen extends StatefulWidget {
  const AccountSettingsScreen({Key? key}) : super(key: key);

  @override
  State<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String? _selectedLanguageCode;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  /// ✅ Load the current user's data into the fields
  Future<void> _loadUserData() async {
    final User? user = _auth.currentUser;
    if (user == null) return;

    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    if (userDoc.exists) {
      final data = userDoc.data() as Map<String, dynamic>;
      _nameController.text = data['name'] ?? '';
      _emailController.text = data['email'] ?? '';
      _selectedLanguageCode =
          data['language_preference'] ?? context.locale.languageCode;
      _passwordController.clear();
      setState(() {});
    }
  }

  /// ✅ Save updated name, email & language
  Future<void> _saveChanges() async {
    final User? user = _auth.currentUser;
    if (user == null) return;

    final updatedName = _nameController.text.trim();
    final updatedEmail = _emailController.text.trim();
    final updatedLang = _selectedLanguageCode;
    final password = _passwordController.text;

    if (password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('enter_current_password'.tr())),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // ✅ Step 1: Re-authenticate the user
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );
      await user.reauthenticateWithCredential(credential);

      // ✅ Step 2: Update email via FirebaseAuth.instance (sends verification email)
      if (updatedEmail != user.email) {
        await FirebaseAuth.instance.currentUser
            ?.verifyBeforeUpdateEmail(updatedEmail);
      }

      // ✅ Step 3: Update Firestore document
      await _firestore.collection('users').doc(user.uid).update({
        'name': updatedName,
        'email': updatedEmail,
        'language_preference': updatedLang,
        'updated_at': FieldValue.serverTimestamp(),
      });

      // ✅ Step 4: Apply new language instantly
      if (updatedLang != null && context.locale.languageCode != updatedLang) {
        await LocaleManager().updateUserLocale(updatedLang);
        if (mounted) {
          context.setLocale(Locale(updatedLang));
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('account_updated_success'.tr())),
      );
    } on FirebaseAuthException catch (e) {
      String errorMsg;
      if (e.code == 'requires-recent-login') {
        errorMsg = 'Please log out and log in again before changing email.';
      } else if (e.code == 'invalid-credential' || e.code == 'wrong-password') {
        errorMsg = 'Your current password is incorrect.';
      } else if (e.code == 'email-already-in-use') {
        errorMsg = 'That email is already in use by another account.';
      } else {
        errorMsg = 'update_failed'.tr();
      }
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(errorMsg)));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('update_failed'.tr())),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// ✅ Delete user account from Firestore & Firebase Auth
  Future<void> _deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore.collection('users').doc(user.uid).delete();
    await user.delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('account_settings'.tr())),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ✅ Name field
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(labelText: 'name'.tr()),
            ),
            const SizedBox(height: 16),

            // ✅ Email field
            TextFormField(
              controller: _emailController,
              decoration: InputDecoration(labelText: 'email'.tr()),
            ),
            const SizedBox(height: 16),

            // ✅ Language dropdown
            DropdownButtonFormField<String>(
              value: _selectedLanguageCode,
              items: [
                {'code': 'en', 'label': 'English'},
                {'code': 'fr', 'label': 'Français'},
                {'code': 'ar', 'label': 'العربية'},
                {'code': 'ur', 'label': 'اردو'},
              ]
                  .map(
                    (lang) => DropdownMenuItem(
                  value: lang['code'],
                  child: Text(lang['label']!),
                ),
              )
                  .toList(),
              onChanged: (val) {
                setState(() => _selectedLanguageCode = val);
              },
              decoration: InputDecoration(labelText: 'language'.tr()),
            ),
            const SizedBox(height: 16),

            // ✅ Password for reauthentication
            TextFormField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(labelText: 'password'.tr()),
            ),
            const SizedBox(height: 32),

            // ✅ Save button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: AppButtons.primaryButton,
                onPressed: _saveChanges,
                child: Text('update_account'.tr()),
              ),
            ),
            const SizedBox(height: 16),

            // ✅ Delete account
            TextButton(
              onPressed: _deleteAccount,
              child: Text(
                'delete_account'.tr(),
                style: AppTextStyles.error,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
