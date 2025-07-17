import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

  // Method to handle password change
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

      // Re-authenticate the user
      await user.reauthenticateWithCredential(cred);

      // Update password
      await user.updatePassword(newPasswordController.text.trim());

      // Clear all fields
      currentPasswordController.clear();
      newPasswordController.clear();
      confirmPasswordController.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password changed successfully')),
        );
      }
    } catch (_) {
      // Show red banner if any error occurs
      setState(() {
        errorBanner = 'Password reset failed';
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
        title: const Text('Change Password'),
        bottom: errorBanner != null
            ? PreferredSize(
          preferredSize: const Size.fromHeight(40),
          child: Container(
            color: Colors.red,
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            child: Text(
              errorBanner!,
              style: const TextStyle(color: Colors.white),
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
              // Current password
              TextFormField(
                controller: currentPasswordController,
                obscureText: !showCurrent,
                decoration: InputDecoration(
                  labelText: 'Current Password',
                  suffixIcon: IconButton(
                    icon: Icon(showCurrent ? Icons.visibility_off : Icons.visibility),
                    onPressed: () {
                      setState(() {
                        showCurrent = !showCurrent;
                      });
                    },
                  ),
                ),
                validator: (value) =>
                value == null || value.isEmpty ? 'Enter current password' : null,
              ),
              const SizedBox(height: 16),

              // New password
              TextFormField(
                controller: newPasswordController,
                obscureText: !showNew,
                decoration: InputDecoration(
                  labelText: 'New Password',
                  suffixIcon: IconButton(
                    icon: Icon(showNew ? Icons.visibility_off : Icons.visibility),
                    onPressed: () {
                      setState(() {
                        showNew = !showNew;
                      });
                    },
                  ),
                ),
                validator: (value) {
                  if (value == null || value.length < 6) {
                    return 'New password must be at least 6 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Confirm new password
              TextFormField(
                controller: confirmPasswordController,
                obscureText: !showConfirm,
                decoration: InputDecoration(
                  labelText: 'Confirm New Password',
                  suffixIcon: IconButton(
                    icon: Icon(showConfirm ? Icons.visibility_off : Icons.visibility),
                    onPressed: () {
                      setState(() {
                        showConfirm = !showConfirm;
                      });
                    },
                  ),
                ),
                validator: (value) {
                  if (value != newPasswordController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                onPressed: changePassword,
                child: const Text('Update Password'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
