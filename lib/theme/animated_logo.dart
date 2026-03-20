import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:ummaly/theme/islamic_patterns.dart';

/// Animated Ummaly logo — the crescent moon, star, and mosque outline
/// merge together in a choreographed entrance animation.
///
/// Phase 1 (0.0–0.35): Mosque silhouette rises up from below with fade-in.
/// Phase 2 (0.20–0.55): Crescent moon sweeps in from the left, rotating.
/// Phase 3 (0.40–0.70): Star fades in and scales up inside the crescent.
/// Phase 4 (0.60–1.00): Everything settles, subtle glow pulse begins.
class AnimatedUmmalyLogo extends StatefulWidget {
  const AnimatedUmmalyLogo({
    super.key,
    this.size = 160.0,
    this.color = IslamicColors.gold,
    this.duration = const Duration(milliseconds: 2500),
    this.onAnimationComplete,
  });

  final double size;
  final Color color;
  final Duration duration;
  final VoidCallback? onAnimationComplete;

  @override
  State<AnimatedUmmalyLogo> createState() => _AnimatedUmmalyLogoState();
}

class _AnimatedUmmalyLogoState extends State<AnimatedUmmalyLogo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  // Phase animations
  late final Animation<double> _mosqueSlide;
  late final Animation<double> _mosqueFade;
  late final Animation<double> _crescentSlide;
  late final Animation<double> _crescentRotation;
  late final Animation<double> _crescentFade;
  late final Animation<double> _starScale;
  late final Animation<double> _starFade;
  late final Animation<double> _glowPulse;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    // Phase 1: Mosque rises up (0.0 → 0.40)
    _mosqueSlide = Tween<double>(begin: 40.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.40, curve: Curves.easeOutCubic),
      ),
    );
    _mosqueFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.35, curve: Curves.easeIn),
      ),
    );

    // Phase 2: Crescent sweeps in (0.15 → 0.55)
    _crescentSlide = Tween<double>(begin: -60.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.15, 0.55, curve: Curves.easeOutBack),
      ),
    );
    _crescentRotation = Tween<double>(begin: -0.5, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.15, 0.55, curve: Curves.easeOutCubic),
      ),
    );
    _crescentFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.15, 0.45, curve: Curves.easeIn),
      ),
    );

    // Phase 3: Star appears (0.40 → 0.70)
    _starScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.40, 0.70, curve: Curves.elasticOut),
      ),
    );
    _starFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.40, 0.60, curve: Curves.easeIn),
      ),
    );

    // Phase 4: Glow pulse (0.70 → 1.00)
    _glowPulse = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.70, 1.0, curve: Curves.easeInOut),
      ),
    );

    _controller.forward().then((_) {
      widget.onAnimationComplete?.call();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: CustomPaint(
            painter: _AnimatedLogoPainter(
              color: widget.color,
              mosqueSlide: _mosqueSlide.value,
              mosqueFade: _mosqueFade.value,
              crescentSlide: _crescentSlide.value,
              crescentRotation: _crescentRotation.value,
              crescentFade: _crescentFade.value,
              starScale: _starScale.value,
              starFade: _starFade.value,
              glowPulse: _glowPulse.value,
            ),
          ),
        );
      },
    );
  }
}

class _AnimatedLogoPainter extends CustomPainter {
  _AnimatedLogoPainter({
    required this.color,
    required this.mosqueSlide,
    required this.mosqueFade,
    required this.crescentSlide,
    required this.crescentRotation,
    required this.crescentFade,
    required this.starScale,
    required this.starFade,
    required this.glowPulse,
  });

  final Color color;
  final double mosqueSlide;
  final double mosqueFade;
  final double crescentSlide;
  final double crescentRotation;
  final double crescentFade;
  final double starScale;
  final double starFade;
  final double glowPulse;

  @override
  void paint(Canvas canvas, Size size) {
    final double s = size.shortestSide;
    final double cx = size.width / 2;
    final double cy = size.height / 2;

    // ── Glow effect (phase 4) ──
    if (glowPulse > 0) {
      final glowPaint = Paint()
        ..color = color.withValues(alpha: 0.08 * glowPulse)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);
      canvas.drawCircle(Offset(cx, cy), s * 0.45, glowPaint);
    }

    // ── Phase 1: Mosque silhouette ──
    if (mosqueFade > 0) {
      canvas.save();
      canvas.translate(0, mosqueSlide);

      final mosquePaint = Paint()
        ..color = color.withValues(alpha: 0.25 * mosqueFade)
        ..style = PaintingStyle.fill;

      _drawMosqueOutline(canvas, mosquePaint, size);

      // Mosque outline stroke
      final mosqueStrokePaint = Paint()
        ..color = color.withValues(alpha: 0.5 * mosqueFade)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2;

      _drawMosqueOutline(canvas, mosqueStrokePaint, size);

      canvas.restore();
    }

    // ── Phase 2: Crescent moon ──
    if (crescentFade > 0) {
      canvas.save();
      canvas.translate(cx + crescentSlide, cy);
      canvas.rotate(crescentRotation);
      canvas.translate(-cx, -cy);

      final crescentPaint = Paint()
        ..color = color.withValues(alpha: crescentFade)
        ..style = PaintingStyle.fill;

      _drawCrescent(canvas, crescentPaint, cx, cy * 0.42, s);

      canvas.restore();
    }

