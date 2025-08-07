// Copyright © 2025 Oliver & Haidar. All rights reserved.
// This file is part of the Ummaly project and may not be reused,
// modified, or distributed without express written permission.

import 'package:flutter/material.dart';
import 'package:ummaly/core/widgets/account_form.dart';
import 'package:ummaly/core/services/account_service.dart';

class AccountSettingsScreen extends StatefulWidget {
  const AccountSettingsScreen({Key? key}) : super(key: key);

  @override
  State<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String? _selectedLanguageCode;
  bool _isLoading = false;

  final AccountService _accountService = AccountService();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  /// Loads the current user's details (name, email, language) from backend
  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);

    final data = await _accountService.getUserFromBackend();

    if (data != null && mounted) {
      setState(() {
        _nameController.text = data['name'] ?? '';
        _emailController.text = data['email'] ?? '';
        _selectedLanguageCode = data['language_preference'] ?? 'en';
      });
    }

    setState(() => _isLoading = false);
  }

  /// Handles saving updated account settings
  Future<void> _saveChanges() async {
    setState(() => _isLoading = true);

    try {
      await _accountService.updateAccount(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        currentPassword: _passwordController.text.trim(),
        language: _selectedLanguageCode ?? 'en',
      );
    } catch (e) {
      debugPrint('Error updating account: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update account')),
        );
      }
    }

    setState(() => _isLoading = false);
  }

  /// Shows a confirmation dialog before deleting account
  Future<void> _confirmDeleteAccount() async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Delete Account'),
          content: const Text(
            'Are you sure you want to delete your account? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete == true) {
      await _deleteAccount();
    }
  }

  /// Handles account deletion
  Future<void> _deleteAccount() async {
    setState(() => _isLoading = true);

    try {
      await _accountService.deleteAccount();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account deleted successfully')),
        );

        Navigator.of(context).pushNamedAndRemoveUntil(
          '/auth/login',
              (route) => false,
        );
      }
    } catch (e) {
      debugPrint('Error deleting account: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete account')),
        );
      }
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Account Settings')),
      body: _isLoading && (_nameController.text.isEmpty)
          ? const Center(child: CircularProgressIndicator())
          : AbsorbPointer(
        absorbing: _isLoading,
        child: AccountForm(
          nameController: _nameController,
          emailController: _emailController,
          passwordController: _passwordController,
          selectedLanguageCode: _selectedLanguageCode,
          onLanguageChanged: (val) => setState(() {
            _selectedLanguageCode = val;
          }),
          onSave: _saveChanges,
          onDelete: _confirmDeleteAccount,
          isLoading: _isLoading,
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
