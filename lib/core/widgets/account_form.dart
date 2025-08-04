import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:ummaly/theme/styles.dart';

class AccountForm extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final String? selectedLanguageCode;
  final ValueChanged<String?> onLanguageChanged;
  final VoidCallback onSave;
  final VoidCallback onDelete;
  final bool isLoading;

  const AccountForm({
    Key? key,
    required this.nameController,
    required this.emailController,
    required this.passwordController,
    required this.selectedLanguageCode,
    required this.onLanguageChanged,
    required this.onSave,
    required this.onDelete,
    required this.isLoading,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Name field
          TextFormField(
            controller: nameController,
            decoration: InputDecoration(labelText: 'name'.tr()),
          ),
          const SizedBox(height: 16),

          // Email field
          TextFormField(
            controller: emailController,
            decoration: InputDecoration(labelText: 'email'.tr()),
          ),
          const SizedBox(height: 16),

          // Language dropdown
          DropdownButtonFormField<String>(
            value: selectedLanguageCode,
            items: [
              {'code': 'en', 'label': 'English'},
              {'code': 'fr', 'label': 'Français'},
              {'code': 'ar', 'label': 'العربية'},
              {'code': 'ur', 'label': 'اردو'},
            ]
                .map(
                  (lang) => DropdownMenuItem(
                value: lang['code'],
                child: Text(lang['label']!),
              ),
            )
                .toList(),
            onChanged: onLanguageChanged,
            decoration: InputDecoration(labelText: 'language'.tr()),
          ),
          const SizedBox(height: 16),

          // Password for reauthentication
          TextFormField(
            controller: passwordController,
            obscureText: true,
            decoration: InputDecoration(labelText: 'password'.tr()),
          ),
          const SizedBox(height: 32),

          // Save button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: AppButtons.primaryButton,
              onPressed: isLoading ? null : onSave,
              child: isLoading
                  ? const CircularProgressIndicator()
                  : Text('update_account'.tr()),
            ),
          ),
          const SizedBox(height: 16),

          // Delete account
          TextButton(
            onPressed: isLoading ? null : onDelete,
            child: Text(
              'delete_account'.tr(),
              style: AppTextStyles.error,
            ),
          ),
        ],
      ),
    );
  }
}
