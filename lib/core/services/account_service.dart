// Copyright © 2025 Oliver & Haidar. All rights reserved.
// This file is part of the Ummaly project and may not be reused,
// modified, or distributed without express written permission.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AccountService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Loads the current user data from Firestore.
  /// Accepts an optional UID (defaults to the logged-in user).
  Future<Map<String, dynamic>?> getUserData({String? uid}) async {
    final String? effectiveUid = uid ?? _auth.currentUser?.uid;
    if (effectiveUid == null) return null;

    final userDoc = await _firestore.collection('users').doc(effectiveUid).get();
    return userDoc.exists ? userDoc.data() as Map<String, dynamic> : null;
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

    // Re-authenticate before sensitive changes
    final credential = EmailAuthProvider.credential(
      email: user.email!,
      password: currentPassword,
    );

    await user.reauthenticateWithCredential(credential);

    // If the email is changing, use Firebase's secure update flow
    if (email != user.email) {
      await user.verifyBeforeUpdateEmail(email);
    }

    // Update Firestore document with new details
    await _firestore.collection('users').doc(user.uid).update({
      'name': name,
      'email': email,
      'language_preference': language,
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  /// Deletes the user’s account from both FirebaseAuth and Firestore.
  Future<void> deleteAccount() async {
    final User? user = _auth.currentUser;
    if (user == null) {
      throw Exception('No user is currently logged in.');
    }

    // Delete Firestore document first
    await _firestore.collection('users').doc(user.uid).delete();

    // Delete the Firebase user account
    await user.delete();
  }
}
