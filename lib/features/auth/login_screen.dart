import 'package:flutter/material.dart';
import 'package:ummaly/features/home/home_screen.dart';
import 'package:ummaly/features/auth/register_screen.dart';
import 'package:ummaly/features/auth/auth_service.dart'; // ✅ use new AuthService
import 'package:ummaly/theme/styles.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  final AuthService _authService = AuthService();

  String errorMessage = '';
  bool isLoading = false;

  /// ✅ Handles full login flow: Firebase + backend
  Future<void> signIn() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      // ✅ Call loginUser from AuthService
      await _authService.loginUser(
        emailController.text.trim(),
        passwordController.text.trim(),
      );

      // ✅ If successful, replace login screen with Home
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } catch (e) {
      // ✅ Clean up error string (remove “Exception:” wrapper)
      setState(() {
        errorMessage = e.toString().replaceFirst('Exception: ', '');
        isLoading = false;
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
            // ✅ Error message using shared style
            if (errorMessage.isNotEmpty)
              Text(
                errorMessage,
                style: AppTextStyles.error,
              ),

            const SizedBox(height: 10),

            // ✅ Email field
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: "Email"),
              keyboardType: TextInputType.emailAddress,
            ),

            const SizedBox(height: 10),

            // ✅ Password field
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(labelText: "Password"),
              obscureText: true,
            ),

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

            // ✅ Login button (shows loader when signing in)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: AppButtons.primaryButton,
                onPressed: isLoading ? null : signIn,
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Login"),
              ),
            ),

            const SizedBox(height: 20),

            // ✅ Link to register screen
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
