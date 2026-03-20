import 'package:flutter/material.dart';
import 'package:ummaly/features/pillars/pillar_content_service.dart';
import 'package:ummaly/features/pillars/widgets/daily_cards.dart';

class ZakatTab extends StatelessWidget {
  const ZakatTab({super.key});

  static const _accent = Color(0xFF2E7D32);
  static const _darkBg = Color(0xFF0F1A2E);

  @override
  Widget build(BuildContext context) {
    final svc = PillarContentService.instance;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
      child: Column(
        children: [
          // ── Dynamic daily content ──
          DailyWisdomCard(accent: _accent),
          const SizedBox(height: 16),
          DidYouKnowCard(accent: _accent, fact: svc.zakatFact()),
          const SizedBox(height: 16),
          DailyReflectionCard(accent: _accent, prompt: svc.zakatReflection()),
          const SizedBox(height: 24),

          // Header card
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: _darkBg.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _accent.withValues(alpha: 0.3),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              children: [
                Icon(
                  Icons.volunteer_activism,
                  size: 56,
                  color: _accent,
                ),
                const SizedBox(height: 16),
                Text(
                  'الزكاة',
                  style: TextStyle(
                    color: _accent,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'ZAKAT',
                  style: TextStyle(
                    color: _accent.withValues(alpha: 0.7),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Obligatory Charitable Giving',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 14,
                    fontWeight: FontWeight.w300,
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _accent.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _accent.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Text(
                    '"Take from their wealth a charity by which you purify '
                    'them and cause them increase."\n— Quran 9:103',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                      height: 1.6,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // About Zakat
          _buildInfoCard(
            title: 'What is Zakat?',
            body:
                'Zakat is the third pillar of Islam. It is an obligatory act of '
                'worship that requires every eligible Muslim to donate a portion '
                'of their wealth (typically 2.5% of savings) to those in need.\n\n'
                'Zakat purifies the soul from greed and attachment to material '
                'possessions, while helping to reduce inequality and support '
                'the most vulnerable in society.',
          ),
          const SizedBox(height: 16),

          // Zakat calculator placeholder
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: _darkBg.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _accent.withValues(alpha: 0.15),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Icon(
                  Icons.calculate_outlined,
                  size: 40,
                  color: _accent,
                ),
                const SizedBox(height: 12),
                Text(
                  'Zakat Calculator',
                  style: TextStyle(
                    color: _accent,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Calculate your Zakat obligation based on your savings, '
                  'gold, silver, investments, and other assets.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                  decoration: BoxDecoration(
                    color: _accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: _accent.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    'Coming Soon',
                    style: TextStyle(
                      color: _accent,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Donation causes header
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Donate to a Cause',
              style: TextStyle(
                color: _accent,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Gaza donation card
          _buildDonationCard(
            title: 'Donate to Gaza',
            subtitle: 'Emergency humanitarian relief',
            description:
                'Support families in Gaza with food, medicine, shelter, '
                'and essential supplies during this time of great need.',
            icon: Icons.favorite,
          ),
          const SizedBox(height: 12),

          // Sudan donation card
          _buildDonationCard(
            title: 'Donate to Sudan',
            subtitle: 'Crisis relief and recovery',
            description:
                'Help displaced Sudanese families with clean water, food, '
                'medical care, and temporary shelter.',
            icon: Icons.handshake,
          ),
          const SizedBox(height: 12),

          // General sadaqah card
          _buildDonationCard(
            title: 'Sadaqah Jariyah',
            subtitle: 'Ongoing charitable giving',
            description:
                'Contribute to projects that provide lasting benefit: wells, '
                'schools, mosques, and orphan sponsorship.',
            icon: Icons.water_drop,
          ),
          const SizedBox(height: 24),

          // Nisab info
          _buildInfoCard(
            title: 'Understanding Nisab',
            body:
                'Nisab is the minimum threshold of wealth a Muslim must possess '
                'before Zakat becomes obligatory. It is calculated based on the '
                'current value of:\n\n'
                '- Gold: 87.48 grams (approximately 3 ounces)\n'
                '- Silver: 612.36 grams (approximately 21 ounces)\n\n'
                'If your total savings and qualifying assets exceed the Nisab '
                'threshold for a full lunar year, you are required to pay 2.5% '
                'of that wealth as Zakat.',
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({required String title, required String body}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _darkBg.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _accent.withValues(alpha: 0.15),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: _accent,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            body,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.75),
              fontSize: 14,
              height: 1.65,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDonationCard({
    required String title,
    required String subtitle,
    required String description,
    required IconData icon,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _darkBg.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _accent.withValues(alpha: 0.15),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _accent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color: _accent,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: _accent,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.55),
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: _accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _accent.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Text(
                    'Coming Soon',
                    style: TextStyle(
                      color: _accent,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
