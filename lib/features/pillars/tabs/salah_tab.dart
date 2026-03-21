import 'package:flutter/material.dart';
import 'package:ummaly/core/services/prayer_time_service.dart';
import 'package:ummaly/features/pillars/pillar_content_service.dart';
import 'package:ummaly/features/pillars/widgets/daily_cards.dart';

class SalahTab extends StatefulWidget {
  const SalahTab({super.key});

  @override
  State<SalahTab> createState() => _SalahTabState();
}

class _SalahTabState extends State<SalahTab> {
  static const _accent = Color(0xFF0D7377);
  static const _darkBg = Color(0xFF0F1A2E);

  final _prayerService = PrayerTimeService.instance;

  @override
  void initState() {
    super.initState();
    _prayerService.addListener(_onPrayerTimesUpdated);
    _prayerService.fetch();
  }

  @override
  void dispose() {
    _prayerService.removeListener(_onPrayerTimesUpdated);
    super.dispose();
  }

  void _onPrayerTimesUpdated() {
    if (mounted) setState(() {});
  }

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

          // ── Next prayer highlight ──
          if (_prayerService.times.isNotEmpty) ...[
            _buildNextPrayerCard(),
            const SizedBox(height: 20),
          ],

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
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            child: Column(
              children: [
                Icon(
                  Icons.access_time_rounded,
                  size: 48,
                  color: _accent,
                ),
                const SizedBox(height: 12),
                Text(
                  'الصلاة',
                  style: TextStyle(
                    color: _accent,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'PRAYER TIMES',
                  style: TextStyle(
                    color: _accent.withValues(alpha: 0.7),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 4,
                  ),
                ),
                if (_prayerService.locationName.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        color: Colors.white.withValues(alpha: 0.5),
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _prayerService.locationName,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ],
                if (_prayerService.hijriDate.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    _prayerService.hijriDate,
                    style: TextStyle(
                      color: _accent.withValues(alpha: 0.5),
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Prayer times list ──
          if (_prayerService.isLoading && _prayerService.times.isEmpty)
            _buildLoadingState()
          else if (_prayerService.times.isNotEmpty)
            ..._buildPrayerTimesList()
          else
            _buildErrorState(),

          const SizedBox(height: 16),

          // Location info / refresh
          _buildLocationBar(),

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

  /// Highlighted card showing the next upcoming prayer.
  Widget _buildNextPrayerCard() {
    final next = _prayerService.nextPrayer;
    if (next == null) return const SizedBox.shrink();

    final timeUntil = _prayerService.timeUntilNext;
    final isUpcoming = next.name != 'Sunrise'; // Don't highlight sunrise

    if (!isUpcoming) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _accent,
            _accent.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: _accent.withValues(alpha: 0.4),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              _iconForPrayer(next.name),
              color: Colors.white,
              size: 26,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'NEXT PRAYER',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${next.name}  ${next.arabic}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                next.formatted,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (timeUntil.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  'in $timeUntil',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _buildPrayerTimesList() {
    final widgets = <Widget>[];
    for (int i = 0; i < _prayerService.times.length; i++) {
      final prayer = _prayerService.times[i];
      final isNext = _prayerService.nextPrayer?.name == prayer.name;
      final isSunrise = prayer.name == 'Sunrise';

      widgets.add(
        _buildPrayerTimeCard(
          name: prayer.name,
          arabic: prayer.arabic,
          time: prayer.formatted,
          description: prayer.description,
          iconData: _iconForPrayer(prayer.name),
          isNext: isNext,
          hasPassed: prayer.hasPassed,
          isSunrise: isSunrise,
        ),
      );

      if (i < _prayerService.times.length - 1) {
        widgets.add(const SizedBox(height: 10));
      }
    }
    return widgets;
  }

  Widget _buildLoadingState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 60),
      decoration: BoxDecoration(
        color: _darkBg.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: _accent,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Loading prayer times...',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Getting your location',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.3),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _darkBg.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.orange.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.location_off_outlined,
            color: Colors.orange.withValues(alpha: 0.7),
            size: 40,
          ),
          const SizedBox(height: 12),
          Text(
            'Enable location for accurate prayer times',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'We use your location to calculate precise prayer times for your area',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: () => _prayerService.fetch(force: true),
            icon: Icon(Icons.refresh, color: _accent, size: 18),
            label: Text(
              'Try Again',
              style: TextStyle(color: _accent),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationBar() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _accent.withValues(alpha: 0.15),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(
            Icons.mosque_outlined,
            color: _accent.withValues(alpha: 0.7),
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _prayerService.locationName.isNotEmpty
                  ? 'Times for ${_prayerService.locationName} · Muslim World League'
                  : 'Tap refresh to load prayer times for your location',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 12,
              ),
            ),
          ),
          GestureDetector(
            onTap: () => _prayerService.fetch(force: true),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: _accent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.refresh_rounded,
                color: _accent,
                size: 16,
              ),
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
    bool isNext = false,
    bool hasPassed = false,
    bool isSunrise = false,
  }) {
    final opacity = hasPassed ? 0.45 : 1.0;

    return Opacity(
      opacity: isSunrise ? 0.6 : opacity,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: isNext
              ? _accent.withValues(alpha: 0.12)
              : _darkBg.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isNext
                ? _accent.withValues(alpha: 0.4)
                : _accent.withValues(alpha: 0.12),
            width: isNext ? 1.5 : 1,
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
                color: isNext
                    ? _accent.withValues(alpha: 0.25)
                    : _accent.withValues(alpha: 0.12),
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
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isSunrise ? 14 : 16,
                          fontWeight:
                              isNext ? FontWeight.w700 : FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        arabic,
                        style: TextStyle(
                          color: _accent.withValues(alpha: 0.7),
                          fontSize: isSunrise ? 13 : 14,
                        ),
                      ),
                      if (hasPassed && !isSunrise) ...[
                        const SizedBox(width: 8),
                        Icon(
                          Icons.check_circle,
                          color: _accent.withValues(alpha: 0.5),
                          size: 14,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    description,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.45),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              time,
              style: TextStyle(
                color: isNext ? _accent : _accent.withValues(alpha: 0.85),
                fontSize: isSunrise ? 13 : 15,
                fontWeight: isNext ? FontWeight.w800 : FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconForPrayer(String name) {
    switch (name) {
      case 'Fajr':
        return Icons.wb_twilight;
      case 'Sunrise':
        return Icons.wb_sunny_outlined;
      case 'Dhuhr':
        return Icons.wb_sunny;
      case 'Asr':
        return Icons.wb_sunny_outlined;
      case 'Maghrib':
        return Icons.wb_twilight_outlined;
      case 'Isha':
        return Icons.nightlight_round;
      default:
        return Icons.access_time;
    }
  }
}
