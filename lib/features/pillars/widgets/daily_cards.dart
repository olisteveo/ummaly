import 'package:flutter/material.dart';
import 'package:ummaly/features/pillars/pillar_content_service.dart';

/// "Daily Verse" card — shows a rotating Quranic verse.
class DailyVerseCard extends StatelessWidget {
  final Color accent;
  const DailyVerseCard({super.key, required this.accent});

  @override
  Widget build(BuildContext context) {
    final svc = PillarContentService.instance;
    return _GlassCard(
      accent: accent,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.auto_stories, color: accent, size: 18),
              const SizedBox(width: 8),
              Text(
                'VERSE OF THE DAY',
                style: TextStyle(
                  color: accent,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            svc.dailyVerse,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 16,
              fontStyle: FontStyle.italic,
              height: 1.6,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 12),
          Text(
            svc.dailyVerseReference,
            style: TextStyle(
              color: accent.withValues(alpha: 0.7),
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

/// "Daily Hadith" card.
class DailyHadithCard extends StatelessWidget {
  final Color accent;
  const DailyHadithCard({super.key, required this.accent});

  @override
  Widget build(BuildContext context) {
    final svc = PillarContentService.instance;
    return _GlassCard(
      accent: accent,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.format_quote, color: accent, size: 18),
              const SizedBox(width: 8),
              Text(
                'HADITH OF THE DAY',
                style: TextStyle(
                  color: accent,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            svc.dailyHadith,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 15,
              fontStyle: FontStyle.italic,
              height: 1.6,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 12),
          Text(
            svc.dailyHadithSource,
            style: TextStyle(
              color: accent.withValues(alpha: 0.7),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// "Daily Wisdom" proverb card.
class DailyWisdomCard extends StatelessWidget {
  final Color accent;
  const DailyWisdomCard({super.key, required this.accent});

  @override
  Widget build(BuildContext context) {
    final svc = PillarContentService.instance;
    return _GlassCard(
      accent: accent,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lightbulb_outline, color: accent, size: 18),
              const SizedBox(width: 8),
              Text(
                'DAILY WISDOM',
                style: TextStyle(
                  color: accent,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            svc.dailyProverb,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 17,
              fontWeight: FontWeight.w500,
              height: 1.5,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '— ${svc.dailyProverbOrigin}',
            style: TextStyle(
              color: accent.withValues(alpha: 0.7),
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

/// "Did You Know?" fact card.
class DidYouKnowCard extends StatelessWidget {
  final Color accent;
  final String fact;
  const DidYouKnowCard({super.key, required this.accent, required this.fact});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withValues(alpha: 0.2)),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.tips_and_updates, color: accent, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Did You Know?',
                  style: TextStyle(
                    color: accent,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  fact,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.75),
                    fontSize: 13,
                    height: 1.5,
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

/// "Daily Reflection" prompt card.
class DailyReflectionCard extends StatelessWidget {
  final Color accent;
  final String prompt;
  const DailyReflectionCard({super.key, required this.accent, required this.prompt});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [accent.withValues(alpha: 0.15), accent.withValues(alpha: 0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.25)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.psychology_outlined, color: accent, size: 20),
              const SizedBox(width: 8),
              Text(
                'REFLECT',
                style: TextStyle(
                  color: accent,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            prompt,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 16,
              fontStyle: FontStyle.italic,
              height: 1.5,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }
}

/// Countdown card (Ramadan / Hajj).
class CountdownCard extends StatelessWidget {
  final Color accent;
  final IconData icon;
  final String title;
  final String label;
  final int value;
  final bool isActive;

  const CountdownCard({
    super.key,
    required this.accent,
    required this.icon,
    required this.title,
    required this.label,
    required this.value,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [accent.withValues(alpha: 0.2), accent.withValues(alpha: 0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.3)),
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
          Icon(icon, size: 36, color: accent),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              color: accent,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          if (isActive)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                label,
                style: TextStyle(
                  color: accent,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            )
          else ...[
            Text(
              value.toString(),
              style: TextStyle(
                color: Colors.white,
                fontSize: 48,
                fontWeight: FontWeight.w800,
                height: 1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 14,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Shared glass-morphism card wrapper.
class _GlassCard extends StatelessWidget {
  final Color accent;
  final Widget child;
  const _GlassCard({required this.accent, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF0F1A2E).withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: child,
    );
  }
}
