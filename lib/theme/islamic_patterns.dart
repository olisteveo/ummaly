import 'dart:math' as math;
import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// Islamic-pattern color palette (defaults)
// ---------------------------------------------------------------------------

class IslamicColors {
  static const gold = Color(0xFFD4A574);
  static const goldSubtle = Color(0x22D4A574);
  static const emerald = Color(0xFF0D7377);
  static const dark = Color(0xFF0F1A2E);
  static const cream = Color(0xFFFFF8E7);
}

// ---------------------------------------------------------------------------
// 1. IslamicGeometryPainter
//    Draws an interlocking field of 8-pointed stars connected by kite shapes.
//    `animation` (0.0-1.0) applies a slow global rotation.
// ---------------------------------------------------------------------------

class IslamicGeometryPainter extends CustomPainter {
  IslamicGeometryPainter({
    this.color = IslamicColors.goldSubtle,
    this.animation = 0.0,
    this.strokeWidth = 0.8,
  });

  final Color color;
  final double animation;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // Tile spacing — keep stars comfortably apart.
    const double spacing = 80.0;
    final double halfSpacing = spacing / 2;
    final double rotationAngle = animation * 2 * math.pi;

    // How many tiles we need (with padding so rotated edges are covered).
    final int cols = (size.width / spacing).ceil() + 2;
    final int rows = (size.height / spacing).ceil() + 2;

    canvas.save();
    // Rotate around the centre of the widget.
    canvas.translate(size.width / 2, size.height / 2);
    canvas.rotate(rotationAngle * 0.05); // Very subtle — only ~18 deg total
    canvas.translate(-size.width / 2, -size.height / 2);

    for (int r = -1; r < rows; r++) {
      for (int c = -1; c < cols; c++) {
        final double cx = c * spacing + halfSpacing;
        final double cy = r * spacing + halfSpacing;
        _drawEightPointedStar(canvas, paint, cx, cy, spacing * 0.38);
      }
    }

    canvas.restore();
  }

  /// Draws a single 8-pointed star at (cx, cy) with the given radius.
  void _drawEightPointedStar(
      Canvas canvas, Paint paint, double cx, double cy, double radius) {
    final double innerRadius = radius * 0.42;
    final path = Path();

    for (int i = 0; i < 8; i++) {
      final double outerAngle = (i * math.pi / 4) - math.pi / 2;
      final double innerAngle = outerAngle + math.pi / 8;

      final double ox = cx + radius * math.cos(outerAngle);
      final double oy = cy + radius * math.sin(outerAngle);
      final double ix = cx + innerRadius * math.cos(innerAngle);
      final double iy = cy + innerRadius * math.sin(innerAngle);

      if (i == 0) {
        path.moveTo(ox, oy);
      } else {
        path.lineTo(ox, oy);
      }
      path.lineTo(ix, iy);
    }
    path.close();
    canvas.drawPath(path, paint);

    // Small inner octagon for detail.
    final innerPath = Path();
    final double innerOctRadius = innerRadius * 0.65;
    for (int i = 0; i < 8; i++) {
      final double angle = (i * math.pi / 4) - math.pi / 2;
      final double px = cx + innerOctRadius * math.cos(angle);
      final double py = cy + innerOctRadius * math.sin(angle);
      if (i == 0) {
        innerPath.moveTo(px, py);
      } else {
        innerPath.lineTo(px, py);
      }
    }
    innerPath.close();
    canvas.drawPath(innerPath, paint);
  }

  @override
  bool shouldRepaint(IslamicGeometryPainter oldDelegate) =>
      oldDelegate.animation != animation ||
      oldDelegate.color != color ||
      oldDelegate.strokeWidth != strokeWidth;
}

// ---------------------------------------------------------------------------
// 2. MosqueSilhouettePainter
//    Draws a symmetrical mosque outline — central dome flanked by two minarets.
//    Intended for decorative header use.
// ---------------------------------------------------------------------------

class MosqueSilhouettePainter extends CustomPainter {
  MosqueSilhouettePainter({
    this.color = IslamicColors.goldSubtle,
  });

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final double w = size.width;
    final double h = size.height;
    final double midX = w / 2;

    final path = Path();

    // ------ Base line ------
    path.moveTo(0, h);
    path.lineTo(0, h * 0.70);

