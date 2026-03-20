import 'package:flutter/material.dart';
import 'package:ummaly/features/home/home_screen.dart';
import 'package:ummaly/features/pillars/pillars_dashboard.dart';
import 'package:ummaly/features/profile/profile_screen.dart';

class AppShell extends StatefulWidget {
  final bool isGuest;
  const AppShell({super.key, this.isGuest = false});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0;

  static const _darkBg = Color(0xFF0F1A2E);
  static const _gold = Color(0xFFD4A574);
  static const _cream = Color(0xFFF5F0E8);

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      HomeScreen(isGuest: widget.isGuest),
      const PillarsDashboard(),
      ProfileScreen(isGuest: widget.isGuest),
    ];
  }

  void _onTabTapped(int index) {
    if (index != _currentIndex) {
      setState(() => _currentIndex = index);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: _darkBg,
        border: Border(
          top: BorderSide(
            color: _gold.withValues(alpha: 0.3),
            width: 0.5,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                index: 0,
                icon: Icons.home_rounded,
                label: 'Home',
              ),
              _buildNavItem(
                index: 1,
                icon: Icons.auto_awesome,
                label: '5 Pillars',
              ),
              _buildNavItem(
                index: 2,
                icon: Icons.person_rounded,
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final bool isActive = _currentIndex == index;
    final Color itemColor = isActive ? _gold : _cream.withValues(alpha: 0.5);
    final double iconSize = isActive ? 28 : 24;

    return GestureDetector(
      onTap: () => _onTabTapped(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: isActive
            ? BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: _gold.withValues(alpha: 0.1),
                boxShadow: [
                  BoxShadow(
                    color: _gold.withValues(alpha: 0.15),
                    blurRadius: 12,
                    spreadRadius: 0,
                  ),
                ],
              )
            : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              child: Icon(
                icon,
                size: iconSize,
                color: itemColor,
              ),
            ),
            const SizedBox(height: 4),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: isActive ? 12 : 11,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                color: itemColor,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}
