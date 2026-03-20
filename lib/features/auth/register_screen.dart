import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:ummaly/features/auth/login_screen.dart';
import 'package:ummaly/features/onboarding/onboarding_screen.dart';
import 'package:ummaly/theme/styles.dart';
import 'package:ummaly/theme/islamic_patterns.dart';
import 'package:ummaly/theme/animated_logo.dart';
import 'package:ummaly/features/auth/auth_service.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:ummaly/features/shell/app_shell.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  final AuthService _authService = AuthService();

  String errorMessage = '';
  bool isLoading = false;
  bool emailSent = false;
  bool verifying = false;
  bool _obscure = true;
  bool _isGoogleLoading = false;

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> register() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      await _authService.registerUser(
        nameController.text.trim(),
        emailController.text.trim(),
        passwordController.text.trim(),
      );

      final user = FirebaseAuth.instance.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
      }

      setState(() {
        emailSent = true;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString().replaceFirst('Exception: ', '');
        isLoading = false;
      });
    }
  }

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
      Get.off(() => const LoginScreen());
    } else {
      setState(() {
        errorMessage = 'Please verify your email before continuing.';
      });
    }

    setState(() {
      verifying = false;
    });
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isGoogleLoading = true;
      errorMessage = '';
    });

    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        setState(() => _isGoogleLoading = false);
        return;
      }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);
      if (!mounted) return;
      Get.offAll(() => const AppShell());
    } catch (e) {
      if (!mounted) return;
      setState(() {
        errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isGoogleLoading = false;
      });
    }
  }

  InputDecoration _darkInputDecoration({
    required String label,
    required IconData prefixIcon,
    Widget? suffixIcon,
  }) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.l),
      borderSide: BorderSide(color: AppColors.gold.withOpacity(0.2)),
    );
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(
        color: AppColors.cream.withOpacity(0.5),
        fontFamily: 'Poppins',
        fontSize: 15,
      ),
      prefixIcon: Icon(prefixIcon, color: AppColors.gold.withOpacity(0.6), size: 20),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: const Color(0xFF1A2540),
      enabledBorder: border,
      focusedBorder: border.copyWith(
        borderSide: const BorderSide(color: AppColors.gold, width: 1.5),
      ),
      errorBorder: border.copyWith(
        borderSide: BorderSide(color: AppColors.error.withOpacity(0.8)),
      ),
      focusedErrorBorder: border.copyWith(
        borderSide: const BorderSide(color: AppColors.error, width: 1.5),
      ),
      errorStyle: const TextStyle(color: Color(0xFFFF8A80), fontSize: 12),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.l,
        vertical: 14,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      backgroundColor: const Color(0xFF0F1A2E),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(gradient: AppGradients.authBackground),
        child: SafeArea(
          child: isLoading
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(
                        color: AppColors.gold,
                        strokeWidth: 2.5,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Creating your account...',
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.cream,
                        ),
                      ),
                    ],
                  ),
                )
              : emailSent
                  ? IslamicPatternBackground(
                      child: _buildEmailVerificationPrompt(),
                    )
                  : IslamicPatternBackground(
                      child: _buildRegistrationForm(bottomInset),
                    ),
        ),
      ),
    );
  }

  Widget _buildRegistrationForm(double bottomInset) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(24, 12, 24, 24 + bottomInset),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            // Back button
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                onPressed: () {
                  if (Get.previousRoute.isNotEmpty) {
                    Get.back();
                  } else {
                    Get.off(() => const OnboardingScreen());
                  }
                },
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: AppColors.cream,
                  size: 22,
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Crescent moon
            const UmmalyLogo(size: 60, color: AppColors.gold),
            const SizedBox(height: 24),

            // Heading
            Text(
              'Create Account',
              style: AppTextStyles.heading.copyWith(
                color: AppColors.gold,
                fontSize: 28,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Join the Ummaly community',
              style: AppTextStyles.body.copyWith(
                color: AppColors.cream,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 28),

            // Error message
            if (errorMessage.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppRadius.m),
                  border: Border.all(
                    color: AppColors.error.withOpacity(0.4),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline,
                        color: Color(0xFFFF8A80), size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        errorMessage,
                        style: const TextStyle(
                          color: Color(0xFFFF8A80),
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Name field
            TextFormField(
              controller: nameController,
              style: const TextStyle(color: AppColors.cream, fontFamily: 'Poppins'),
              decoration: _darkInputDecoration(
                label: 'Name',
                prefixIcon: Icons.person_outline,
              ),
              textInputAction: TextInputAction.next,
              validator: (v) {
                final value = v?.trim() ?? '';
                if (value.isEmpty) return 'Name is required';
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Email field
            TextFormField(
              controller: emailController,
              style: const TextStyle(color: AppColors.cream, fontFamily: 'Poppins'),
              decoration: _darkInputDecoration(
                label: 'Email',
                prefixIcon: Icons.mail_outline,
              ),
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
              validator: (v) {
                final value = v?.trim() ?? '';
                if (value.isEmpty) return 'Email is required';
                if (!value.contains('@') || !value.contains('.')) {
                  return 'Enter a valid email';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Password field
            TextFormField(
              controller: passwordController,
              style: const TextStyle(color: AppColors.cream, fontFamily: 'Poppins'),
              decoration: _darkInputDecoration(
                label: 'Password',
                prefixIcon: Icons.lock_outline,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscure ? Icons.visibility_off : Icons.visibility,
                    color: AppColors.gold.withOpacity(0.6),
                    size: 20,
                  ),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
              obscureText: _obscure,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => register(),
              validator: (v) {
                final value = v ?? '';
                if (value.isEmpty) return 'Password is required';
                if (value.length < 6) return 'At least 6 characters';
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Register button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: AppButtons.goldButton,
                onPressed: register,
                child: const Text(
                  'Register',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Divider
            Row(
              children: [
                Expanded(
                  child: Divider(color: AppColors.cream.withOpacity(0.2)),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'or',
                    style: TextStyle(
                      color: AppColors.cream.withOpacity(0.5),
                      fontFamily: 'Poppins',
                      fontSize: 14,
                    ),
                  ),
                ),
                Expanded(
                  child: Divider(color: AppColors.cream.withOpacity(0.2)),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Google Sign In button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.cream,
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.l),
                  ),
                  side: BorderSide(
                    color: AppColors.cream.withOpacity(0.25),
                    width: 1,
                  ),
                ),
                onPressed: _isGoogleLoading ? null : _signInWithGoogle,
                icon: _isGoogleLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.cream,
                        ),
                      )
                    : Image.network(
                        'https://developers.google.com/identity/images/g-logo.png',
                        height: 20,
                        width: 20,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.g_mobiledata,
                          size: 24,
                          color: AppColors.cream,
                        ),
                      ),
                label: const Text(
                  'Continue with Google',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Sign in link
            Center(
              child: GestureDetector(
                onTap: () {
                  Get.off(() => const LoginScreen());
                },
                child: RichText(
                  text: const TextSpan(
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      color: AppColors.cream,
                    ),
                    children: [
                      TextSpan(text: 'Already have an account? '),
                      TextSpan(
                        text: 'Sign In',
                        style: TextStyle(
                          color: AppColors.gold,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildEmailVerificationPrompt() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.gold.withOpacity(0.12),
              ),
              child: const Icon(
                Icons.mail_outline,
                color: AppColors.gold,
                size: 44,
              ),
            ),
            const SizedBox(height: 24),

            Text(
              'Verification Email Sent!',
              style: AppTextStyles.heading.copyWith(
                color: AppColors.gold,
                fontSize: 24,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),

            Text(
              'Please check your inbox and verify your email address to continue.',
              style: AppTextStyles.body.copyWith(
                color: AppColors.cream,
                fontSize: 15,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),

            if (errorMessage.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppRadius.m),
                  border: Border.all(
                    color: AppColors.error.withOpacity(0.4),
                    width: 1,
                  ),
                ),
                child: Text(
                  errorMessage,
                  style: const TextStyle(
                    color: Color(0xFFFF8A80),
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 20),
            ],

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: AppButtons.goldButton,
                onPressed: verifying ? null : checkEmailVerified,
                child: verifying
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.darkSurface,
                        ),
                      )
                    : const Text(
                        'I Have Verified My Email',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Poppins',
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
