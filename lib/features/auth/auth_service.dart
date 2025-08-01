import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:ummaly/config/config.dart'; // ✅ Import AppConfig for ngrok URL

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// ✅ Register a new user (Firebase + backend)
  Future<Map<String, dynamic>> registerUser(String name, String email, String password) async {
    try {
      // ✅ 1. Create user in Firebase
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? firebaseUser = result.user;

      if (firebaseUser == null) {
        throw Exception("Firebase registration failed");
      }

      // ✅ 2. Get ID token safely (await + nullable handling)
      String? idToken = await firebaseUser.getIdToken();
      if (idToken == null || idToken.isEmpty) {
        throw Exception("Failed to retrieve Firebase ID token");
      }

      // ✅ 3. Send user info to backend for Neon DB registration
      final response = await http.post(
        Uri.parse("${AppConfig.authEndpoint}/firebase-register"), // ✅ Uses ngrok tunnel
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $idToken",
        },
        body: json.encode({
          "firebase_uid": firebaseUser.uid,
          "name": name,
          "email": email,
          "language_preference": "en", // TODO: make dynamic later
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception("Backend registration failed: ${response.body}");
      }
    } catch (e) {
      throw Exception("Registration error: $e");
    }
  }

  /// ✅ Login user (Firebase + backend)
  Future<Map<String, dynamic>> loginUser(String email, String password) async {
    try {
      // ✅ 1. Sign in with Firebase
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? firebaseUser = result.user;

      if (firebaseUser == null) {
        throw Exception("Firebase login failed");
      }

      // ✅ 2. Get ID token safely (await + nullable handling)
      String? idToken = await firebaseUser.getIdToken();
      if (idToken == null || idToken.isEmpty) {
        throw Exception("Failed to retrieve Firebase ID token");
      }

      // ✅ 3. Call backend to fetch Neon DB user
      final response = await http.post(
        Uri.parse("${AppConfig.authEndpoint}/firebase-login"), // ✅ Uses ngrok tunnel
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $idToken",
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception("Backend login failed: ${response.body}");
      }
    } catch (e) {
      throw Exception("Login error: $e");
    }
  }

  /// ✅ Firebase sign out only (backend doesn’t need sign out)
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// ✅ Get currently signed in Firebase user
  User? get currentUser => _auth.currentUser;
}
