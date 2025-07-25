import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:ummaly/theme/styles.dart'; // Import the shared styles file for colors, text, and buttons

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController currentPasswordController = TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  bool isLoading = false;
  bool showCurrent = false;
  bool showNew = false;
  bool showConfirm = false;
  String? errorBanner;

  Future<void> changePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      isLoading = true;
      errorBanner = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw FirebaseAuthException(code: 'no-user', message: 'No user logged in');

      final cred = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPasswordController.text.trim(),
      );

      await user.reauthenticateWithCredential(cred);
      await user.updatePassword(newPasswordController.text.trim());

      currentPasswordController.clear();
      newPasswordController.clear();
      confirmPasswordController.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('password_changed_success'.tr())),
        );
      }
    } catch (_) {
      setState(() {
        errorBanner = 'password_change_failed'.tr();
      });
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('change_password'.tr()),
        bottom: errorBanner != null
            ? PreferredSize(
          preferredSize: const Size.fromHeight(40),
          child: Container(
            color: AppColors.error, // replaced inline Colors.red
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            child: Text(
              errorBanner!,
              style: AppTextStyles.button.copyWith(color: AppColors.white),
              // replaced inline TextStyle(color: Colors.white)
              // using the shared button style and forcing white color
              textAlign: TextAlign.center,
            ),
          ),
        )
            : null,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Current password field
              TextFormField(
                controller: currentPasswordController,
                obscureText: !showCurrent,
                decoration: InputDecoration(
                  labelText: 'current_password'.tr(),
                  suffixIcon: IconButton(
                    icon: Icon(showCurrent ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => showCurrent = !showCurrent),
                  ),
                ),
                validator: (value) =>
                value == null || value.isEmpty ? 'enter_current_password'.tr() : null,
              ),
              const SizedBox(height: 16),

              // New password field
              TextFormField(
                controller: newPasswordController,
                obscureText: !showNew,
                decoration: InputDecoration(
                  labelText: 'new_password'.tr(),
                  suffixIcon: IconButton(
                    icon: Icon(showNew ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => showNew = !showNew),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.length < 6) {
                    return 'password_min_length'.tr();
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Confirm new password field
              TextFormField(
                controller: confirmPasswordController,
                obscureText: !showConfirm,
                decoration: InputDecoration(
                  labelText: 'confirm_new_password'.tr(),
                  suffixIcon: IconButton(
                    icon: Icon(showConfirm ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => showConfirm = !showConfirm),
                  ),
                ),
                validator: (value) {
                  if (value != newPasswordController.text) {
                    return 'passwords_do_not_match'.tr();
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Update password button with shared button style
              isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                style: AppButtons.primaryButton,
                onPressed: changePassword,
                child: Text('update_password'.tr()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
