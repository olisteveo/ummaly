import 'package:flutter/material.dart';
import 'package:ummaly/features/pillars/pillar_content_service.dart';
import 'package:ummaly/features/pillars/widgets/daily_cards.dart';

class HajjTab extends StatelessWidget {
  const HajjTab({super.key});

  static const _accent = Color(0xFF4A148C);
  static const _accentLight = Color(0xFF7C43BD);
  static const _darkBg = Color(0xFF0F1A2E);

  @override
  Widget build(BuildContext context) {
    final svc = PillarContentService.instance;
    final hajj = svc.hajjCountdown();
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
      child: Column(
        children: [
          // ── Hajj countdown ──
          CountdownCard(
            accent: _accentLight,
            icon: Icons.mosque,
            title: 'Hajj',
            label: hajj.label,
            value: hajj.days,
            isActive: hajj.isActive,
          ),
          const SizedBox(height: 16),
          DidYouKnowCard(accent: _accentLight, fact: svc.hajjFact()),
          const SizedBox(height: 16),
          DailyReflectionCard(accent: _accentLight, prompt: svc.hajjReflection()),
          const SizedBox(height: 24),

          // Header card
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: _darkBg.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _accent.withValues(alpha: 0.4),
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
                  Icons.mosque,
                  size: 56,
                  color: _accentLight,
                ),
                const SizedBox(height: 16),
                Text(
                  'الحج',
                  style: TextStyle(
                    color: _accentLight,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'HAJJ',
                  style: TextStyle(
                    color: _accentLight.withValues(alpha: 0.7),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'The Pilgrimage to Mecca',
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

          // Quranic verse 1
          _buildQuoteCard(
            arabic: 'وَلِلَّهِ عَلَى النَّاسِ حِجُّ الْبَيْتِ مَنِ اسْتَطَاعَ إِلَيْهِ سَبِيلًا',
            translation:
                '"And pilgrimage to the House is a duty owed to Allah by '
                'all people who are able to undertake it."',
            reference: 'Quran 3:97',
          ),
          const SizedBox(height: 16),

          // Quranic verse 2
          _buildQuoteCard(
            arabic: 'وَأَذِّن فِي النَّاسِ بِالْحَجِّ يَأْتُوكَ رِجَالًا وَعَلَىٰ كُلِّ ضَامِرٍ يَأْتِينَ مِن كُلِّ فَجٍّ عَمِيقٍ',
            translation:
                '"And proclaim to the people the Hajj; they will come to '
                'you on foot and on every lean camel; they will come from '
                'every distant pass."',
            reference: 'Quran 22:27',
          ),
          const SizedBox(height: 16),

          // Hadith
          _buildQuoteCard(
            arabic: null,
            translation:
                '"Whoever performs Hajj for the sake of Allah and does not '
                'utter any obscene speech or do any evil deed, will go back '
                '(free of sin) as his mother bore him."',
            reference: 'Sahih al-Bukhari',
          ),
          const SizedBox(height: 24),

          // About Hajj
          _buildInfoCard(
            title: 'The Fifth Pillar',
            body:
                'Hajj is the annual Islamic pilgrimage to Mecca, Saudi Arabia, '
                'the holiest city for Muslims. It is a mandatory religious duty '
                'that must be carried out at least once in a lifetime by every '
                'able-bodied Muslim who can afford to do so.\n\n'
                'Hajj occurs during the Islamic month of Dhul Hijjah (the 12th '
                'month of the Islamic calendar). Each year, millions of Muslims '
                'from around the world gather in Mecca to perform the rites of '
                'Hajj, making it one of the largest annual gatherings of people '
                'in the world.',
          ),
          const SizedBox(height: 16),

          // Hajj guide placeholder
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: _darkBg.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _accent.withValues(alpha: 0.2),
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
                  'Hajj Guide',
                  style: TextStyle(
                    color: _accentLight,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                _buildStepRow(
                  step: '1',
                  title: 'Ihram',
                  description:
                      'Enter the state of sacred purity and don the white garments.',
                ),
                const SizedBox(height: 14),
                _buildStepRow(
                  step: '2',
                  title: 'Tawaf',
                  description:
                      'Circumambulate the Kaaba seven times in a counter-clockwise direction.',
                ),
                const SizedBox(height: 14),
                _buildStepRow(
                  step: '3',
                  title: "Sa'i",
                  description:
                      'Walk seven times between the hills of Safa and Marwah.',
                ),
                const SizedBox(height: 14),
                _buildStepRow(
                  step: '4',
                  title: 'Day of Arafah',
                  description:
                      'Stand in supplication on the plains of Arafah from noon to sunset.',
                ),
                const SizedBox(height: 14),
                _buildStepRow(
                  step: '5',
                  title: 'Muzdalifah',
                  description:
                      'Spend the night under the open sky and collect pebbles.',
                ),
                const SizedBox(height: 14),
                _buildStepRow(
                  step: '6',
                  title: 'Rami al-Jamarat',
                  description:
                      'Stone the three pillars representing Shaytan over the days of Eid.',
                ),
                const SizedBox(height: 14),
                _buildStepRow(
                  step: '7',
                  title: 'Sacrifice & Shaving',
                  description:
                      'Offer an animal sacrifice (Qurbani) and shave or trim the hair.',
                ),
                const SizedBox(height: 14),
                _buildStepRow(
                  step: '8',
                  title: 'Farewell Tawaf',
                  description:
                      'Perform a final circumambulation of the Kaaba before departing Mecca.',
                ),
                const SizedBox(height: 20),
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 10),
                    decoration: BoxDecoration(
                      color: _accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: _accent.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      'Detailed Guide Coming Soon',
                      style: TextStyle(
                        color: _accentLight,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // More quotes
          _buildInfoCard(
            title: 'Reflections on Hajj',
            body:
                'The Prophet Muhammad (peace be upon him) said during his '
                'Farewell Sermon at Hajj:\n\n'
                '"All mankind is from Adam and Eve. An Arab has no superiority '
                'over a non-Arab, nor does a non-Arab have any superiority over '
                'an Arab; a white has no superiority over a black, nor does a '
                'black have any superiority over a white — except by piety and '
                'good action."\n\n'
                'Hajj embodies the equality of all believers before Allah. '
                'Regardless of wealth, status, or nationality, every pilgrim '
                'wears the same simple white garments and performs the same '
                'rites, standing shoulder to shoulder in devotion.',
          ),
        ],
      ),
    );
  }

  Widget _buildQuoteCard({
    String? arabic,
    required String translation,
    required String reference,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _darkBg.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _accent.withValues(alpha: 0.2),
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
            Icons.format_quote,
            color: _accentLight.withValues(alpha: 0.4),
            size: 28,
          ),
          if (arabic != null) ...[
            const SizedBox(height: 12),
            Text(
              arabic,
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
              style: TextStyle(
                color: _accentLight,
                fontSize: 20,
                fontWeight: FontWeight.w600,
                height: 1.8,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: 40,
              height: 1,
              color: _accent.withValues(alpha: 0.3),
            ),
          ],
          const SizedBox(height: 12),
          Text(
            translation,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 14,
              fontStyle: FontStyle.italic,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            reference,
            style: TextStyle(
              color: _accentLight.withValues(alpha: 0.6),
              fontSize: 12,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepRow({
    required String step,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: _accent.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(
            step,
            style: TextStyle(
              color: _accentLight,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                description,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.55),
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
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
              color: _accentLight,
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
