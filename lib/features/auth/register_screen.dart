import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ummaly/features/auth/login_screen.dart';
import 'package:ummaly/theme/styles.dart';
import 'package:ummaly/features/auth/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  final AuthService _authService = AuthService();

  String errorMessage = '';
  bool isLoading = false;
  bool emailSent = false;
  bool verifying = false;

  /// Handles full registration flow: Firebase + Backend + email verification
  Future<void> register() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      // Step 1: Register user in Firebase and backend via AuthService
      await _authService.registerUser(
        nameController.text.trim(),
        emailController.text.trim(),
        passwordController.text.trim(),
      );

      // Step 2: Send email verification
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
      }

      setState(() {
        emailSent = true;
        isLoading = false;
      });
    } catch (e) {
      // Clean up error message so it’s not wrapped in “Exception:”
      setState(() {
        errorMessage = e.toString().replaceFirst('Exception: ', '');
        isLoading = false;
      });
    }
  }

  /// Checks if email has been verified
  Future<void> checkEmailVerified() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() {
      verifying = true;
      errorMessage = '';
    });

    await user.reload();
    final refreshedUser = FirebaseAuth.instance.currentUser;

    if (refreshedUser != null && refreshedUser.emailVerified) {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
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
            style: AppTextStyles.error,
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
          style: AppButtons.primaryButton,
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

  // Email verification UI
  Widget _buildEmailVerificationPrompt() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.email, color: Colors.blue, size: 80),
        const SizedBox(height: 16),
        Text(
          'Verification email sent!',
          style: AppTextStyles.heading.copyWith(fontSize: 20),
        ),
        const SizedBox(height: 8),
        const Text('Please check your inbox and verify your email.'),
        const SizedBox(height: 20),
        if (errorMessage.isNotEmpty)
          Text(
            errorMessage,
            style: AppTextStyles.error,
          ),
        ElevatedButton(
          style: AppButtons.primaryButton,
          onPressed: verifying ? null : checkEmailVerified,
          child: verifying
              ? const CircularProgressIndicator()
              : const Text("I have verified my email"),
        ),
      ],
    );
  }
}