    // ------ Left minaret ------
    final double minaretW = w * 0.04;
    final double minaretLeft = w * 0.18;
    path.lineTo(minaretLeft, h * 0.70);
    path.lineTo(minaretLeft, h * 0.22);
    // Minaret cap (small dome)
    path.quadraticBezierTo(
        minaretLeft + minaretW / 2, h * 0.14, minaretLeft + minaretW, h * 0.22);
    path.lineTo(minaretLeft + minaretW, h * 0.70);

    // ------ Wall to dome ------
    final double domeStartX = w * 0.30;
    final double domeEndX = w * 0.70;
    path.lineTo(domeStartX, h * 0.70);

    // Dome wall rises.
    path.lineTo(domeStartX, h * 0.50);

    // ------ Central dome ------
    path.quadraticBezierTo(midX, h * 0.06, domeEndX, h * 0.50);

    // Dome wall descends.
    path.lineTo(domeEndX, h * 0.70);

    // ------ Right minaret ------
    final double rightMinaretLeft = w * 0.78;
    path.lineTo(rightMinaretLeft, h * 0.70);
    path.lineTo(rightMinaretLeft, h * 0.22);
    path.quadraticBezierTo(rightMinaretLeft + minaretW / 2, h * 0.14,
        rightMinaretLeft + minaretW, h * 0.22);
    path.lineTo(rightMinaretLeft + minaretW, h * 0.70);

    // ------ Close ------
    path.lineTo(w, h * 0.70);
    path.lineTo(w, h);
    path.close();

    canvas.drawPath(path, paint);

    // Finial dots on each minaret tip and dome apex.
    final finialPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final double dotR = math.min(w, h) * 0.012;
    canvas.drawCircle(Offset(minaretLeft + minaretW / 2, h * 0.13), dotR, finialPaint);
    canvas.drawCircle(Offset(rightMinaretLeft + minaretW / 2, h * 0.13), dotR, finialPaint);
    canvas.drawCircle(Offset(midX, h * 0.05), dotR * 1.2, finialPaint);
  }

  @override
  bool shouldRepaint(MosqueSilhouettePainter oldDelegate) =>
      oldDelegate.color != color;
}

// ---------------------------------------------------------------------------
// 3. IslamicPatternBackground
//    Wraps IslamicGeometryPainter with a slow 30-second animation cycle.
// ---------------------------------------------------------------------------

class IslamicPatternBackground extends StatefulWidget {
  const IslamicPatternBackground({
    super.key,
    required this.child,
    this.color = IslamicColors.goldSubtle,
    this.strokeWidth = 0.8,
  });

  final Widget child;
  final Color color;
  final double strokeWidth;

  @override
  State<IslamicPatternBackground> createState() =>
      _IslamicPatternBackgroundState();
}

class _IslamicPatternBackgroundState extends State<IslamicPatternBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Pattern layer — behind everything, ignoring touches.
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                return CustomPaint(
                  painter: IslamicGeometryPainter(
                    color: widget.color,
                    animation: _controller.value,
                    strokeWidth: widget.strokeWidth,
                  ),
                );
              },
            ),
          ),
        ),
        // Actual content — receives all touches.
        widget.child,
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// 4. ArabescueBorder
//    Draws an ornamental border frame with arched corner flourishes.
// ---------------------------------------------------------------------------

class ArabescueBorder extends CustomPainter {
  ArabescueBorder({
    this.color = IslamicColors.goldSubtle,
    this.strokeWidth = 1.0,
    this.cornerRadius = 16.0,
  });

  final Color color;
  final double strokeWidth;
  final double cornerRadius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final double w = size.width;
    final double h = size.height;
    final double inset = 6.0;
    final double cr = cornerRadius;

    // Outer frame.
    final outer = RRect.fromLTRBR(
        inset, inset, w - inset, h - inset, Radius.circular(cr));
    canvas.drawRRect(outer, paint);

    // Inner frame (slightly inset).
    final double innerInset = inset + 5;
    final inner = RRect.fromLTRBR(innerInset, innerInset, w - innerInset,
        h - innerInset, Radius.circular(cr * 0.7));
    canvas.drawRRect(inner, paint);

    // Corner flourishes — small arcs at each corner.
    _drawCornerFlourish(canvas, paint, inset, inset, 1, 1);
    _drawCornerFlourish(canvas, paint, w - inset, inset, -1, 1);
    _drawCornerFlourish(canvas, paint, inset, h - inset, 1, -1);
    _drawCornerFlourish(canvas, paint, w - inset, h - inset, -1, -1);

