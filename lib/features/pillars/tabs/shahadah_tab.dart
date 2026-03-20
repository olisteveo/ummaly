import 'package:flutter/material.dart';
import 'package:ummaly/features/pillars/pillar_content_service.dart';
import 'package:ummaly/features/pillars/widgets/daily_cards.dart';

class ShahadahTab extends StatelessWidget {
  const ShahadahTab({super.key});

  static const _accent = Color(0xFFD4A574);
  static const _darkBg = Color(0xFF0F1A2E);

  @override
  Widget build(BuildContext context) {
    final svc = PillarContentService.instance;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
      child: Column(
        children: [
          // ── Dynamic daily content ──
          DailyVerseCard(accent: _accent),
          const SizedBox(height: 16),
          DidYouKnowCard(accent: _accent, fact: svc.shahadahFact()),
          const SizedBox(height: 16),
          DailyReflectionCard(accent: _accent, prompt: svc.shahadahReflection()),
          const SizedBox(height: 24),

          // Main Shahadah card
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
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
            child: Column(
              children: [
                Icon(
                  Icons.brightness_7,
                  size: 56,
                  color: _accent,
                ),
                const SizedBox(height: 20),
                Text(
                  'الشهادة',
                  style: TextStyle(
                    color: _accent,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'SHAHADAH',
                  style: TextStyle(
                    color: _accent.withValues(alpha: 0.7),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'The Declaration of Faith',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 14,
                    fontWeight: FontWeight.w300,
                  ),
                ),
                const SizedBox(height: 32),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: _accent.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _accent.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'لَا إِلٰهَ إِلَّا ٱللّٰهُ مُحَمَّدٌ رَسُولُ ٱللّٰهِ',
                        textAlign: TextAlign.center,
                        textDirection: TextDirection.rtl,
                        style: TextStyle(
                          color: _accent,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          height: 1.8,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        width: 60,
                        height: 1,
                        color: _accent.withValues(alpha: 0.3),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'La ilaha illallah,\nMuhammadur Rasulullah',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          fontStyle: FontStyle.italic,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '"There is no god but Allah,\nand Muhammad is the Messenger of Allah"',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Significance card
          _buildInfoCard(
            title: 'The First Pillar',
            body:
                'The Shahadah is the most fundamental expression of Islamic beliefs. '
                'It is the first of the Five Pillars of Islam and encapsulates the '
                'essence of the entire faith in a single declaration.\n\n'
                'By reciting the Shahadah with sincere conviction, a person enters '
                'the fold of Islam. It affirms the oneness of God (Tawhid) and '
                'accepts Prophet Muhammad (peace be upon him) as His final messenger.',
          ),
          const SizedBox(height: 16),

          // Two parts card
          _buildInfoCard(
            title: 'Two Testimonies',
            body:
                'The Shahadah consists of two declarations:\n\n'
                '1. La ilaha illallah — There is no deity worthy of worship except '
                'Allah. This is the affirmation of monotheism (Tawhid).\n\n'
                '2. Muhammadur Rasulullah — Muhammad is the Messenger of Allah. '
                'This is the acceptance of prophethood and the teachings brought '
                'by the Prophet Muhammad (peace be upon him).',
          ),
          const SizedBox(height: 16),

          // When is it recited
          _buildInfoCard(
            title: 'When is it Recited?',
            body:
                'The Shahadah is recited throughout a Muslim\'s life:\n\n'
                '- As the first words whispered to a newborn baby\n'
                '- During the call to prayer (Adhan) five times daily\n'
                '- Upon embracing Islam as a new Muslim\n'
                '- During the daily prayers (Salah)\n'
                '- As the last words a Muslim hopes to utter before passing',
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
}
