// Copyright © 2025 Oliver & Haidar. All rights reserved.
// This file is part of the Ummaly project and may not be reused,
// modified, or distributed without express written permission.

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ummaly/config/config.dart';

class AccountService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Loads the current user data directly from Neon DB via backend.
  Future<Map<String, dynamic>?> getUserFromBackend() async {
    final User? user = _auth.currentUser;
    if (user == null) return null;

    final idToken = await user.getIdToken();
    final response = await http.post(
      Uri.parse('${AppConfig.authEndpoint}/firebase-login'),
      headers: {
        'Authorization': 'Bearer $idToken',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body)['user'];
    } else {
      return null;
    }
  }

  /// Updates the user’s name, email, and language preference.
  /// Re-authenticates the user before making changes.
  Future<void> updateAccount({
    required String name,
    required String email,
    required String? language,
    required String currentPassword,
  }) async {
    final User? user = _auth.currentUser;
    if (user == null) {
      throw Exception('No user is currently logged in.');
    }

    final credential = EmailAuthProvider.credential(
      email: user.email!,
      password: currentPassword,
    );

    await user.reauthenticateWithCredential(credential);

    if (email != user.email) {
      await user.verifyBeforeUpdateEmail(email);
    }

    // You could also send this update to the backend here if needed
  }

  /// Sends a DELETE request to the backend to delete the user account.
  Future<void> deleteAccount() async {
    final User? user = _auth.currentUser;
    if (user == null) throw Exception('No user is currently logged in.');

    final idToken = await user.getIdToken();

    final response = await http.delete(
      Uri.parse('${AppConfig.authEndpoint}/account'),
      headers: {
        'Authorization': 'Bearer $idToken',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200 || response.statusCode == 401) {
      await _auth.signOut();
      return;
    }

    final error = json.decode(response.body)['error'] ?? 'Unknown error';
    throw Exception('Account deletion failed: $error');
  }
}
