import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart' hide Trans;
import 'package:easy_localization/easy_localization.dart';
import 'package:ummaly/theme/styles.dart';
import 'package:ummaly/theme/islamic_patterns.dart';
import 'package:ummaly/theme/animated_logo.dart';
import 'package:ummaly/features/account/account_settings_screen.dart';
import 'package:ummaly/features/account/change_password_screen.dart';
import 'package:ummaly/features/scanner/scan_history_screen.dart';
import 'package:ummaly/features/auth/login_screen.dart';
import 'package:ummaly/features/auth/register_screen.dart';
import 'package:ummaly/core/locale/locale_manager.dart';

class ProfileScreen extends StatefulWidget {
  final bool isGuest;
  const ProfileScreen({super.key, this.isGuest = false});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _userName = '';
  String _userEmail = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    if (widget.isGuest) {
      setState(() => _isLoading = false);
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }

    _userEmail = user.email ?? '';

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      _userName = doc.data()?['name'] ?? '';
    } catch (_) {
      _userName = user.displayName ?? '';
    }

    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: IslamicPatternBackground(
        color: AppColors.primary.withOpacity(0.03),
        child: SafeArea(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                )
              : widget.isGuest
                  ? _buildGuestProfile()
                  : _buildAuthenticatedProfile(),
        ),
      ),
    );
  }

  // ============================================================
  // GUEST PROFILE
  // ============================================================
  Widget _buildGuestProfile() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
      child: Column(
        children: [
          const SizedBox(height: 20),

          // Guest avatar
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withOpacity(0.1),
              border: Border.all(
                color: AppColors.primary.withOpacity(0.2),
                width: 2,
              ),
            ),
            child: const Icon(
              Icons.person_outline_rounded,
              color: AppColors.primary,
              size: 44,
            ),
          ),
          const SizedBox(height: 20),

          Text(
            'Guest User',
            style: AppTextStyles.heading.copyWith(fontSize: 24),
          ),
          const SizedBox(height: 8),
          Text(
            'Create an account to unlock all features',
            style: AppTextStyles.body.copyWith(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 32),

          // Create Account CTA
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0F1A2E), Color(0xFF1A2B45)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0F1A2E).withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                const UmmalyLogo(size: 48, color: AppColors.gold),
                const SizedBox(height: 16),
                const Text(
                  'Join the Ummaly Community',
                  style: TextStyle(
                    color: AppColors.gold,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Get unlimited barcode scans, save your scan history, and personalise your experience.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.cream.withOpacity(0.75),
                    fontSize: 14,
                    height: 1.5,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 24),

                // Create Account button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: AppButtons.goldButton,
                    onPressed: () => Get.off(() => const RegisterScreen()),
                    child: const Text(
                      'Create Account',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Sign In link
                GestureDetector(
                  onTap: () => Get.off(() => const LoginScreen()),
                  child: RichText(
                    text: TextSpan(
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        color: AppColors.cream.withOpacity(0.6),
                      ),
                      children: const [
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
              ],
            ),
          ),
          const SizedBox(height: 24),

          // What guests can do
          _buildSectionLabel('WHAT YOU CAN DO'),
          const SizedBox(height: 8),
          _buildMenuCard([
            _MenuItem(
              icon: Icons.qr_code_scanner_rounded,
              label: '5 Free Barcode Scans',
              subtitle: 'Create an account for unlimited',
              onTap: () {},
            ),
            _MenuItem(
              icon: Icons.restaurant_rounded,
              label: 'Restaurant Search',
              subtitle: 'Full access as a guest',
              onTap: () {},
            ),
            _MenuItem(
              icon: Icons.auto_awesome,
              label: 'Five Pillars of Islam',
              subtitle: 'Full access as a guest',
              onTap: () {},
            ),
          ]),

          const SizedBox(height: 24),
          _buildSectionLabel('APP'),
          const SizedBox(height: 8),
          _buildMenuCard([
            _MenuItem(
              icon: Icons.info_outline,
              label: 'About Ummaly',
              onTap: () => _showAbout(),
            ),
          ]),

          const SizedBox(height: 16),
          Text(
            'Ummaly v1.0.0',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // AUTHENTICATED PROFILE
  // ============================================================
  Widget _buildAuthenticatedProfile() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
      child: Column(
        children: [
          // Profile header
          _buildProfileHeader(),
          const SizedBox(height: 32),

          // Menu sections
          _buildSectionLabel('ACCOUNT'),
          const SizedBox(height: 8),
          _buildMenuCard([
            _MenuItem(
              icon: Icons.person_outline,
              label: 'Account Settings',
              onTap: () async {
                await Get.to(() => const AccountSettingsScreen());
                _loadProfile(); // refresh on return
              },
            ),
            _MenuItem(
              icon: Icons.lock_outline,
              label: 'Change Password',
              onTap: () => Get.to(() => const ChangePasswordScreen()),
            ),
          ]),

          const SizedBox(height: 24),
          _buildSectionLabel('ACTIVITY'),
          const SizedBox(height: 8),
          _buildMenuCard([
            _MenuItem(
              icon: Icons.history_rounded,
              label: 'Scan History',
              onTap: () {
                final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
                if (uid.isNotEmpty) {
                  Get.to(() => ScanHistoryScreen(firebaseUid: uid));
                }
              },
            ),
          ]),

          const SizedBox(height: 24),
          _buildSectionLabel('APP'),
          const SizedBox(height: 8),
          _buildMenuCard([
            _MenuItem(
              icon: Icons.info_outline,
              label: 'About Ummaly',
              onTap: () => _showAbout(),
            ),
          ]),

          const SizedBox(height: 32),

          // Logout button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                side: BorderSide(
                  color: AppColors.error.withOpacity(0.3),
                ),
              ),
              onPressed: _handleLogout,
              icon: const Icon(Icons.logout_rounded, size: 20),
              label: const Text(
                'Sign Out',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Version
          Text(
            'Ummaly v1.0.0',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    final initials = _userName.isNotEmpty
        ? _userName.split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(2).join().toUpperCase()
        : '?';

    return Column(
      children: [
        // Avatar
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppGradients.emeraldGold,
          ),
          child: Center(
            child: Text(
              initials,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w700,
                fontFamily: 'Poppins',
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Name
        Text(
          _userName.isNotEmpty ? _userName : 'User',
          style: AppTextStyles.heading.copyWith(fontSize: 22),
        ),
        const SizedBox(height: 4),

        // Email
        Text(
          _userEmail,
          style: AppTextStyles.caption.copyWith(
            color: AppColors.textSecondary,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionLabel(String label) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        label,
        style: AppTextStyles.label.copyWith(
          color: AppColors.textSecondary,
          letterSpacing: 2,
        ),
      ),
    );
  }

  Widget _buildMenuCard(List<_MenuItem> items) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          for (int i = 0; i < items.length; i++) ...[
            _buildMenuItem(items[i]),
            if (i < items.length - 1)
              Divider(
                height: 1,
                indent: 56,
                color: AppColors.divider,
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildMenuItem(_MenuItem item) {
    return InkWell(
      onTap: item.onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(item.icon, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.label,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  if (item.subtitle != null)
                    Text(
                      item.subtitle!,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary.withOpacity(0.7),
                        fontFamily: 'Poppins',
                      ),
                    ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textSecondary.withOpacity(0.4),
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  void _showAbout() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            UmmalyLogo(size: 32, color: AppColors.gold),
            const SizedBox(width: 12),
            const Text('Ummaly', style: TextStyle(fontFamily: 'Playfair Display')),
          ],
        ),
        content: const Text(
          'Your companion for halal living. Scan products, find halal restaurants, '
          'and explore the Five Pillars of Islam.\n\n'
          'Built with love for the Ummah.',
          style: TextStyle(fontFamily: 'Poppins', height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Sign Out', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await FirebaseAuth.instance.signOut();
      LocaleManager().resetToDeviceLocale();
      Get.offAll(() => const LoginScreen());
    } catch (_) {
      Get.snackbar('Error', 'Failed to sign out. Please try again.',
          backgroundColor: AppColors.error, colorText: Colors.white);
    }
  }
}

class _MenuItem {
  final IconData icon;
  final String label;
  final String? subtitle;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.label,
    this.subtitle,
    required this.onTap,
  });
}
