import 'dart:math' as math;
import 'package:flutter/material.dart';

/// A heavenly, luminous splash screen with a golden glass-effect mosque.
/// Palette: whites, creams, soft golds. Ethereal and elegant.
///
/// Phases:
///  0.00–0.20  Pure white → warm cream gradient fades in
///  0.10–0.40  Soft golden light radiates from center
///  0.15–0.50  Delicate geometric patterns emerge (Islamic tessellation)
///  0.25–0.60  Golden glass mosque materialises with shimmer
///  0.40–0.70  Light rays fan out from behind dome
///  0.50–0.80  Gold dust particles drift upward
///  0.75–0.90  Everything glows brighter — heavenly bloom
///  0.88–1.00  Fade to dark navy (transition to logo slide)
class MosqueSplashScreen extends StatefulWidget {
  final VoidCallback onComplete;
  final Duration duration;

  const MosqueSplashScreen({
    super.key,
    required this.onComplete,
    this.duration = const Duration(milliseconds: 5500),
  });

  @override
  State<MosqueSplashScreen> createState() => _MosqueSplashScreenState();
}

class _MosqueSplashScreenState extends State<MosqueSplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onComplete();
      }
    });
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _controller.forward();
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
        return CustomPaint(
          painter: _HeavenlySplashPainter(progress: _controller.value),
          size: Size.infinite,
        );
      },
    );
  }
}

class _HeavenlySplashPainter extends CustomPainter {
  final double progress;
  _HeavenlySplashPainter({required this.progress});

