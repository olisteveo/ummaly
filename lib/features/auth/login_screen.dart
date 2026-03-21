import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ummaly/features/shell/app_shell.dart';
import 'package:ummaly/features/auth/register_screen.dart';
import 'package:ummaly/features/auth/auth_service.dart';
import 'package:ummaly/features/auth/forgot_password.dart';
import 'package:ummaly/features/onboarding/onboarding_screen.dart';
import 'package:ummaly/theme/styles.dart';
import 'package:ummaly/theme/islamic_patterns.dart';
import 'package:ummaly/theme/animated_logo.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _passwordFocus = FocusNode();

  final AuthService _authService = AuthService();

  String _error = '';
  bool _isLoading = false;
  bool _obscure = true;
  bool _isGoogleLoading = false;

  @override
  void dispose() {
    _email.dispose();
    _passwordFocus.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      await _authService.loginUser(
        _email.text.trim(),
        _password.text.trim(),
      );
      if (!mounted) return;
      Get.offAll(() => const AppShell());
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isGoogleLoading = true;
      _error = '';
    });

    try {
      if (kIsWeb) {
        // Web: use Firebase Auth signInWithPopup directly
        final provider = GoogleAuthProvider();
        await FirebaseAuth.instance.signInWithPopup(provider);
      } else {
        // Mobile: use google_sign_in package
        final googleUser = await GoogleSignIn().signIn();
        if (googleUser == null) {
          setState(() => _isGoogleLoading = false);
          return; // User cancelled
        }

        final googleAuth = await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        await FirebaseAuth.instance.signInWithCredential(credential);
      }

      if (!mounted) return;
      Get.offAll(() => const AppShell());
    } on FirebaseException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = AuthService.friendlyError(e);
        _isGoogleLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Google sign-in failed. Please try again.';
        _isGoogleLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      backgroundColor: const Color(0xFF0F1A2E),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: AppGradients.authBackground,
        ),
        child: SafeArea(
          child: IslamicPatternBackground(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(24, 12, 24, 24 + bottomInset),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Back button
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      onPressed: () => Get.off(() => const OnboardingScreen()),
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: AppColors.cream,
                        size: 22,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Ummaly logo (crescent + star + mosque)
                  const UmmalyLogo(
                    size: 80,
                    color: AppColors.gold,
                  ),
                  const SizedBox(height: 20),

                  // App name
                  Text(
                    'Ummaly',
                    style: AppTextStyles.title.copyWith(
                      color: AppColors.gold,
                      fontSize: 36,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Welcome subtitle
                  Text(
                    'Welcome back',
                    style: AppTextStyles.subtitle.copyWith(
                      color: AppColors.cream,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Error message
                  if (_error.isNotEmpty) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2A1520),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: const Color(0xFF5C2A3A),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFFFF6B6B).withOpacity(0.15),
                            ),
                            child: const Icon(
                              Icons.info_outline_rounded,
                              color: Color(0xFFFF8A80),
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _error,
                              style: const TextStyle(
                                color: Color(0xFFFFB4AB),
                                fontFamily: 'Poppins',
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Email field
                  TextFormField(
                    controller: _email,
                    style: const TextStyle(
                      color: AppColors.cream,
                      fontFamily: 'Poppins',
                      fontSize: 16,
                    ),
                    decoration: _darkInputDecoration(
                      label: 'Email',
                      icon: Icons.mail_outline,
                    ),
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [
                      AutofillHints.username,
                      AutofillHints.email,
                    ],
                    onFieldSubmitted: (_) => _passwordFocus.requestFocus(),
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
                    controller: _password,
                    focusNode: _passwordFocus,
                    style: const TextStyle(
                      color: AppColors.cream,
                      fontFamily: 'Poppins',
                      fontSize: 16,
                    ),
                    decoration: _darkInputDecoration(
                      label: 'Password',
                      icon: Icons.lock_outline,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscure ? Icons.visibility_off : Icons.visibility,
                          color: AppColors.gold.withOpacity(0.6),
                          size: 22,
                        ),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                    obscureText: _obscure,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.password],
                    onFieldSubmitted: (_) => _signIn(),
                    validator: (v) {
                      final value = v ?? '';
                      if (value.isEmpty) return 'Password is required';
                      if (value.length < 6) return 'At least 6 characters';
                      return null;
                    },
                  ),

                  // Forgot password link
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        Get.to(() => const ForgotPasswordPage());
                      },
                      child: const Text(
                        'Forgot Password?',
                        style: TextStyle(
                          color: AppColors.gold,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Login button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: AppButtons.goldButton,
                      onPressed: _isLoading ? null : _signIn,
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.darkSurface,
                              ),
                            )
                          : const Text('Login'),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Divider
                  Row(
                    children: [
                      Expanded(
                        child: Divider(
                          color: AppColors.cream.withOpacity(0.2),
                        ),
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
                        child: Divider(
                          color: AppColors.cream.withOpacity(0.2),
                        ),
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
                  const SizedBox(height: 24),

                  // Register link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Don't have an account? ",
                        style: TextStyle(
                          color: AppColors.cream.withOpacity(0.7),
                          fontFamily: 'Poppins',
                          fontSize: 14,
                        ),
                      ),
                      GestureDetector(
                        onTap: _isLoading
                            ? null
                            : () {
                                Get.to(() => const RegisterScreen());
                              },
                        child: const Text(
                          'Register',
                          style: TextStyle(
                            color: AppColors.gold,
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          ),
        ),
      ),
    );
  }

  InputDecoration _darkInputDecoration({
    required String label,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    const fillColor = Color(0xFF1A2540);
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.l),
      borderSide: BorderSide(color: AppColors.gold.withOpacity(0.15)),
    );

    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(
        color: AppColors.cream.withOpacity(0.5),
        fontFamily: 'Poppins',
        fontSize: 15,
      ),
      prefixIcon: Icon(icon, color: AppColors.gold.withOpacity(0.6), size: 22),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: fillColor,
      enabledBorder: border,
      focusedBorder: border.copyWith(
        borderSide: BorderSide(color: AppColors.gold.withOpacity(0.5), width: 1.5),
      ),
      errorBorder: border.copyWith(
        borderSide: const BorderSide(color: AppColors.error),
      ),
      focusedErrorBorder: border.copyWith(
        borderSide: const BorderSide(color: AppColors.error, width: 1.5),
      ),
      errorStyle: const TextStyle(color: Color(0xFFFF8A8A), fontSize: 12),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.l,
        vertical: AppSpacing.m + 4,
      ),
    );
  }
}
