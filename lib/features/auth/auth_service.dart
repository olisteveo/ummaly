import 'dart:convert';
import 'dart:async';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:ummaly/config/config.dart'; // ✅ Import AppConfig for ngrok/LAN/emulator

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// ✅ Register a new user (Firebase + backend)
  Future<Map<String, dynamic>> registerUser(
      String name,
      String email,
      String password,
      ) async {
    try {
      // ✅ 1. Create user in Firebase
      final result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final firebaseUser = result.user;
      if (firebaseUser == null) {
        throw Exception('Firebase registration failed');
      }

      // ✅ 2. Get ID token safely
      final idToken = await firebaseUser.getIdToken();
      if (idToken == null || idToken.isEmpty) {
        throw Exception('Failed to retrieve Firebase ID token');
      }

      // ✅ 3. Send user info to backend for Neon DB registration
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
          'language_preference': 'en', // TODO: make dynamic later
        }),
      )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      }

      throw Exception('Backend registration failed: '
          '${response.statusCode} ${response.body}');
    } on TimeoutException {
      throw Exception('Registration timed out against ${AppConfig.baseUrl}');
    } on SocketException catch (e) {
      throw Exception('Network error during registration: $e');
    } catch (e) {
      throw Exception('Registration error: $e');
    }
  }

  /// ✅ Login user (Firebase + backend)
  Future<Map<String, dynamic>> loginUser(
      String email,
      String password,
      ) async {
    try {
      // ✅ 1. Sign in with Firebase
      final result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final firebaseUser = result.user;
      if (firebaseUser == null) {
        throw Exception('Firebase login failed');
      }

      // ✅ 2. Get ID token safely
      final idToken = await firebaseUser.getIdToken();
      if (idToken == null || idToken.isEmpty) {
        throw Exception('Failed to retrieve Firebase ID token');
      }

      // ✅ 3. Call backend to fetch Neon DB user
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
        return json.decode(response.body) as Map<String, dynamic>;
      }

      throw Exception('Backend login failed: '
          '${response.statusCode} ${response.body}');
    } on TimeoutException {
      throw Exception('Login timed out against ${AppConfig.baseUrl}');
    } on SocketException catch (e) {
      throw Exception('Network error during login: $e');
    } catch (e) {
      throw Exception('Login error: $e');
    }
  }

  /// ✅ Firebase sign out only (backend doesn’t need sign out)
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// ✅ Get currently signed in Firebase user
  User? get currentUser => _auth.currentUser;
}
