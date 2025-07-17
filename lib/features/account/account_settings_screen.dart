// Copyright © 2025 Oliver & Haidar. All rights reserved.
// This file is part of the Ummaly project and may not be reused,
// modified, or distributed without express written permission.

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ummaly/features/auth/auth_gate.dart';

class AccountSettingsScreen extends StatefulWidget {
  const AccountSettingsScreen({super.key});

  @override
  State<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  String _error = '';
  String _success = '';
  bool _isLoading = false;
  bool _obscurePassword = true; // Controls password visibility

  // Load user data from Firestore
  Future<void> loadUserData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    final data = doc.data();

    if (data != null) {
      _nameController.text = data['name'] ?? '';
      _emailController.text = data['email'] ?? '';
    }
  }

  // Reauthenticate before sensitive actions
  Future<void> reauthenticate(String password) async {
    final user = FirebaseAuth.instance.currentUser;
    final cred = EmailAuthProvider.credential(
      email: user?.email ?? '',
      password: password,
    );
    await user?.reauthenticateWithCredential(cred);
  }

  // Update user info
  Future<void> updateUserData() async {
    setState(() {
      _isLoading = true;
      _error = '';
      _success = '';
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      final uid = user?.uid;

      if (user == null || uid == null) throw Exception("No user");

      if (_nameController.text.trim().isEmpty || _emailController.text.trim().isEmpty) {
        throw Exception("Name and email cannot be empty");
      }

      await reauthenticate(_passwordController.text.trim());

      await user.updateEmail(_emailController.text.trim());

      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'updated_at': Timestamp.now(),
      });

      setState(() => _success = 'Account updated successfully');
    } catch (e) {
      setState(() => _error = 'Update failed');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Delete user account
  Future<void> deleteAccount() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Account"),
        content: const Text("Are you sure you want to delete your account? This action is irreversible."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
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

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const AuthGate()),
            (route) => false,
      );
    } catch (e) {
      setState(() {
        _error = 'Account deletion failed';
        _isLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    loadUserData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Account'),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            if (_error.isNotEmpty)
              Text(_error, style: const TextStyle(color: Colors.red)),

            if (_success.isNotEmpty)
              Text(_success, style: const TextStyle(color: Colors.green)),

            const SizedBox(height: 10),

            // Name field
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),

            const SizedBox(height: 10),

            // Email field
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),

            const SizedBox(height: 10),

            // Current Password field with toggle visibility
            TextField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: 'Current Password',
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Update button
            ElevatedButton(
              onPressed: updateUserData,
              child: const Text('Update Account'),
            ),

            const SizedBox(height: 20),

            // Delete button
            TextButton(
              onPressed: deleteAccount,
              child: const Text('Delete Account', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      ),
    );
  }
}
