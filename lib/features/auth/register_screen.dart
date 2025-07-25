import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ummaly/features/auth/login_screen.dart';
import 'package:ummaly/theme/styles.dart'; // Import shared styles

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
  bool emailSent = false;
  bool verifying = false;

  Future<void> register() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final UserCredential userCredential =
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      final user = userCredential.user;

      if (user != null) {
        // Create user document in Firestore
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'name': nameController.text.trim(),
          'email': emailController.text.trim(),
          'role_id': 'user',
          'language_preference': 'en',
          'created_at': Timestamp.now(),
          'updated_at': Timestamp.now(),
          'email_verified': false,
        });

        await user.sendEmailVerification();

        setState(() {
          emailSent = true;
          isLoading = false;
        });
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        errorMessage = e.message ?? 'Registration failed';
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'An unexpected error occurred';
        isLoading = false;
      });
    }
  }

  Future<void> checkEmailVerifiedAndWriteToFirestore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() {
      verifying = true;
      errorMessage = '';
    });

    await user.reload();
    final refreshedUser = FirebaseAuth.instance.currentUser;

    if (refreshedUser != null && refreshedUser.emailVerified) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(refreshedUser.uid)
            .update({
          'email_verified': true,
          'updated_at': Timestamp.now(),
        });

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      } catch (e) {
        setState(() {
          errorMessage = 'Failed to update Firestore after verification.';
        });
      }
    } else {
      setState(() {
        errorMessage = 'Please verify your email before continuing.';
      });
    }

    setState(() {
      verifying = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Register")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : emailSent
            ? _buildEmailVerificationPrompt()
            : _buildRegistrationForm(),
      ),
    );
  }

  // Registration form UI
  Widget _buildRegistrationForm() {
    return Column(
      children: [
        if (errorMessage.isNotEmpty)
          Text(
            errorMessage,
            style: AppTextStyles.error, // replaced inline red text style
          ),
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
          style: AppButtons.primaryButton, // use shared primary button style
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

  // Email verification UI after registration
  Widget _buildEmailVerificationPrompt() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.email, color: Colors.blue, size: 80),
        const SizedBox(height: 16),
        Text(
          'Verification email sent!',
          style: AppTextStyles.heading.copyWith(fontSize: 20),
          // replaced inline TextStyle(fontSize: 20)
        ),
        const SizedBox(height: 8),
        const Text('Please check your inbox and verify your email.'),
        const SizedBox(height: 20),
        if (errorMessage.isNotEmpty)
          Text(
            errorMessage,
            style: AppTextStyles.error, // replaced inline red text style
          ),
        ElevatedButton(
          style: AppButtons.primaryButton, // consistent button styling
          onPressed: verifying ? null : checkEmailVerifiedAndWriteToFirestore,
          child: verifying
              ? const CircularProgressIndicator()
              : const Text("I have verified my email"),
        ),
      ],
    );
  }
}
