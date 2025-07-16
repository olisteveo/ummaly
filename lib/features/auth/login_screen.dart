import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Navigate to after successful login
import 'package:ummaly/features/home/home_screen.dart';

// Navigate to register screen
import 'package:ummaly/features/auth/register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Controllers for user input
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  // Store error messages (e.g. wrong password, user not found)
  String errorMessage = '';

  // Firebase sign-in function
  Future<void> signIn() async {
    try {
      // Attempt to sign in with email & password
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      // If successful, go to home screen and remove login screen from stack
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } on FirebaseAuthException catch (e) {
      // If login fails, show error message
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
            // Show error message if login fails
            if (errorMessage.isNotEmpty)
              Text(
                errorMessage,
                style: const TextStyle(color: Colors.red),
              ),

            const SizedBox(height: 10),

            // Email input field
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: "Email"),
              keyboardType: TextInputType.emailAddress,
            ),

            const SizedBox(height: 10),

            // Password input field
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(labelText: "Password"),
              obscureText: true,
            ),

            // Forgot Password button (right-aligned)
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

            // Login button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: signIn,
                child: const Text("Login"),
              ),
            ),

            const SizedBox(height: 20),

            // Link to register page
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
