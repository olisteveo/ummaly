import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ummaly/features/home/home_screen.dart';
import 'package:ummaly/features/auth/register_screen.dart';
import 'package:ummaly/theme/styles.dart'; // Use shared colors, text, and button styles

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  String errorMessage = '';

  // Firebase email/password login
  Future<void> signIn() async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      // If successful, replace login screen with home
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } on FirebaseAuthException catch (e) {
      setState(() {
        errorMessage = e.message ?? 'Login failed';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Login")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Error message section using shared error text style
            if (errorMessage.isNotEmpty)
              Text(
                errorMessage,
                style: AppTextStyles.error, // replaced inline red TextStyle
              ),

            const SizedBox(height: 10),

            // Email field
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: "Email"),
              keyboardType: TextInputType.emailAddress,
            ),

            const SizedBox(height: 10),

            // Password field
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(labelText: "Password"),
              obscureText: true,
            ),

            // Forgot password link
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/forgot-password');
                },
                child: const Text("Forgot Password?"),
              ),
            ),

            const SizedBox(height: 20),

            // Login button using shared primary style
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: AppButtons.primaryButton, // applied global style
                onPressed: signIn,
                child: const Text("Login"),
              ),
            ),

            const SizedBox(height: 20),

            // Navigate to register screen
            Center(
              child: TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const RegisterScreen(),
                    ),
                  );
                },
                child: const Text("Don't have an account? Register here"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
