import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ummaly/features/auth/login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  String errorMessage = '';
  bool isLoading = false;
  bool registrationComplete = false;

  // Handles Firebase registration with logging
  Future<void> register() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      // Create user in Firebase Auth
      final UserCredential userCredential =
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      print("✅ Firebase Auth success");

      // Firestore write inside nested try block
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .set({
          'name': nameController.text.trim(),
          'email': emailController.text.trim(),
          'role_id': 'user',
          'created_at': Timestamp.now(),
          'updated_at': Timestamp.now(),
        });

        print("📦 Firestore write success");

        setState(() {
          registrationComplete = true;
          isLoading = false;
        });

        print("🎉 State updated: registrationComplete = true");

        WidgetsBinding.instance.addPostFrameCallback((_) {
          Future.delayed(const Duration(seconds: 3), () {
            if (mounted) {
              print("🔁 Redirecting to LoginScreen...");
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            }
          });
        });
      } catch (firestoreError) {
        print("❗ Firestore write failed: $firestoreError");
        setState(() {
          errorMessage = 'Failed to save user info';
          isLoading = false;
        });
      }
    } on FirebaseAuthException catch (e) {
      print("❌ FirebaseAuthException: ${e.message}");
      setState(() {
        errorMessage = e.message ?? 'Registration failed';
        isLoading = false;
      });
    } catch (e) {
      print("🔥 Unexpected error: $e");
      setState(() {
        errorMessage = 'An unexpected error occurred';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Register")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: registrationComplete
            ? const _RegistrationSuccess()
            : isLoading
            ? const Center(child: CircularProgressIndicator())
            : _buildRegistrationForm(),
      ),
    );
  }

  Widget _buildRegistrationForm() {
    return Column(
      children: [
        if (errorMessage.isNotEmpty)
          Text(errorMessage, style: const TextStyle(color: Colors.red)),
        TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: "Name"),
        ),
        TextField(
          controller: emailController,
          decoration: const InputDecoration(labelText: "Email"),
        ),
        TextField(
          controller: passwordController,
          decoration: const InputDecoration(labelText: "Password"),
          obscureText: true,
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: register,
          child: const Text("Register"),
        ),
        TextButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const LoginScreen()),
            );
          },
          child: const Text("Already have an account? Login here"),
        ),
      ],
    );
  }
}

// Confirmation UI
class _RegistrationSuccess extends StatefulWidget {
  const _RegistrationSuccess({super.key});

  @override
  State<_RegistrationSuccess> createState() => _RegistrationSuccessState();
}

class _RegistrationSuccessState extends State<_RegistrationSuccess> {
  @override
  void initState() {
    super.initState();

    // Redirect after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle, color: Colors.green, size: 80),
          SizedBox(height: 16),
          Text(
            'Registration successful!',
            style: TextStyle(fontSize: 20),
          ),
          SizedBox(height: 8),
          Text('Redirecting to login...'),
        ],
      ),
    );
  }
}