    // ── Phase 3: Star ──
    if (starFade > 0) {
      final starPaint = Paint()
        ..color = color.withValues(alpha: starFade)
        ..style = PaintingStyle.fill;

      final double moonR = s * 0.26;
      final double starCx = cx + moonR * 0.52;
      final double starCy = cy * 0.42 - moonR * 0.10;
      final double starR = moonR * 0.24 * starScale;

      _drawStar(canvas, starPaint, starCx, starCy, starR, 5);
    }
  }

  void _drawMosqueOutline(Canvas canvas, Paint paint, Size size) {
    final double w = size.width;
    final double h = size.height;
    final double midX = w / 2;

    // Mosque positioned in the lower portion of the logo
    final double mosqueTop = h * 0.45;
    final double mosqueBottom = h * 0.92;
    final double mosqueHeight = mosqueBottom - mosqueTop;

    final path = Path();

    // Base
    path.moveTo(w * 0.12, mosqueBottom);

    // Left minaret
    final double minaretW = w * 0.045;
    final double leftMinX = w * 0.20;
    path.lineTo(leftMinX, mosqueBottom);
    path.lineTo(leftMinX, mosqueTop + mosqueHeight * 0.15);
    // Minaret cap
    path.quadraticBezierTo(
      leftMinX + minaretW / 2,
      mosqueTop + mosqueHeight * 0.02,
      leftMinX + minaretW,
      mosqueTop + mosqueHeight * 0.15,
    );
    path.lineTo(leftMinX + minaretW, mosqueBottom);

    // Wall to dome
    final double domeStartX = w * 0.32;
    final double domeEndX = w * 0.68;
    path.lineTo(domeStartX, mosqueBottom);

    // Dome wall rises
    path.lineTo(domeStartX, mosqueTop + mosqueHeight * 0.45);

    // Central dome
    path.quadraticBezierTo(
      midX,
      mosqueTop + mosqueHeight * 0.05,
      domeEndX,
      mosqueTop + mosqueHeight * 0.45,
    );

    // Dome wall descends
    path.lineTo(domeEndX, mosqueBottom);

    // Right minaret
    final double rightMinX = w * 0.755;
    path.lineTo(rightMinX, mosqueBottom);
    path.lineTo(rightMinX, mosqueTop + mosqueHeight * 0.15);
    path.quadraticBezierTo(
      rightMinX + minaretW / 2,
      mosqueTop + mosqueHeight * 0.02,
      rightMinX + minaretW,
      mosqueTop + mosqueHeight * 0.15,
    );
    path.lineTo(rightMinX + minaretW, mosqueBottom);

    // Close
    path.lineTo(w * 0.88, mosqueBottom);
    path.close();

    canvas.drawPath(path, paint);

    // Finial crescents on minaret tips and dome apex
    if (paint.style == PaintingStyle.fill) {
      final dotPaint = Paint()
        ..color = paint.color
        ..style = PaintingStyle.fill;
      final double dotR = w * 0.012;
      canvas.drawCircle(
        Offset(leftMinX + minaretW / 2, mosqueTop + mosqueHeight * 0.01),
        dotR,
        dotPaint,
      );
      canvas.drawCircle(
        Offset(rightMinX + minaretW / 2, mosqueTop + mosqueHeight * 0.01),
        dotR,
        dotPaint,
      );
      canvas.drawCircle(
        Offset(midX, mosqueTop + mosqueHeight * 0.03),
        dotR * 1.3,
        dotPaint,
      );
    }
  }

  void _drawCrescent(
      Canvas canvas, Paint paint, double cx, double cy, double s) {
    final double moonR = s * 0.26;
    final outerPath = Path()
      ..addOval(Rect.fromCircle(center: Offset(cx, cy), radius: moonR));

    final double cutR = moonR * 0.82;
    final double cutOffsetX = moonR * 0.38;
    final cutPath = Path()
      ..addOval(Rect.fromCircle(
        center: Offset(cx + cutOffsetX, cy - moonR * 0.05),
        radius: cutR,
      ));

    final crescent =
        Path.combine(PathOperation.difference, outerPath, cutPath);
    canvas.drawPath(crescent, paint);
  }

  void _drawStar(Canvas canvas, Paint paint, double cx, double cy,
      double outerR, int points) {
    if (outerR <= 0) return;
    final double innerR = outerR * 0.45;
    final path = Path();
    final double startAngle = -math.pi / 2;

    for (int i = 0; i < points * 2; i++) {
      final double r = i.isEven ? outerR : innerR;
      final double angle = startAngle + (i * math.pi / points);
      final double px = cx + r * math.cos(angle);
      final double py = cy + r * math.sin(angle);
      if (i == 0) {
        path.moveTo(px, py);
      } else {
        path.lineTo(px, py);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_AnimatedLogoPainter oldDelegate) => true;
}

/// Static version of the combined logo (no animation) for use after
/// the intro animation has completed, or anywhere a static logo is needed.
class UmmalyLogo extends StatelessWidget {
  const UmmalyLogo({
    super.key,
    this.size = 80.0,
    this.color = IslamicColors.gold,
  });

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _AnimatedLogoPainter(
          color: color,
          mosqueSlide: 0,
          mosqueFade: 1,
          crescentSlide: 0,
          crescentRotation: 0,
          crescentFade: 1,
          starScale: 1,
          starFade: 1,
          glowPulse: 0,
        ),
      ),
    );
  }
}
