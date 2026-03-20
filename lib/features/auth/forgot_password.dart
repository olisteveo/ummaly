import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:ummaly/theme/styles.dart';
import 'package:ummaly/theme/islamic_patterns.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final TextEditingController _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _emailSent = false;
  String _error = '';

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendResetLink() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: _emailController.text.trim(),
      );
      setState(() {
        _emailSent = true;
        _isLoading = false;
      });
    } on FirebaseAuthException catch (e) {
      setState(() {
        _error = e.message ?? 'Something went wrong.';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Back button
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    onPressed: () => Get.back(),
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: AppColors.cream,
                      size: 22,
                    ),
                  ),
                ),
                const SizedBox(height: 40),

                // Lock icon
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.gold.withOpacity(0.12),
                  ),
                  child: const Icon(
                    Icons.lock_reset_rounded,
                    color: AppColors.gold,
                    size: 44,
                  ),
                ),
                const SizedBox(height: 28),

                // Heading
                Text(
                  _emailSent ? 'Check Your Email' : 'Forgot Password',
                  style: AppTextStyles.heading.copyWith(
                    color: AppColors.gold,
                    fontSize: 28,
                  ),
                ),
                const SizedBox(height: 12),

                // Subtitle
                Text(
                  _emailSent
                      ? 'We\'ve sent a password reset link to your email address.'
                      : 'Enter your email and we\'ll send you a reset link.',
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.cream.withOpacity(0.75),
                    fontSize: 15,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 36),

                if (_emailSent) ...[
                  // Success state
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D7377).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(AppRadius.m),
                      border: Border.all(
                        color: const Color(0xFF0D7377).withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.check_circle_outline,
                          color: Color(0xFF0D7377),
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Reset link sent to ${_emailController.text.trim()}',
                            style: const TextStyle(
                              color: AppColors.cream,
                              fontFamily: 'Poppins',
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: AppButtons.goldButton,
                      onPressed: () => Get.back(),
                      child: const Text(
                        'Back to Login',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                  ),
                ] else ...[
                  // Form state
                  if (_error.isNotEmpty) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppRadius.m),
                        border: Border.all(
                          color: AppColors.error.withOpacity(0.4),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline,
                              color: Color(0xFFFF8A80), size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _error,
                              style: const TextStyle(
                                color: Color(0xFFFF8A80),
                                fontFamily: 'Poppins',
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _emailController,
                          style: const TextStyle(
                            color: AppColors.cream,
                            fontFamily: 'Poppins',
                            fontSize: 16,
                          ),
                          decoration: InputDecoration(
                            labelText: 'Email',
                            labelStyle: TextStyle(
                              color: AppColors.cream.withOpacity(0.5),
                              fontFamily: 'Poppins',
                              fontSize: 15,
                            ),
                            prefixIcon: Icon(
                              Icons.mail_outline,
                              color: AppColors.gold.withOpacity(0.6),
                              size: 22,
                            ),
                            filled: true,
                            fillColor: const Color(0xFF1A2540),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppRadius.l),
                              borderSide: BorderSide(
                                color: AppColors.gold.withOpacity(0.15),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppRadius.l),
                              borderSide: BorderSide(
                                color: AppColors.gold.withOpacity(0.5),
                                width: 1.5,
                              ),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppRadius.l),
                              borderSide: const BorderSide(
                                color: AppColors.error,
                              ),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppRadius.l),
                              borderSide: const BorderSide(
                                color: AppColors.error,
                                width: 1.5,
                              ),
                            ),
                            errorStyle: const TextStyle(
                              color: Color(0xFFFF8A8A),
                              fontSize: 12,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.l,
                              vertical: AppSpacing.m + 4,
                            ),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _sendResetLink(),
                          validator: (v) {
                            final value = v?.trim() ?? '';
                            if (value.isEmpty) return 'Email is required';
                            if (!value.contains('@') || !value.contains('.')) {
                              return 'Enter a valid email';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 28),

                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: AppButtons.goldButton,
                            onPressed: _isLoading ? null : _sendResetLink,
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.darkSurface,
                                    ),
                                  )
                                : const Text(
                                    'Send Reset Link',
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
                ],
              ],
            ),
          ),
          ),
        ),
      ),
    );
  }
}
