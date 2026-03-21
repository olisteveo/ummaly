import 'dart:convert';
import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:ummaly/config/config.dart';
import 'package:ummaly/core/services/scan_quota_service.dart';
import 'package:ummaly/core/services/subscription_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Translates Firebase error codes into user-friendly messages.
  static String friendlyError(dynamic e) {
    // FirebaseAuthException extends FirebaseException — catch both
    if (e is FirebaseException) {
      switch (e.code) {
        case 'email-already-in-use':
          return 'This email is already registered. Try signing in instead.';
        case 'invalid-email':
          return 'Please enter a valid email address.';
        case 'weak-password':
          return 'Password is too weak. Use at least 6 characters.';
        case 'user-not-found':
          return 'No account found with this email.';
        case 'wrong-password':
          return 'Incorrect password. Please try again.';
        case 'invalid-credential':
          return 'Incorrect email or password. Please try again.';
        case 'user-disabled':
          return 'This account has been disabled. Contact support.';
        case 'too-many-requests':
          return 'Too many attempts. Please wait a moment and try again.';
        case 'network-request-failed':
          return 'Network error. Check your internet connection.';
        case 'operation-not-allowed':
          return 'This sign-in method is not enabled.';
        case 'account-exists-with-different-credential':
          return 'An account already exists with this email using a different sign-in method.';
        default:
          return 'Something went wrong. Please try again.';
      }
    }
    if (e is TimeoutException) {
      return 'Connection timed out. Please check your internet and try again.';
    }
    final msg = e.toString();
    // Strip any "Exception: " prefix for cleaner display
    return msg.replaceFirst(RegExp(r'^Exception:\s*'), '');
  }

  /// ✅ Register a new user (Firebase + backend)
  Future<Map<String, dynamic>> registerUser(
      String name,
      String email,
      String password,
      ) async {
    try {
      // 1. Create user in Firebase
      final result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final firebaseUser = result.user;
      if (firebaseUser == null) {
        throw Exception('Registration failed. Please try again.');
      }

      // 2. Get ID token safely
      final idToken = await firebaseUser.getIdToken();
      if (idToken == null || idToken.isEmpty) {
        throw Exception('Authentication error. Please try again.');
      }

      // 3. Send user info to backend for Neon DB registration
      final uri = Uri.parse('${AppConfig.authEndpoint}/firebase-register');

      final response = await http
          .post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
        body: json.encode({
          'firebase_uid': firebaseUser.uid,
          'name': name,
          'email': email,
          'language_preference': 'en',
        }),
      )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        await ScanQuotaService().resetCounters();
        await SubscriptionService.instance.identify(firebaseUser.uid);
        return json.decode(response.body) as Map<String, dynamic>;
      }

      throw Exception('Could not complete registration. Please try again.');
    } on FirebaseException catch (e) {
      throw Exception(friendlyError(e));
    } on TimeoutException {
      throw Exception(friendlyError(TimeoutException('timeout')));
    } catch (e) {
      if (e is Exception && e.toString().contains('Exception: ')) {
        rethrow; // Already a friendly message
      }
      throw Exception(friendlyError(e));
    }
  }

  /// ✅ Login user (Firebase + backend)
  Future<Map<String, dynamic>> loginUser(
      String email,
      String password,
      ) async {
    try {
      // 1. Sign in with Firebase
      final result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final firebaseUser = result.user;
      if (firebaseUser == null) {
        throw Exception('Login failed. Please try again.');
      }

      // 2. Get ID token safely
      final idToken = await firebaseUser.getIdToken();
      if (idToken == null || idToken.isEmpty) {
        throw Exception('Authentication error. Please try again.');
      }

      // 3. Call backend to fetch Neon DB user
      final uri = Uri.parse('${AppConfig.authEndpoint}/firebase-login');

      final response = await http
          .post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
      )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        await ScanQuotaService().resetCounters();
        await SubscriptionService.instance.identify(firebaseUser.uid);
        return json.decode(response.body) as Map<String, dynamic>;
      }

      throw Exception('Could not complete login. Please try again.');
    } on FirebaseException catch (e) {
      throw Exception(friendlyError(e));
    } on TimeoutException {
      throw Exception(friendlyError(TimeoutException('timeout')));
    } catch (e) {
      if (e is Exception && e.toString().contains('Exception: ')) {
        rethrow;
      }
      throw Exception(friendlyError(e));
    }
  }

  /// ✅ Firebase sign out only (backend doesn’t need sign out)
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// ✅ Get currently signed in Firebase user
  User? get currentUser => _auth.currentUser;
}
