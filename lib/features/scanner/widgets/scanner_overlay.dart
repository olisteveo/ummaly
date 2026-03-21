import 'package:flutter/material.dart';
import 'package:ummaly/theme/styles.dart';

/// Premium scanner overlay with corner brackets, scan line animation,
/// and clean instruction text.
class ScannerOverlay extends StatelessWidget {
  final AnimationController pulseController;

  const ScannerOverlay({Key? key, required this.pulseController})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    // Scanner window size — responsive
    final scanWidth = size.width * 0.72;
    final scanHeight = scanWidth * 0.6;

    return Stack(
      children: [
        // ── Dark vignette around scan window ──
        ColorFiltered(
          colorFilter: const ColorFilter.mode(
            Colors.black54,
            BlendMode.srcOut,
          ),
          child: Stack(
            children: [
              Container(
                decoration: const BoxDecoration(
                  color: Colors.black,
                  backgroundBlendMode: BlendMode.dstOut,
                ),
              ),
              Center(
                child: Container(
                  width: scanWidth,
                  height: scanHeight,
                  decoration: BoxDecoration(
                    color: Colors.red, // any color, gets cut out
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ],
          ),
        ),

        // ── Corner brackets ──
        Center(
          child: SizedBox(
            width: scanWidth,
            height: scanHeight,
            child: AnimatedBuilder(
              animation: pulseController,
              builder: (context, child) {
                return CustomPaint(
                  painter: _CornerBracketPainter(
                    color: AppColors.scanner,
                    opacity: 0.6 + (pulseController.value - 0.9) * 2,
                  ),
                );
              },
            ),
          ),
        ),

        // ── Animated scan line ──
        Center(
          child: SizedBox(
            width: scanWidth,
            height: scanHeight,
            child: AnimatedBuilder(
              animation: pulseController,
              builder: (context, _) {
                // Map pulse 0.9..1.1 to 0..1 for the line position
                final t = (pulseController.value - 0.9) / 0.2;
                return CustomPaint(
                  painter: _ScanLinePainter(
                    progress: t,
                    color: AppColors.scanner,
                  ),
                );
              },
            ),
          ),
        ),

        // ── Bottom instruction bar ──
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.7),
                ],
              ),
            ),
            padding: const EdgeInsets.fromLTRB(24, 40, 24, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.qr_code_scanner_rounded,
                      color: Colors.white.withOpacity(0.9),
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Align barcode inside the frame',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Hold steady — scans automatically',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Draws four corner brackets (L-shaped) around the scan window.
class _CornerBracketPainter extends CustomPainter {
  final Color color;
  final double opacity;

  _CornerBracketPainter({required this.color, required this.opacity});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(opacity.clamp(0.4, 1.0))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    const len = 28.0; // bracket arm length
    const r = 16.0;   // corner radius

    // Top-left
    canvas.drawPath(
      Path()
        ..moveTo(0, len)
        ..lineTo(0, r)
        ..quadraticBezierTo(0, 0, r, 0)
        ..lineTo(len, 0),
      paint,
    );

    // Top-right
    canvas.drawPath(
      Path()
        ..moveTo(size.width - len, 0)
        ..lineTo(size.width - r, 0)
        ..quadraticBezierTo(size.width, 0, size.width, r)
        ..lineTo(size.width, len),
      paint,
    );

    // Bottom-left
    canvas.drawPath(
      Path()
        ..moveTo(0, size.height - len)
        ..lineTo(0, size.height - r)
        ..quadraticBezierTo(0, size.height, r, size.height)
        ..lineTo(len, size.height),
      paint,
    );

    // Bottom-right
    canvas.drawPath(
      Path()
        ..moveTo(size.width - len, size.height)
        ..lineTo(size.width - r, size.height)
        ..quadraticBezierTo(size.width, size.height, size.width, size.height - r)
        ..lineTo(size.width, size.height - len),
      paint,
    );
  }

  @override
  bool shouldRepaint(_CornerBracketPainter old) => old.opacity != opacity;
}

/// Draws a horizontal gradient scan line that sweeps top→bottom.
class _ScanLinePainter extends CustomPainter {
  final double progress; // 0..1
  final Color color;

  _ScanLinePainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height * progress;
    final margin = 8.0;
    final rect = Rect.fromLTWH(margin, y - 1, size.width - margin * 2, 2);

    final gradient = LinearGradient(
      colors: [
        Colors.transparent,
        color.withOpacity(0.8),
        Colors.transparent,
      ],
      stops: const [0.0, 0.5, 1.0],
    ).createShader(rect);

    canvas.drawRect(rect, Paint()..shader = gradient);
  }

  @override
  bool shouldRepaint(_ScanLinePainter old) => old.progress != progress;
}
