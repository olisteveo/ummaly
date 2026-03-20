import 'package:flutter/material.dart';
import 'package:ummaly/features/pillars/pillar_content_service.dart';
import 'package:ummaly/features/pillars/widgets/daily_cards.dart';

class SawmTab extends StatelessWidget {
  const SawmTab({super.key});

  static const _accent = Color(0xFFE65100);
  static const _darkBg = Color(0xFF0F1A2E);

  @override
  Widget build(BuildContext context) {
    final svc = PillarContentService.instance;
    final ramadan = svc.ramadanCountdown();
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
      child: Column(
        children: [
          // ── Ramadan countdown ──
          CountdownCard(
            accent: _accent,
            icon: Icons.calendar_month,
            title: 'Ramadan',
            label: ramadan.label,
            value: ramadan.days,
            isActive: ramadan.isActive,
          ),
          const SizedBox(height: 16),
          DidYouKnowCard(accent: _accent, fact: svc.sawmFact()),
          const SizedBox(height: 16),
          DailyReflectionCard(accent: _accent, prompt: svc.sawmReflection()),
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
                  Icons.restaurant_menu,
                  size: 56,
                  color: _accent,
                ),
                const SizedBox(height: 16),
                Text(
                  'الصوم',
                  style: TextStyle(
                    color: _accent,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'SAWM',
                  style: TextStyle(
                    color: _accent.withValues(alpha: 0.7),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Fasting During Ramadan',
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
                    '"O you who believe! Fasting is prescribed for you as it '
                    'was prescribed for those before you, that you may attain '
                    'Taqwa (God-consciousness)."\n— Quran 2:183',
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

          // Suhoor & Iftar times
          Row(
            children: [
              Expanded(
                child: _buildMealTimeCard(
                  title: 'Suhoor',
                  arabic: 'السحور',
                  time: '04:30 AM',
                  description: 'Pre-dawn meal',
                  icon: Icons.dark_mode,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMealTimeCard(
                  title: 'Iftar',
                  arabic: 'الإفطار',
                  time: '06:15 PM',
                  description: 'Meal at sunset',
                  icon: Icons.wb_sunny,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: _accent.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _accent.withValues(alpha: 0.15),
              ),
            ),
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: _accent, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Times shown are placeholders. Location-based Suhoor and Iftar times coming soon.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.55),
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Fasting tips
          _buildInfoCard(
            title: 'Fasting Tips',
            body: null,
            child: Column(
              children: [
                _buildTipRow(
                  icon: Icons.water_drop,
                  tip: 'Stay well hydrated between Iftar and Suhoor. Drink plenty of water and avoid caffeinated drinks.',
                ),
                const SizedBox(height: 14),
                _buildTipRow(
                  icon: Icons.rice_bowl,
                  tip: 'Eat a balanced Suhoor with complex carbs, protein, and healthy fats for sustained energy.',
                ),
                const SizedBox(height: 14),
                _buildTipRow(
                  icon: Icons.favorite_border,
                  tip: 'Break your fast with dates and water, following the Sunnah of the Prophet (peace be upon him).',
                ),
                const SizedBox(height: 14),
                _buildTipRow(
                  icon: Icons.menu_book,
                  tip: 'Increase Quran recitation and dhikr during Ramadan, especially in the last ten nights.',
                ),
                const SizedBox(height: 14),
                _buildTipRow(
                  icon: Icons.bedtime,
                  tip: 'Maintain a healthy sleep schedule. Try to rest after Dhuhr if possible during long fasting days.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // About Sawm
          _buildInfoCard(
            title: 'The Virtues of Fasting',
            body:
                'Fasting during Ramadan is the fourth pillar of Islam. Muslims '
                'abstain from food, drink, and other physical needs from dawn '
                'until sunset during the entire month.\n\n'
                'The Prophet Muhammad (peace be upon him) said: "When Ramadan '
                'begins, the gates of Paradise are opened, the gates of Hell '
                'are closed, and the devils are chained."\n\n'
                'Fasting teaches self-discipline, self-control, sacrifice, and '
                'empathy for those who are less fortunate. It is a time of '
                'spiritual reflection, increased devotion, and worship.',
          ),
        ],
      ),
    );
  }

  Widget _buildMealTimeCard({
    required String title,
    required String arabic,
    required String time,
    required String description,
    required IconData icon,
  }) {
    return Container(
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
      child: Column(
        children: [
          Icon(icon, color: _accent, size: 28),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            arabic,
            style: TextStyle(
              color: _accent.withValues(alpha: 0.7),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            time,
            style: TextStyle(
              color: _accent,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipRow({required IconData icon, required String tip}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: _accent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: _accent, size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            tip,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard({
    required String title,
    String? body,
    Widget? child,
  }) {
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
          if (body != null)
            Text(
              body,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.75),
                fontSize: 14,
                height: 1.65,
              ),
            ),
          if (child != null) child,
        ],
      ),
    );
  }
}