  // ── Palette ──
  static const _white = Color(0xFFFFFFFf);
  static const _cream = Color(0xFFFFF8EE);
  static const _warmCream = Color(0xFFFFF0D4);
  static const _lightGold = Color(0xFFE8C88A);
  static const _gold = Color(0xFFD4A574);
  static const _deepGold = Color(0xFFC49660);
  static const _navy = Color(0xFF0F1A2E);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    _drawBackground(canvas, size);
    _drawCentralGlow(canvas, size);
    _drawGeometricPatterns(canvas, size);
    _drawLightRays(canvas, size);
    _drawMosque(canvas, size);
    _drawParticles(canvas, size);
    _drawHeavenlyBloom(canvas, size);
    _drawFadeOut(canvas, size);
  }

  // ─── BACKGROUND ───
  void _drawBackground(Canvas canvas, Size size) {
    final warmth = _i(0.0, 0.30);

    final topColor = Color.lerp(_white, _cream, warmth)!;
    final bottomColor = Color.lerp(_white, _warmCream, warmth)!;

    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [topColor, bottomColor],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  // ─── CENTRAL RADIAL GLOW ───
  void _drawCentralGlow(Canvas canvas, Size size) {
    final glowAlpha = _i(0.08, 0.45);
    if (glowAlpha <= 0) return;

    final paint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0, 0.1),
        radius: 0.7 + glowAlpha * 0.3,
        colors: [
          _lightGold.withValues(alpha: 0.35 * glowAlpha),
          _gold.withValues(alpha: 0.15 * glowAlpha),
          _warmCream.withValues(alpha: 0.05 * glowAlpha),
          Colors.transparent,
        ],
        stops: const [0.0, 0.3, 0.6, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  // ─── ISLAMIC GEOMETRIC PATTERNS ───
  void _drawGeometricPatterns(Canvas canvas, Size size) {
    final patternAlpha = _i(0.12, 0.50) * (1.0 - _i(0.75, 0.92));
    if (patternAlpha <= 0.01) return;

    final cx = size.width / 2;
    final cy = size.height / 2;

    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.6
      ..color = _gold.withValues(alpha: 0.12 * patternAlpha);

    const spacing = 48.0;
    final cols = (size.width / spacing).ceil() + 2;
    final rows = (size.height / spacing).ceil() + 2;

    // Expand outward from center
    final expandRadius = patternAlpha * size.width * 0.9;

    for (int r = -1; r < rows; r++) {
      for (int c = -1; c < cols; c++) {
        final px = c * spacing + (r.isOdd ? spacing / 2 : 0);
        final py = r * spacing;

        // Only draw within expanding radius
        final dist = math.sqrt(math.pow(px - cx, 2) + math.pow(py - cy, 2));
        if (dist > expandRadius) continue;

        // Fade based on distance from center
        final distFade = 1.0 - (dist / expandRadius).clamp(0.0, 1.0);
        strokePaint.color = _gold.withValues(alpha: 0.12 * patternAlpha * distFade);

        _drawEightPointStar(canvas, strokePaint, px, py, 12);
      }
    }
  }

  void _drawEightPointStar(Canvas canvas, Paint paint, double cx, double cy, double radius) {
    final innerR = radius * 0.42;
    final path = Path();

    for (int i = 0; i < 8; i++) {
      final outerAngle = (i * math.pi / 4) - math.pi / 2;
      final innerAngle = outerAngle + math.pi / 8;

      final ox = cx + radius * math.cos(outerAngle);
      final oy = cy + radius * math.sin(outerAngle);
      final ix = cx + innerR * math.cos(innerAngle);
      final iy = cy + innerR * math.sin(innerAngle);

      if (i == 0) {
        path.moveTo(ox, oy);
      } else {
        path.lineTo(ox, oy);
      }
      path.lineTo(ix, iy);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  // ─── LIGHT RAYS ───
  void _drawLightRays(Canvas canvas, Size size) {
    final rayAlpha = _i(0.35, 0.70) * (1.0 - _i(0.80, 0.95));
    if (rayAlpha <= 0) return;

    final cx = size.width / 2;
    final cy = size.height * 0.42;

    final rayPaint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < 16; i++) {
      final baseAngle = (i / 16) * math.pi * 2;
      final angle = baseAngle + progress * 0.15; // very slow rotation

      final rayLength = size.height * 0.7;
      final spreadAngle = 0.03 + math.sin(i * 1.3) * 0.015;

      // Alternating opacity for depth
      final rayOpacity = (i.isEven ? 0.04 : 0.025) * rayAlpha;

      rayPaint.color = _gold.withValues(alpha: rayOpacity);

      final path = Path()
        ..moveTo(cx, cy)
        ..lineTo(
          cx + math.cos(angle - spreadAngle) * rayLength,
          cy + math.sin(angle - spreadAngle) * rayLength,
        )
        ..lineTo(
          cx + math.cos(angle + spreadAngle) * rayLength,
          cy + math.sin(angle + spreadAngle) * rayLength,
        )
        ..close();

      canvas.drawPath(path, rayPaint);
    }
  }

  // ─── MOSQUE ───
  void _drawMosque(Canvas canvas, Size size) {
    final mosqueAlpha = _i(0.20, 0.55);
    if (mosqueAlpha <= 0) return;

    final cx = size.width / 2;
    final baseY = size.height * 0.62;
    final mosqueW = size.width * 0.72;
    final mosqueH = size.height * 0.22;

    final left = cx - mosqueW / 2;
    final right = cx + mosqueW / 2;

    // Glass effect: semi-transparent gold fill + crisp gold stroke
    final glassFill = Paint()
      ..style = PaintingStyle.fill
      ..color = _gold.withValues(alpha: 0.08 * mosqueAlpha);

    final glassStroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeJoin = StrokeJoin.round
      ..color = _gold.withValues(alpha: 0.55 * mosqueAlpha);

    final shimmerStroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..color = _lightGold.withValues(alpha: 0.3 * mosqueAlpha);

    // ── Main body ──
    final bodyRect = Rect.fromLTRB(
      left + mosqueW * 0.08,
      baseY - mosqueH * 0.45,
      right - mosqueW * 0.08,
      baseY + mosqueH * 0.15,
    );
    final bodyRRect = RRect.fromRectAndRadius(bodyRect, const Radius.circular(3));
    canvas.drawRRect(bodyRRect, glassFill);
    canvas.drawRRect(bodyRRect, glassStroke);

    // ── Central dome ──
    final domePath = _createDomePath(cx, baseY - mosqueH * 0.45, mosqueW * 0.32, mosqueH * 0.42);
    canvas.drawPath(domePath, glassFill);
    canvas.drawPath(domePath, glassStroke);

    // Glass shimmer line on dome
    final shimmerPath = Path();
    final shimmerOffset = mosqueW * 0.04;
    shimmerPath.moveTo(cx - mosqueW * 0.10, baseY - mosqueH * 0.50);
    shimmerPath.quadraticBezierTo(
      cx - shimmerOffset, baseY - mosqueH * 0.85,
      cx + shimmerOffset, baseY - mosqueH * 0.70,
    );
    canvas.drawPath(shimmerPath, shimmerStroke);

    // ── Side domes ──
    final sideDomeL = _createDomePath(
      cx - mosqueW * 0.25, baseY - mosqueH * 0.38,
      mosqueW * 0.15, mosqueH * 0.22,
    );
    final sideDomeR = _createDomePath(
      cx + mosqueW * 0.25, baseY - mosqueH * 0.38,
      mosqueW * 0.15, mosqueH * 0.22,
    );
    canvas.drawPath(sideDomeL, glassFill);
    canvas.drawPath(sideDomeL, glassStroke);
    canvas.drawPath(sideDomeR, glassFill);
    canvas.drawPath(sideDomeR, glassStroke);

    // ── Minarets ──
    _drawGlassMinaret(canvas, glassFill, glassStroke, shimmerStroke,
        left + mosqueW * 0.05, baseY - mosqueH * 0.75, mosqueW * 0.028, mosqueH * 0.90, mosqueAlpha);
    _drawGlassMinaret(canvas, glassFill, glassStroke, shimmerStroke,
        right - mosqueW * 0.05, baseY - mosqueH * 0.75, mosqueW * 0.028, mosqueH * 0.90, mosqueAlpha);

    // ── Crescent on central dome ──
    _drawGoldCrescent(canvas, cx, baseY - mosqueH * 0.88, mosqueW * 0.035, mosqueAlpha);

    // ── Arched windows ──
    final windowStroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = _gold.withValues(alpha: 0.4 * mosqueAlpha);

    final windowFill = Paint()
      ..style = PaintingStyle.fill
      ..color = _lightGold.withValues(alpha: 0.06 * mosqueAlpha);

    for (int i = -2; i <= 2; i++) {
      final wx = cx + i * mosqueW * 0.085;
      final wy = baseY - mosqueH * 0.08;
      final ww = mosqueW * 0.028;
      final wh = mosqueH * 0.25;

      final windowPath = Path();
      windowPath.moveTo(wx - ww, wy);
      windowPath.lineTo(wx - ww, wy - wh * 0.55);
      windowPath.quadraticBezierTo(wx, wy - wh, wx + ww, wy - wh * 0.55);
      windowPath.lineTo(wx + ww, wy);
      windowPath.close();

      canvas.drawPath(windowPath, windowFill);
      canvas.drawPath(windowPath, windowStroke);
    }

    // ── Doorway (central arch) ──
    final doorW = mosqueW * 0.06;
    final doorH = mosqueH * 0.32;
    final doorPath = Path();
    doorPath.moveTo(cx - doorW, baseY + mosqueH * 0.15);
    doorPath.lineTo(cx - doorW, baseY - doorH * 0.4);
    doorPath.quadraticBezierTo(cx, baseY - doorH, cx + doorW, baseY - doorH * 0.4);
    doorPath.lineTo(cx + doorW, baseY + mosqueH * 0.15);

    canvas.drawPath(doorPath, windowFill);
    canvas.drawPath(doorPath, windowStroke);

    // ── Ground reflection / shadow ──
    final groundPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          _gold.withValues(alpha: 0.06 * mosqueAlpha),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTRB(
        left, baseY + mosqueH * 0.15,
        right, baseY + mosqueH * 0.5,
      ));
    canvas.drawRect(
      Rect.fromLTRB(left + mosqueW * 0.05, baseY + mosqueH * 0.15,
          right - mosqueW * 0.05, baseY + mosqueH * 0.5),
      groundPaint,
    );
  }

  Path _createDomePath(double cx, double baseY, double width, double height) {
    final path = Path();
    path.moveTo(cx - width / 2, baseY);
    path.cubicTo(
      cx - width / 2, baseY - height * 0.8,
      cx - width * 0.15, baseY - height,
      cx, baseY - height,
    );
    path.cubicTo(
      cx + width * 0.15, baseY - height,
      cx + width / 2, baseY - height * 0.8,
      cx + width / 2, baseY,
    );
    path.close();
    return path;
  }

  void _drawGlassMinaret(Canvas canvas, Paint fill, Paint stroke, Paint shimmer,
      double cx, double top, double width, double height, double alpha) {
    // Tower body
    final towerPath = Path();
    towerPath.moveTo(cx - width, top + height);
    towerPath.lineTo(cx - width * 0.65, top + height * 0.12);
    towerPath.lineTo(cx, top);
    towerPath.lineTo(cx + width * 0.65, top + height * 0.12);
    towerPath.lineTo(cx + width, top + height);
    towerPath.close();

    canvas.drawPath(towerPath, fill);
    canvas.drawPath(towerPath, stroke);

    // Balcony
    final balconyY = top + height * 0.30;
    final balconyPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = _gold.withValues(alpha: 0.45 * alpha);
    canvas.drawLine(
      Offset(cx - width * 1.5, balconyY),
      Offset(cx + width * 1.5, balconyY),
      balconyPaint,
    );

    // Second balcony
    final balcony2Y = top + height * 0.55;
    canvas.drawLine(
      Offset(cx - width * 1.3, balcony2Y),
      Offset(cx + width * 1.3, balcony2Y),
      balconyPaint,
    );

    // Shimmer line
    canvas.drawLine(
      Offset(cx - width * 0.2, top + height * 0.15),
      Offset(cx - width * 0.3, top + height * 0.7),
      shimmer,
    );

    // Crescent at top
    _drawGoldCrescent(canvas, cx, top - width * 0.8, width * 0.55, alpha);
  }

  void _drawGoldCrescent(Canvas canvas, double cx, double cy, double radius, double alpha) {
    final paint = Paint()
      ..color = _gold.withValues(alpha: 0.6 * alpha)
      ..style = PaintingStyle.fill;

    final outer = Path()
      ..addOval(Rect.fromCircle(center: Offset(cx, cy), radius: radius));
    final inner = Path()
      ..addOval(Rect.fromCircle(
          center: Offset(cx + radius * 0.35, cy - radius * 0.1),
          radius: radius * 0.78));

    final crescent = Path.combine(PathOperation.difference, outer, inner);
    canvas.drawPath(crescent, paint);

    // Star next to crescent
    final starX = cx + radius * 0.7;
    final starY = cy - radius * 0.3;
    final starR = radius * 0.2;
    final starPaint = Paint()
      ..color = _gold.withValues(alpha: 0.5 * alpha)
      ..style = PaintingStyle.fill;

    final starPath = Path();
    for (int i = 0; i < 5; i++) {
      final outerAngle = (i * 2 * math.pi / 5) - math.pi / 2;
      final innerAngle = outerAngle + math.pi / 5;
      final ox = starX + starR * math.cos(outerAngle);
      final oy = starY + starR * math.sin(outerAngle);
      final ix = starX + starR * 0.4 * math.cos(innerAngle);
      final iy = starY + starR * 0.4 * math.sin(innerAngle);
      if (i == 0) {
        starPath.moveTo(ox, oy);
      } else {
        starPath.lineTo(ox, oy);
      }
      starPath.lineTo(ix, iy);
    }
    starPath.close();
    canvas.drawPath(starPath, starPaint);
  }

  // ─── PARTICLES ───
  void _drawParticles(Canvas canvas, Size size) {
    final pAlpha = _i(0.35, 0.80) * (1.0 - _i(0.82, 0.95));
    if (pAlpha <= 0) return;

    final rng = math.Random(55);
    final paint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < 50; i++) {
      final startX = rng.nextDouble() * size.width;
      final startY = size.height * (0.25 + rng.nextDouble() * 0.5);
      final speed = 0.3 + rng.nextDouble() * 1.0;
      final radius = 0.8 + rng.nextDouble() * 2.0;

      final x = startX + math.sin(progress * math.pi * 2.5 + i * 0.8) * 15;
      final y = startY - pAlpha * speed * size.height * 0.25;

      final life = math.sin(pAlpha * math.pi);
      if (life <= 0) continue;

      final shimmer = (math.sin(progress * math.pi * 5 + i * 2.1) + 1) / 2;

      paint.color = Color.lerp(
        _gold,
        _cream,
        shimmer,
      )!.withValues(alpha: life * 0.4 * pAlpha);

      canvas.drawCircle(Offset(x, y), radius * (0.6 + shimmer * 0.4), paint);
    }
  }

  // ─── HEAVENLY BLOOM ───
  void _drawHeavenlyBloom(Canvas canvas, Size size) {
    final bloom = _i(0.65, 0.85);
    if (bloom <= 0) return;

    final paint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0, 0.0),
        radius: 1.2,
        colors: [
          _white.withValues(alpha: 0.35 * bloom),
          _cream.withValues(alpha: 0.15 * bloom),
          Colors.transparent,
        ],
        stops: const [0.0, 0.4, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  // ─── FADE TO DARK ───
  void _drawFadeOut(Canvas canvas, Size size) {
    final fade = _i(0.88, 1.0);
    if (fade <= 0) return;

    final paint = Paint()
      ..color = _navy.withValues(alpha: fade);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  /// Shorthand interval mapper.
  double _i(double start, double end) {
    return ((progress - start) / (end - start)).clamp(0.0, 1.0);
  }

  @override
  bool shouldRepaint(_HeavenlySplashPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