    // Mid-edge motifs — small pointed arches.
    _drawEdgeArch(canvas, paint, w / 2, inset, false);
    _drawEdgeArch(canvas, paint, w / 2, h - inset, true);
    _drawEdgeArchVertical(canvas, paint, inset, h / 2, false);
    _drawEdgeArchVertical(canvas, paint, w - inset, h / 2, true);
  }

  void _drawCornerFlourish(
      Canvas canvas, Paint paint, double x, double y, int dx, int dy) {
    const double len = 18.0;
    const double curl = 8.0;
    final path = Path();

    // Horizontal arm.
    path.moveTo(x, y);
    path.quadraticBezierTo(
        x + dx * curl, y + dy * curl, x + dx * len, y);

    // Vertical arm.
    path.moveTo(x, y);
    path.quadraticBezierTo(
        x + dx * curl, y + dy * curl, x, y + dy * len);

    canvas.drawPath(path, paint);
  }

  void _drawEdgeArch(
      Canvas canvas, Paint paint, double cx, double y, bool flip) {
    const double archW = 14.0;
    const double archH = 8.0;
    final double dir = flip ? 1 : -1;
    final path = Path()
      ..moveTo(cx - archW, y)
      ..quadraticBezierTo(cx, y + dir * archH, cx + archW, y);
    canvas.drawPath(path, paint);
  }

  void _drawEdgeArchVertical(
      Canvas canvas, Paint paint, double x, double cy, bool flip) {
    const double archW = 8.0;
    const double archH = 14.0;
    final double dir = flip ? 1 : -1;
    final path = Path()
      ..moveTo(x, cy - archH)
      ..quadraticBezierTo(x + dir * archW, cy, x, cy + archH);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(ArabescueBorder oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.strokeWidth != strokeWidth ||
      oldDelegate.cornerRadius != cornerRadius;
}

// ---------------------------------------------------------------------------
// Convenience widget wrapper for ArabescueBorder.
// ---------------------------------------------------------------------------

class ArabescueBorderWidget extends StatelessWidget {
  const ArabescueBorderWidget({
    super.key,
    required this.child,
    this.color = IslamicColors.goldSubtle,
    this.strokeWidth = 1.0,
    this.cornerRadius = 16.0,
  });

  final Widget child;
  final Color color;
  final double strokeWidth;
  final double cornerRadius;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: ArabescueBorder(
        color: color,
        strokeWidth: strokeWidth,
        cornerRadius: cornerRadius,
      ),
      child: child,
    );
  }
}

// ---------------------------------------------------------------------------
// 5. CrescentMoonWidget
//    Draws a crescent moon with a small star — classic Islamic motif.
// ---------------------------------------------------------------------------

class CrescentMoonWidget extends StatelessWidget {
  const CrescentMoonWidget({
    super.key,
    this.size = 48.0,
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
        painter: _CrescentMoonPainter(color: color),
      ),
    );
  }
}

class _CrescentMoonPainter extends CustomPainter {
  _CrescentMoonPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final double s = size.shortestSide;
    final double cx = size.width / 2;
    final double cy = size.height / 2;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Outer circle (full moon).
    final double moonR = s * 0.40;
    final outerPath = Path()
      ..addOval(Rect.fromCircle(center: Offset(cx, cy), radius: moonR));

    // Inner circle offset to the right to carve the crescent.
    final double cutR = moonR * 0.82;
    final double cutOffsetX = moonR * 0.38;
    final cutPath = Path()
      ..addOval(Rect.fromCircle(
          center: Offset(cx + cutOffsetX, cy - moonR * 0.05), radius: cutR));

    // Subtract inner from outer → crescent.
    final crescent =
        Path.combine(PathOperation.difference, outerPath, cutPath);
    canvas.drawPath(crescent, paint);

    // Five-pointed star placed in the opening of the crescent.
    final double starCx = cx + moonR * 0.52;
    final double starCy = cy - moonR * 0.10;
    final double starR = moonR * 0.22;
    _drawStar(canvas, paint, starCx, starCy, starR, 5);
  }

  void _drawStar(Canvas canvas, Paint paint, double cx, double cy,
      double outerR, int points) {
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
  bool shouldRepaint(_CrescentMoonPainter oldDelegate) =>
      oldDelegate.color != color;
}
