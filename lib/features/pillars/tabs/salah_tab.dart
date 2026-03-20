import 'package:flutter/material.dart';
import 'package:ummaly/features/pillars/pillar_content_service.dart';
import 'package:ummaly/features/pillars/widgets/daily_cards.dart';

class SalahTab extends StatelessWidget {
  const SalahTab({super.key});

  static const _accent = Color(0xFF0D7377);
  static const _darkBg = Color(0xFF0F1A2E);

  @override
  Widget build(BuildContext context) {
    final svc = PillarContentService.instance;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
      child: Column(
        children: [
          // ── Dynamic daily content ──
          DailyHadithCard(accent: _accent),
          const SizedBox(height: 16),
          DidYouKnowCard(accent: _accent, fact: svc.salahFact()),
          const SizedBox(height: 16),
          DailyReflectionCard(accent: _accent, prompt: svc.salahReflection()),
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
                  Icons.access_time_rounded,
                  size: 56,
                  color: _accent,
                ),
                const SizedBox(height: 16),
                Text(
                  'الصلاة',
                  style: TextStyle(
                    color: _accent,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'SALAH',
                  style: TextStyle(
                    color: _accent.withValues(alpha: 0.7),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'The Five Daily Prayers',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 14,
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Prayer times list
          _buildPrayerTimeCard(
            name: 'Fajr',
            arabic: 'الفجر',
            time: '05:42 AM',
            description: 'Dawn prayer — before sunrise',
            iconData: Icons.wb_twilight,
          ),
          const SizedBox(height: 12),
          _buildPrayerTimeCard(
            name: 'Dhuhr',
            arabic: 'الظهر',
            time: '12:15 PM',
            description: 'Midday prayer — after the sun passes its zenith',
            iconData: Icons.wb_sunny,
          ),
          const SizedBox(height: 12),
          _buildPrayerTimeCard(
            name: 'Asr',
            arabic: 'العصر',
            time: '03:38 PM',
            description: 'Afternoon prayer — late part of the afternoon',
            iconData: Icons.wb_sunny_outlined,
          ),
          const SizedBox(height: 12),
          _buildPrayerTimeCard(
            name: 'Maghrib',
            arabic: 'المغرب',
            time: '06:12 PM',
            description: 'Sunset prayer — just after the sun sets',
            iconData: Icons.wb_twilight_outlined,
          ),
          const SizedBox(height: 12),
          _buildPrayerTimeCard(
            name: 'Isha',
            arabic: 'العشاء',
            time: '07:45 PM',
            description: 'Night prayer — after twilight disappears',
            iconData: Icons.nightlight_round,
          ),
          const SizedBox(height: 24),

          // API notice
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: _accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _accent.withValues(alpha: 0.2),
              ),
            ),
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: _accent,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Prayer times shown are placeholders. Location-based prayer time API coming soon.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // About Salah
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'About Salah',
                  style: TextStyle(
                    color: _accent,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Salah is the second pillar of Islam and the most important act of '
                  'worship performed by Muslims. It is obligatory for every adult '
                  'Muslim to perform five prayers daily.\n\n'
                  'The Prophet Muhammad (peace be upon him) said: "The first matter '
                  'that the slave will be brought to account for on the Day of '
                  'Judgement is the prayer. If it is sound, then the rest of his '
                  'deeds will be sound. And if it is bad, then the rest of his '
                  'deeds will be bad."',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.75),
                    fontSize: 14,
                    height: 1.65,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrayerTimeCard({
    required String name,
    required String arabic,
    required String time,
    required String description,
    required IconData iconData,
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _accent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              iconData,
              color: _accent,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      arabic,
                      style: TextStyle(
                        color: _accent.withValues(alpha: 0.7),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: TextStyle(
              color: _accent,
              fontSize: 15,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
